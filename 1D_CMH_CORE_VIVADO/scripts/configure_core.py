#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

FRAC_BITS = 24
CORDIC_ITERS = 31


def qround(value: float, frac_bits: int = FRAC_BITS) -> int:
    scaled = value * (1 << frac_bits)
    if scaled >= 0:
        quantized = math.floor(scaled + 0.5)
    else:
        quantized = math.ceil(scaled - 0.5)
    if not -(1 << 31) <= quantized <= (1 << 31) - 1:
        raise ValueError(f"{value} does not fit signed 32-bit fixed point")
    return int(quantized)


def coefficient_constants(branches: int, rho_re: float,
                          rho_im: float) -> list[tuple[int, int]]:
    coefficients: list[tuple[int, int]] = []
    for index in range(branches):
        angle = 2.0 * math.pi * index / branches
        cosine = math.cos(angle)
        sine = math.sin(angle)
        real = rho_re * cosine - rho_im * sine
        imag = rho_re * sine + rho_im * cosine
        coefficients.append((qround(real), qround(imag)))
    return coefficients


def verilog_signed(value: int) -> str:
    return f"-32'sd{abs(value)}" if value < 0 else f"32'sd{value}"


def clog2_int(value: int) -> int:
    return max(1, math.ceil(math.log2(value)))


def generate_config(path: Path, branches: int, index_width: int,
                    rho_re_q: int, rho_im_q: int,
                    sigma_re_q: int, sigma_im_q: int,
                    z0_re_q: int, z0_im_q: int) -> None:
    path.write_text(f"""`ifndef CMH_CONFIG_VH
`define CMH_CONFIG_VH

`define CMH_BRANCHES {branches}
`define CMH_INDEX_WIDTH {index_width}
`define CMH_WORD_WIDTH 32
`define CMH_FRAC_BITS 24
`define CMH_CORDIC_ITERS {CORDIC_ITERS}

`define CMH_RHO_RE_Q824 {verilog_signed(rho_re_q)}
`define CMH_RHO_IM_Q824 {verilog_signed(rho_im_q)}
`define CMH_SIGMA_RE_Q824 {verilog_signed(sigma_re_q)}
`define CMH_SIGMA_IM_Q824 {verilog_signed(sigma_im_q)}
`define CMH_Z0_RE_Q824 {verilog_signed(z0_re_q)}
`define CMH_Z0_IM_Q824 {verilog_signed(z0_im_q)}

`endif
""", encoding="utf-8")


def generate_coeff_rom(path: Path, branches: int, index_width: int,
                       coefficients: list[tuple[int, int]]) -> None:
    lines = [
        "`timescale 1ns/1ps", "",
        "module cmh_branch_coeff_rom (",
        f"    input  wire [{index_width - 1}:0] idx,",
        "    output reg  signed [31:0] coeff_re,",
        "    output reg  signed [31:0] coeff_im",
        ");",
        "    always @* begin",
        "        case (idx)",
    ]
    for index, (real, imag) in enumerate(coefficients):
        lines.extend([
            f"            {index_width}'d{index}: begin",
            f"                coeff_re = {verilog_signed(real)};",
            f"                coeff_im = {verilog_signed(imag)};",
            "            end",
        ])
    lines.extend([
        "            default: begin",
        f"                coeff_re = {verilog_signed(coefficients[0][0])};",
        f"                coeff_im = {verilog_signed(coefficients[0][1])};",
        "            end",
        "        endcase",
        "    end",
        "endmodule", "",
    ])
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--branches", "-m", type=int, default=9)
    parser.add_argument("--rho-re", type=float, default=0.32)
    parser.add_argument("--rho-im", type=float, default=-0.33)
    parser.add_argument("--sigma-re", type=float, default=-1.80)
    parser.add_argument("--sigma-im", type=float, default=-0.90)
    parser.add_argument("--z0-re", type=float, default=0.10)
    parser.add_argument("--z0-im", type=float, default=0.20)
    args = parser.parse_args()

    if not 2 <= args.branches <= 32:
        raise SystemExit("--branches must be in the range 2 to 32")

    root = Path(__file__).resolve().parents[1]
    rtl_dir = root / "rtl"
    docs_dir = root / "docs"
    rtl_dir.mkdir(parents=True, exist_ok=True)
    docs_dir.mkdir(parents=True, exist_ok=True)

    branches = args.branches
    index_width = clog2_int(branches)
    rho_re_q = qround(args.rho_re)
    rho_im_q = qround(args.rho_im)
    sigma_re_q = qround(args.sigma_re)
    sigma_im_q = qround(args.sigma_im)
    z0_re_q = qround(args.z0_re)
    z0_im_q = qround(args.z0_im)
    coefficients = coefficient_constants(branches, args.rho_re, args.rho_im)

    generate_config(
        rtl_dir / "cmh_config.vh",
        branches,
        index_width,
        rho_re_q,
        rho_im_q,
        sigma_re_q,
        sigma_im_q,
        z0_re_q,
        z0_im_q,
    )
    generate_coeff_rom(
        rtl_dir / "cmh_branch_coeff_rom.v",
        branches,
        index_width,
        coefficients,
    )

    stale = rtl_dir / "cmh_sector_classifier.v"
    if stale.exists():
        stale.unlink()

    config = {
        "branches": branches,
        "configuration_mode": "synthesis time",
        "word_format": "Q8.24 signed two's complement",
        "angle_format": "pi radians = 2^30",
        "cordic_iterations": CORDIC_ITERS,
        "rho": {
            "real": args.rho_re,
            "imag": args.rho_im,
            "real_q824": rho_re_q,
            "imag_q824": rho_im_q,
        },
        "sigma": {
            "real": args.sigma_re,
            "imag": args.sigma_im,
            "real_q824": sigma_re_q,
            "imag_q824": sigma_im_q,
        },
        "z0": {
            "real": args.z0_re,
            "imag": args.z0_im,
            "real_q824": z0_re_q,
            "imag_q824": z0_im_q,
        },
        "sector_rule": "q=ceil((m*Arg(z)-pi)/(2*pi)) mod m",
        "branch_interval": "((2q-1)pi/m, (2q+1)pi/m]",
        "feedback_branch": 0,
        "cfold_N": 1,
    }
    (docs_dir / "generated_config.json").write_text(
        json.dumps(config, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    print(f"Generated fully parallel 1D-CMH core configuration for m={branches}")


if __name__ == "__main__":
    main()
