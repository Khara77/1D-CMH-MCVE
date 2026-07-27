# NIST SP 800-22 Evaluation of Nine-Channel Keystreams

This directory contains the statistical evaluation results of the nine binary keystream channels generated for the 1D-MCC-based multichannel video encryption experiment.

## Test Configuration

- Test suite: NIST Statistical Test Suite (STS) 2.1.2
- Number of channels: 9
- Sequences per channel: 64
- Sequence length: 1,000,000 bits
- Total bits per channel: 64,000,000 bits
- Input format: binary
- Significance level: \(\alpha=0.01\)
- Tests: all 15 NIST SP 800-22 statistical tests
- Test parameters: NIST STS 2.1.2 defaults

The principal parameters used by STS were:

- Block Frequency block length: 128
- Non-overlapping Template length: 9
- Overlapping Template length: 9
- Approximate Entropy block length: 10
- Serial block length: 16
- Linear Complexity block length: 500

## Result Summary

All nine channels completed the 15 NIST SP 800-22 tests without a uniformity or pass-proportion flag in the official `finalAnalysisReport.txt` files.

The aggregate results used in the manuscript are provided in `nist_paper_table.csv`. Across the nine channels:

- all channels are reported as `PASS`;
- the parsed result matrix contains 1,692 report rows;
- no flagged row was detected;
- no uniformity failure was detected;
- no pass-proportion failure was detected.

These results indicate that no statistical deviation was detected under the applied NIST STS configuration. Passing NIST SP 800-22 does not by itself constitute proof of cryptographic security.

## Files

- `summary.csv`  
  Per-channel summary, including file size, bit balance, SHA-256 value, minimum uniformity \(p\)-value, minimum pass ratio, and overall status.

- `result_matrix.csv`  
  Complete parsed result matrix containing the reported \(p\)-value uniformity, pass counts, pass ratios, sample sizes, and status values.

- `nist_paper_table.csv`  
  Aggregate values used for the NIST table in the manuscript.

- `test_configuration.txt`  
  NIST STS version, sequence dimensions, significance level, and test parameters.

- `official_reports_sanitized/`  
  The nine final STS reports, one for each keystream channel. Only the original local input path was replaced by `private_input/chXX.bin`; the statistical results were not changed.
