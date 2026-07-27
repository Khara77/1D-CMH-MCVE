# 1D-CMH-Based FPGA-Efficient Multichannel Video Encryption

This repository contains selected implementation materials and experimental evidence associated with the manuscript:

> **A One-Dimensional Complex Multivalued Hyperhaotic Map for FPGA-Efficient Multichannel Video Encryption**

The repository focuses on two aspects of the work:

1. a configurable Q8.24 hardware implementation of the proposed one-dimensional complex multivalued  hyperchaotic (1D-CMH) map; and
2. experimental evidence for the stand-alone dual-Zynq multichannel video encryption (MCVE) prototype.

## Main Features

- Configurable multibranch 1D-CMH chaos core
- Q8.24 fixed-point arithmetic
- Synthesis-time branch-number configuration
- One-to-many branch generation from a common recursive state
- Zynq-based hardware implementation
- Nine-channel dual-Zynq MCVE demonstration
- NIST SP 800-22 evaluation of nine hardware-generated keystream channels
- Vivado resource and timing reports for one-to-six-channel scalability analysis
- Comparison with a core-replication baseline

## Repository Structure

```text
.
├── 1D_CMH_CORE_VIVADO/
│   ├── docs/
│   ├── rtl/
│   ├── scripts/
│   └── README.md
├── Demo_video/
│   ├── demo_video.mp4
│   └── README.md
├── NIST/
│   ├── official_reports_sanitized/
│   ├── nist_paper_table.csv
│   ├── result_matrix.csv
│   ├── summary.csv
│   ├── test_configuration.txt
│   └── README.md
├── rpt/
│   ├── timing/
│   ├── utilization/
│   └── README.md
├── NOTICE.md
├── .gitignore
└── README.md
```

### Configurable 1D-CMH Core

[`1D_CMH_CORE_VIVADO/`](1D_CMH_CORE_VIVADO/) contains the Verilog RTL and project-generation scripts for the configurable chaos core.

The implemented map is

$$
z_{k+1}^{(j)}
=
\rho\left(\sqrt[m]{z_k^m}\right)^{(j)}
+
\sigma\operatorname{CFOLD}(z_k,1),
\qquad
j=0,\ldots,m-1.
$$

The current implementation uses signed Q8.24 arithmetic. The branch number \(m\) is configured at synthesis time, and branch \(0\) is fed back as the recursive state for the next iteration. The default configuration uses

$$
m=9,\qquad
\rho=0.32-0.33i,\qquad
\sigma=-1.80-0.90i,\qquad
z_0=0.10+0.20i.
$$

Detailed project-generation and interface instructions are provided in the directory README.

### Dual-Zynq Demonstration

[`Demo_video/`](Demo_video/) contains a short hardware demonstration of the stand-alone dual-Zynq MCVE prototype.

The demonstration presents the following observable processing states:

1. nine-channel plaintext video input;
2. noise-like encrypted video at the MCEA side;
3. transmitted ciphertext video at the MCDA input; and
4. recovered plaintext video after synchronized decryption.

The video is provided as visual evidence of the implemented branch-to-channel MCVE processing chain. Detailed playback and hardware-layout information is provided in the directory README.

### NIST SP 800-22 Results

[`NIST/`](NIST/) contains compact statistical evidence for the nine hardware-generated keystream channels.

The test configuration is:

- NIST STS 2.1.2
- 9 channels
- 64 sequences per channel
- 1,000,000 bits per sequence
- significance level \(\alpha=0.01\)
- all 15 NIST SP 800-22 tests

No uniformity or pass-proportion flag was reported in the retained final reports under this configuration.
The directory includes the aggregate manuscript table, the parsed result matrix, per-channel summaries, test parameters, and sanitized final STS reports.

### FPGA Resource and Timing Reports

[`rpt/`](rpt/) contains Vivado utilization and timing reports for the proposed MCVE datapath and a core-replication baseline from one to six channels.

The implementation environment is:

- Xilinx Vivado 2020.2
- XC7Z020-CLG400-1
- Q8.24 fixed-point format
- 50 MHz clock constraint

The principal scalability result is summarized below.

| Channels | Proposed DSP | Replication DSP | DSP Saving |
|---:|---:|---:|---:|
| 1 | 32 | 32 | -- |
| 2 | 32 | 64 | 50.0% |
| 3 | 32 | 96 | 66.7% |
| 4 | 32 | 128 | 75.0% |
| 5 | 32 | 160 | 80.0% |
| 6 | 32 | 192 | 83.3% |

The proposed design maintains a constant DSP count of 32 throughout the evaluated range, whereas the replication baseline increases proportionally with the channel count. All retained timing reports have positive worst negative slack under the stated clock constraint.

## Terminology

The manuscript denotes the proposed system as the **one-dimensional complex multivalued hyperchaotic map (1D-CMH)**. The same acronym and terminology should be used consistently in the repository name, directory names, documentation, figures, and source-code comments.

## Citation

The formal citation will be added after publication. Until then, please cite the associated manuscript by its title:

```text
A One-Dimensional Multivalued Complex Chaotic Map for
FPGA-Efficient Multichannel Video Encryption
```

## Rights and Use

Unless otherwise stated, all rights are reserved. The public source files and experimental materials are provided for academic inspection of the associated work. No permission is granted to redistribute, modify, sublicense, or incorporate these materials into another project without prior written authorization from the authors.

See [`NOTICE.md`](NOTICE.md) for the repository-use statement.
