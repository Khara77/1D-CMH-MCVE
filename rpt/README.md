# FPGA Resource and Timing Reports

This directory contains the Vivado implementation reports used to evaluate the hardware scalability of the proposed 1D-CMH-based multichannel encryption datapath.

## Implementation Environment

- Tool: Xilinx Vivado 2020.2
- Device: XC7Z020-CLG400-1
- Fixed-point format: Q8.24
- Target clock frequency: 50 MHz
- Report state: routed design with bitstream generated

The reports compare two implementations from one to six channels

## Why One to Six Channels Were Evaluated

The one-to-six-channel range was selected to ensure that both implementations could be synthesized and compared on the same XC7Z020 device.

The replication baseline uses one independent chaotic arithmetic core for each channel, with each core consuming 32 DSP blocks. Therefore, its DSP usage increases linearly with the number of channels:

[
\mathrm{DSP}_{\mathrm{replication}} = 32N_c,
]

where (N_c) denotes the number of channels.

The XC7Z020 device contains 220 DSP blocks. A six-channel replication design requires

[
6\times32=192
]

DSP blocks and can still be implemented on this device, whereas a seven-channel replication design would require

[
7\times32=224
]

DSP blocks, exceeding the available device capacity. Consequently, six channels represent the largest common comparison point at which both the proposed and replication implementations can be evaluated on the same FPGA.

This evaluation range does not represent the channel limit of the proposed architecture. The proposed design reuses one chaotic arithmetic core and maintains a constant DSP count of 32 throughout the tested configurations. Additional channels can be supported by extending the branch scheduling and channel-control logic, subject to the throughput, buffering, interface bandwidth, and timing constraints of the target system.


## Directory Structure

- `utilization/`  
  Hierarchical utilization reports for the proposed and replication implementations from one to six channels.

- `timing/`  
  Post-implementation timing summary reports for the same configurations.

## File Naming

For the proposed architecture:

```text
utilization/top_CMHN_hierarchical.rpt
timing/top_CMHN_mce_timing.rpt
```

For the replication baseline:

```text
utilization/top_CMHN_replication_hierarchical.rpt
timing/top_CMHN_replication_mce_timing.rpt
```

Here, `N` denotes the number of channels.

## Resource Summary

| Channels | Proposed LUT | Proposed FF | Proposed DSP | Replication LUT | Replication FF | Replication DSP | DSP Saving |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 669 | 626 | 32 | 669 | 626 | 32 | -- |
| 2 | 736 | 776 | 32 | 1338 | 1252 | 64 | 50.0% |
| 3 | 836 | 888 | 32 | 2009 | 1878 | 96 | 66.7% |
| 4 | 822 | 856 | 32 | 2675 | 2504 | 128 | 75.0% |
| 5 | 932 | 942 | 32 | 3345 | 3130 | 160 | 80.0% |
| 6 | 886 | 961 | 32 | 4012 | 3756 | 192 | 83.3% |

The proposed architecture maintains a constant DSP count of 32 from one to six channels, whereas the replication baseline increases from 32 to 192 DSP blocks. At six channels, the proposed architecture reduces DSP usage by 83.3%.

The nonmonotonic LUT and FF values of the proposed configurations arise from synthesis and implementation optimization across separately generated designs. The DSP result is the primary indicator of arithmetic-core reuse.

## Timing Summary

| Channels | Proposed WNS (ns) | Replication WNS (ns) |
|---:|---:|---:|
| 1 | 8.219 | 9.313 |
| 2 | 6.561 | 9.057 |
| 3 | 6.946 | 6.749 |
| 4 | 5.553 | 8.854 |
| 5 | 5.222 | 6.289 |
| 6 | 7.249 | 7.946 |

All reported configurations have positive worst negative slack and zero total negative slack under the 50 MHz clock constraint. The internal registered datapaths therefore meet the specified clock timing.

