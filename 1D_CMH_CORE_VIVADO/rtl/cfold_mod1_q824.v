`timescale 1ns/1ps

module cfold_mod1_q824 (
    input  wire signed [31:0] z_re,
    input  wire signed [31:0] z_im,
    output wire signed [31:0] fold_re,
    output wire signed [31:0] fold_im
);
    assign fold_re = {8'd0, z_re[23:0]};
    assign fold_im = {8'd0, z_im[23:0]};
endmodule
