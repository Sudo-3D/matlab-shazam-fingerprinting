# Audio Fingerprint Matcher

A robust MATLAB implementation of a content-based audio identification system, inspired by the industrial Shazam fingerprinting algorithm. This system extracts unique geometric acoustic signatures from an audio file and matches query snippets against a localized database using time-invariant relative offsets.

---

## 🛠️ How It Works

The system processes audio signals through four distinct phases:

### 1. Audio Processing & Feature Extraction
* **Mono Conversion & Downsampling:** Ensures uniform signal dimensions by isolating the primary channel.
* **Spectrogram Generation:** Computes time-frequency distributions using a Short-Time Fourier Transform (STFT) with a `1024-point Hamming window` and `512-point overlap`.

### 2. Constellation Mapping & Peak Detection
* **2D Max Filtering:** Passes an `9x9` order statistic filter (`ordfilt2`) over the spectrogram magnitudes to isolate local power peaks.
* **Adaptive Thresholding:** Calculates the mean energy per time-frame and applies a structural power offset to filter out background noise, retaining only the dominant acoustic landmarks.

### 3. Combinatorial Hashing
* Anchors adjacent peaks within a local `target zone` forward in time.
* Generates unique cryptographic-style string keys based on frequency pairs and their precise temporal spacing:
  $$\text{Hash Key} = f_1 \mid f_2 \mid \Delta t$$

### 4. Time-Offset Matching & Histogram Voting
* Evaluates the query hashes against the database (`fingerprintDB.mat`).
* For every matching hash key, it computes the absolute time-offset delay:
  $$\Delta T_{\text{offset}} = t_{\text{database}} - t_{\text{query}}$$
* Plots a scatter vote histogram across all candidates. A true match creates a sharp peak in the time-delay distribution, proving linear coherence even if the query starts mid-song.

---

## 📂 Project Structure

```text
audio-fingerprint-system/
|── fingerprint_system.m   # Core audio analysis, indexing, and lookup script
├── fingerprintDB.m        # database
├── samples/
│   └── .gitkeep               # Directory for storing test audio clips (.mp3)
├── .gitignore                 # Excludes heavy binary .mat and .mp3 files from version control
└── README.md                  # System documentation
```
## 🚀 Getting Started
Prerequisites
MATLAB (R2020a or later recommended)

Running the System
Clone the repository:

Bash
git clone [https://github.com/Sudo-3D/audio-fingerprint-system.git](https://github.com/Sudo-3D/audio-fingerprint-system.git)
1- Open MATLAB and navigate to the project directory.

2- Run the script fingerprint_system.m.

3- Select an audio file from the file explorer dialog prompt.

4- Choose whether to display visual graphs (Y/N) to view the processing pipeline stages:

- Original Spectrogram

- After 2D Max Filter Spectrum

- Resulting Constellation Map
