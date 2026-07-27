`timescale 1ns/1ps

module cmh_branch_coeff_rom (
    input  wire [3:0] idx,
    output reg  signed [31:0] coeff_re,
    output reg  signed [31:0] coeff_im
);
    always @* begin
        case (idx)
            4'd0: begin
                coeff_re = 32'sd5368709;
                coeff_im = -32'sd5536481;
            end
            4'd1: begin
                coeff_re = 32'sd7671451;
                coeff_im = -32'sd790251;
            end
            4'd2: begin
                coeff_re = 32'sd6384636;
                coeff_im = 32'sd4325746;
            end
            4'd3: begin
                coeff_re = 32'sd2110379;
                coeff_im = 32'sd7417679;
            end
            4'd4: begin
                coeff_re = -32'sd3151348;
                coeff_im = 32'sd7038797;
            end
            4'd5: begin
                coeff_re = -32'sd6938524;
                coeff_im = 32'sd3366384;
            end
            4'd6: begin
                coeff_re = -32'sd7479088;
                coeff_im = -32'sd1881198;
            end
            4'd7: begin
                coeff_re = -32'sd4520103;
                coeff_im = -32'sd6248546;
            end
            4'd8: begin
                coeff_re = 32'sd553888;
                coeff_im = -32'sd7692130;
            end
            default: begin
                coeff_re = 32'sd5368709;
                coeff_im = -32'sd5536481;
            end
        endcase
    end
endmodule
