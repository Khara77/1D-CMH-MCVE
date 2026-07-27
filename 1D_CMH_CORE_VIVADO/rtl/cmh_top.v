`timescale 1ns/1ps
`include "cmh_config.vh"

module cmh_top (
    input  wire                                  clk,
    input  wire                                  rstn,
    input  wire                                  seed_valid,
    output wire                                  seed_ready,
    input  wire signed [31:0]                    seed_re,
    input  wire signed [31:0]                    seed_im,
    input  wire                                  step_valid,
    output wire                                  step_ready,
    output wire [`CMH_BRANCHES*32-1:0]           branches_re,
    output wire [`CMH_BRANCHES*32-1:0]           branches_im,
    output wire                                  branches_valid,
    input  wire                                  branches_ready,
    output wire signed [31:0]                    state_re,
    output wire signed [31:0]                    state_im
);
    cmh_parallel_core u_core (
        .clk(clk),
        .rstn(rstn),
        .seed_valid(seed_valid),
        .seed_ready(seed_ready),
        .seed_re(seed_re),
        .seed_im(seed_im),
        .step_valid(step_valid),
        .step_ready(step_ready),
        .branches_re(branches_re),
        .branches_im(branches_im),
        .branches_valid(branches_valid),
        .branches_ready(branches_ready),
        .state_re(state_re),
        .state_im(state_im)
    );
endmodule
