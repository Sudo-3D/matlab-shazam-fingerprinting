clc; clear;

%% 1. Audio Processing & Feature Extraction
[music_file, filePath] = uigetfile({'*.mp3;*.wav;*.ogg;*.m4a', 'Audio Files (*.mp3, *.wav, *.ogg, *.m4a)'; '*.*', 'All Files (*.*)'}, 'select file');
if isequal(music_file, 0) || isequal(filePath, 0)
    error('No file has been selected');

else
    fullPath = fullfile(filePath, music_file);
    fprintf('File Selected: %s\n', fullPath);
    
    [y, Fs] = audioread(fullPath); 
end

if size(y, 2) > 1
    y = y(:, 1); % Convert to Mono
end

% Spectrogram configuration
window_size = 1024;
h = hamming(window_size);
overlap = 512;
nfft = 1024;
target_zone = 3;

[S, F, T, P] = spectrogram(y, h, overlap, nfft, Fs, 'yaxis');
P_db = 10 * log10(abs(P) + eps);

% 2D Max Filtering & Adaptive Thresholding
P_2D_max = ordfilt2(P_db, 81, ones(9, 9));
mean_per_frame = mean(P_db, 1);
offset = 40; % to detect music only
threshold = mean_per_frame + offset;

mask = (P_db == P_2D_max) & (P_db > threshold);
[row, col] = find(mask);
[~, idx] = sort(col);
row = row(idx); col = col(idx);

freq = F(row);
time = T(col);

i = 0;
while i ==0
    ask = input("Do you want to see the Spectrogram before and after and Constellation Map: (Y/N) ", "s");
    
    if lower(ask) == 'y'
    
        figure;
        subplot(1,3,1);
        imagesc(T,F,P_db);
        axis xy;
        title('Original Spectrogram');
        xlabel('Time');
        ylabel('Frequency');
        colorbar;
    
        subplot(1,3,2);
        imagesc(T,F,P_2D_max);
        axis xy;
        title('After 2D Max Filter');
        xlabel('Time');
        ylabel('Frequency');
        colorbar;
    
        subplot(1,3,3);
        scatter(T(col), F(row), 10, 'filled');
        xlabel('Time');
        ylabel('Frequency');
        title('Constellation Map');
        i =1;
     elseif lower(ask) == 'n'
        disp('Generate Hashes.........')
        i =1;   
     else
        disp('please enter valid input Y/N');
    end
end
%% 2. Generate Hashes for Current Audio
current_DB = containers.Map();

for i = 1:length(freq)
    for j = i+1:min(i+target_zone, length(freq))
        f1 = round(freq(i));
        f2 = round(freq(j));
        dt = round(100 * (time(j) - time(i)));
        
        hash_key = sprintf('%d|%d|%d', f1, f2, dt);
        info = {music_file, time(i)}; % Stores song name and absolute time
        
        if isKey(current_DB, hash_key)
            existing_entries = current_DB(hash_key);
            existing_entries(end+1) = {info};
            current_DB(hash_key) = existing_entries;
        else
            current_DB(hash_key) = {info};
        end
    end
end

%% 3. Database Lookup & Time-Offset Matching
if exist('fingerprintDB.mat', 'file')
    data = load('fingerprintDB.mat');
    global_DB = data.DB;
else
    global_DB = containers.Map(); % Create new if it doesn't exist
end

query_keys = keys(current_DB);
vote_map = containers.Map('KeyType', 'char', 'ValueType', 'double');

for i = 1:length(query_keys)
    k = query_keys{i};
    
    if isKey(global_DB, k)
        % Retrieve database match entries
        db_entries = global_DB(k);
        
        % Normalize format to handle single or multiple stored entries
        if ~iscell(db_entries{1}), db_entries = {db_entries}; end
        
        % Get current query time for this hash
        query_entry = current_DB(k);
        if ~iscell(query_entry{1}), query_entry = {query_entry}; end
        t_query = query_entry{1}{2}; 
        
        % Check all matches in the database for this hash
        for m = 1:length(db_entries)
            song_id = db_entries{m}{1};
            t_db = db_entries{m}{2};
            
            % CRITICAL STEP: Compute Time Offset
            time_offset = round(t_db - t_query, 2);
            
            % Unique vote key combines song name and the precise time offset
            vote_key = sprintf('%s|%.2f', song_id, time_offset);
            
            if isKey(vote_map, vote_key)
                vote_map(vote_key) = vote_map(vote_key) + 1;
            else
                vote_map(vote_key) = 1;
            end
        end
    else
        % If hash is unique, insert it into the global Database
        global_DB(k) = current_DB(k);
    end
end

% Save the updated database back to disk
DB = global_DB;
save('fingerprintDB.mat', 'DB');

%% 4. Identify the Winner
vote_keys = keys(vote_map);
vote_values = cell2mat(values(vote_map));

if isempty(vote_values)
    disp('Sorry, song not found in the database.');
    fprintf('%d hashes added.\n',global_DB.Count);
    fprintf('song added to database with name: %s', string(music_file));
else
    [max_votes, win_idx] = max(vote_values);
    winner_info = split(vote_keys{win_idx}, '|');
    winner_song = winner_info{1};
    winner_time_offset = winner_info{2};
    
    % Printing results for all detected candidates
    fprintf('\n--- Matching Results ---\n');
    for i = 1:length(vote_keys)
        candidate = split(vote_keys{i}, '|');
        %fprintf('Candidate: %s (Offset: %ss) -> %d votes\n', candidate{1}, candidate{2}, vote_map(vote_keys{i}));
    end
    if max_votes >= 100
        fprintf('------------------------\n');
        fprintf('🎉 Song Detected: [%s]\n', winner_song);
        fprintf('⏱️ Match found at timestamp: %ss in the original track\n', winner_time_offset);
        fprintf('📊 Confidence: %d matching hashes\n', max_votes);
    else
        disp('Sorry, song not found in the database.');
        fprintf('%d hashes added.\n',global_DB.Count);
        disp('---------------------------------------');
        fprintf('song added to database with name: %s', string(music_file));
    end
end