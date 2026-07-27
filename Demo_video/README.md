# Dual-Zynq MCVE Demonstration Video

This directory contains a short hardware demonstration video of the stand-alone dual-Zynq multichannel video encryption (MCVE) prototype developed for the proposed one-dimensional complex multivalued hyperchaotic (1D-CMH) map.

## Video File

* **File:** `demo_video.mp4`
* **Duration:** Approximately 17 s
* **Resolution:** 1280 × 720
* **Frame rate:** 30 fps
* **Display layout:** A (3\times3) arrangement of nine video channels on each monitor

## Demonstrated Hardware Setup

The MCVE prototype consists of two Zynq-based hardware endpoints:

* **MCEA:** Multichannel Encryption Accelerator, responsible for multichannel video encryption.
* **MCDA:** Multichannel Decryption Accelerator, responsible for receiving and decrypting the transmitted ciphertext video streams.

The MCEA and MCDA are connected through a Cat6A Ethernet cable, forming the complete hardware transmission path for multichannel encryption, ciphertext transmission, and plaintext recovery.

Each Zynq endpoint independently outputs its visual processing results to a monitor through an HDMI interface. The two displays jointly present the visual states along the complete MCVE processing chain.

## What the Video Shows

The demonstration uses four display regions, labeled **(a)**–**(d)** from left to right, to present the video states at different stages of the MCVE processing chain.

### Initial State

Before encryption and decryption are enabled, the MCEA reads the nine source video streams. All four display regions show the original plaintext videos:

* **(a):** Original video input
* **(b):** Original video
* **(c):** Original video
* **(d):** Original video

### Encryption Enabled

After **KEY0** is pressed, the MCEA activates multichannel encryption. The display states become:

* **(a):** Original plaintext video
* **(b):** Noise-like encrypted video
* **(c):** Noise-like encrypted video
* **(d):** Noise-like encrypted video

This state visually confirms that the nine source video channels have been processed by the branch-to-channel keystreams generated from the 1D-CMH map.

### Decryption Enabled

After **KEY1** is pressed, the MCDA synchronously activates multichannel decryption. The four display regions then show:

* **(a):** Original plaintext video
* **(b):** Noise-like encrypted video
* **(c):** Transmitted noise-like ciphertext video
* **(d):** Losslessly recovered video after decryption

At this stage, the two monitors jointly display the complete set of visual states along the MCVE processing chain:

[
\text{Plaintext input}
\rightarrow
\text{Encrypted output}
\rightarrow
\text{Transmitted ciphertext}
\rightarrow
\text{Recovered plaintext}.
]

The recovered nine-channel videos in region **(d)** are visually consistent with the corresponding source videos in region **(a)**.

## Demonstrated Processing Sequence

The video provides visual evidence of the following hardware processing sequence:

1. Nine-channel plaintext video input
2. Branch-to-channel keystream assignment
3. Multichannel encryption at the MCEA side
4. Cat6A transmission of the encrypted video streams
5. Synchronized multichannel decryption at the MCDA side
6. Lossless recovery and display of the nine video channels

It directly presents four observable states of the multichannel video processing chain: the original videos, encrypted videos, transmitted ciphertext videos, and recovered videos.


## Playback Note

For broad browser compatibility, an H.264/AAC MP4 version is recommended for the public repository. The current video uses an HEVC video stream and may not play directly in every browser.
