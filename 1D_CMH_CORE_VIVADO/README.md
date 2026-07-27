# Configurable 1D-CMH Chaos Core Vivado Project

This project implements a 1D-CMH chaos core with a configurable number of branches.

## Mathematical Model

The implementation uses Q8.24 fixed-point format:

\[
z_{k+1}^{(j)}=\rho\left(\sqrt[m]{z_k^m}\right)^{(j)}+\sigma\operatorname{CFOLD}(z_k,1),\qquad j=0,\ldots,m-1.
\]

All branches are computed through independent arithmetic datapaths in parallel, and branch 0 is fed back as the next recursive state. The branch count \(m\) is a synthesis-time parameter with a supported range of 2 to 32. This range represents the safe engineering range supported by the current RTL version, rather than an absolute mathematical limit.

Default parameters are:

\[
m=9,\quad \rho=0.32-0.33i,\quad \sigma=-1.80-0.90i,\quad z_0=0.10+0.20i.
\]

## Project Contents

The project provides the following features:

1. Generate fixed-point configuration based on the specified \(m\), \(\rho\), \(\sigma\), and \(z_0\);
2. Generate the complex rotation coefficient ROM corresponding to the branch count;
3. Create a Vivado project containing the 1D-CMH RTL source files;
4. Update the complex initial value at runtime through the seed interface;
5. Accept a single iteration request and output all \(m\) complex branches;
6. Automatically feed branch 0 back as the next iteration state.

## Python Environment

Vivado 2020.2 may inject its bundled Python standard library into the external Python environment and trigger `SRE module mismatch`. Before invoking the configuration generator, the Tcl scripts temporarily clear `PYTHONHOME` and `PYTHONPATH` and then search for an available interpreter in the following order:

1. Environment variable `CMH_PYTHON`;
2. Windows `py -3`;
3. `python3`;
4. `python`.

To manually specify the interpreter, run the following in the Vivado Tcl Console:

```tcl
set ::env(CMH_PYTHON) {C:/Users/CJ/AppData/Local/Programs/Python/Python311/python.exe}
```

## Creating the Project

In the Vivado Tcl Console, change to the project root directory:

```tcl
cd {C:/Users/CJ/Desktop/CMH_PARALLEL_CONFIGURABLE}
```

To create the default 9-branch project:

```tcl
set argv {9}
source ./scripts/create_project.tcl
```

To create a 5-branch project:

```tcl
close_project
set argv {5}
source ./scripts/create_project.tcl
```

To set the branch count, parameters, and initial values at the same time:

```tcl
close_project
set argv {9 0.32 -0.33 -1.80 -0.90 0.10 0.20}
source ./scripts/create_project.tcl
```

Parameter order:

```text
m rho_re rho_im sigma_re sigma_im z0_re z0_im
```

The generated project is located at:

```text
build/cmh_m9/cmh_m9.xpr
```

## Formal Outputs

The outputs of `cmh_top` are:

```verilog
branches_re[m*32-1:0]
branches_im[m*32-1:0]
branches_valid
state_re
state_im
```

The \(j\)-th branch is located at:

```verilog
branches_re[j*32 +: 32]
branches_im[j*32 +: 32]
```

Each real and imaginary part is signed Q8.24 data.

## Using the Chaos Core

The functional top module is `cmh_top`.

The core uses valid-ready handshakes for seed loading, iteration requests, and branch output transfer.

### Reset

`rstn` is an active-low reset signal. When `rstn` is asserted, the internal state is initialized with the configured value \(z_0\).

```verilog
rstn = 1'b0;