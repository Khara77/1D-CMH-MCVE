`timescale 1ns/1ps

module cmul_q824_pipe (
    input  wire                    clk,
    input  wire                    rstn,
    input  wire                    in_valid,
    input  wire signed [31:0]      a_re,
    input  wire signed [31:0]      a_im,
    input  wire signed [31:0]      b_re,
    input  wire signed [31:0]      b_im,
    output reg                     out_valid,
    output reg  signed [31:0]      p_re,
    output reg  signed [31:0]      p_im
);
    (* use_dsp = "yes" *) reg signed [63:0] ac_q;
    (* use_dsp = "yes" *) reg signed [63:0] bd_q;
    (* use_dsp = "yes" *) reg signed [63:0] ad_q;
    (* use_dsp = "yes" *) reg signed [63:0] bc_q;
    reg valid_q;

    wire signed [64:0] real_full =
        $signed({ac_q[63], ac_q}) - $signed({bd_q[63], bd_q});
    wire signed [64:0] imag_full =
        $signed({ad_q[63], ad_q}) + $signed({bc_q[63], bc_q});
    wire signed [64:0] real_scaled = real_full >>> 24;
    wire signed [64:0] imag_scaled = imag_full >>> 24;

    always @(posedge clk) begin
        if (!rstn) begin
            ac_q      <= 64'sd0;
            bd_q      <= 64'sd0;
            ad_q      <= 64'sd0;
            bc_q      <= 64'sd0;
            valid_q   <= 1'b0;
            out_valid <= 1'b0;
            p_re      <= 32'sd0;
            p_im      <= 32'sd0;
        end else begin
            valid_q   <= in_valid;
            out_valid <= valid_q;

            if (in_valid) begin
                ac_q <= $signed(a_re) * $signed(b_re);
                bd_q <= $signed(a_im) * $signed(b_im);
                ad_q <= $signed(a_re) * $signed(b_im);
                bc_q <= $signed(a_im) * $signed(b_re);
            end

            if (valid_q) begin
                p_re <= real_scaled[31:0];
                p_im <= imag_scaled[31:0];
            end
        end
    end
endmodule
