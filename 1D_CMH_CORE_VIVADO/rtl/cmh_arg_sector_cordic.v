`timescale 1ns/1ps
`include "cmh_config.vh"

module cmh_arg_sector_cordic (
    input  wire                              clk,
    input  wire                              rstn,
    input  wire                              in_valid,
    output wire                              in_ready,
    input  wire signed [31:0]                x_in,
    input  wire signed [31:0]                y_in,
    output reg                               out_valid,
    output reg  [`CMH_INDEX_WIDTH-1:0]       sector_idx
);
    localparam signed [39:0] PI_CODE = 40'sd1073741824;
    localparam [5:0] LAST_ITER = `CMH_CORDIC_ITERS - 1;

    reg busy_q;
    reg calc_pending_q;
    reg [5:0] iter_q;
    reg signed [39:0] x_q;
    reg signed [39:0] y_q;
    reg signed [39:0] angle_q;

    reg signed [39:0] x_next;
    reg signed [39:0] y_next;
    reg signed [39:0] angle_next;
    reg signed [39:0] atan_value;

    assign in_ready = !busy_q && !calc_pending_q && !out_valid;

    function signed [39:0] atan_lut;
        input [5:0] index;
        begin
            case (index)
                6'd0:  atan_lut = 40'sd268435456;
                6'd1:  atan_lut = 40'sd158466703;
                6'd2:  atan_lut = 40'sd83729454;
                6'd3:  atan_lut = 40'sd42502378;
                6'd4:  atan_lut = 40'sd21333666;
                6'd5:  atan_lut = 40'sd10677233;
                6'd6:  atan_lut = 40'sd5339919;
                6'd7:  atan_lut = 40'sd2670123;
                6'd8:  atan_lut = 40'sd1335082;
                6'd9:  atan_lut = 40'sd667543;
                6'd10: atan_lut = 40'sd333772;
                6'd11: atan_lut = 40'sd166886;
                6'd12: atan_lut = 40'sd83443;
                6'd13: atan_lut = 40'sd41722;
                6'd14: atan_lut = 40'sd20861;
                6'd15: atan_lut = 40'sd10430;
                6'd16: atan_lut = 40'sd5215;
                6'd17: atan_lut = 40'sd2608;
                6'd18: atan_lut = 40'sd1304;
                6'd19: atan_lut = 40'sd652;
                6'd20: atan_lut = 40'sd326;
                6'd21: atan_lut = 40'sd163;
                6'd22: atan_lut = 40'sd81;
                6'd23: atan_lut = 40'sd41;
                6'd24: atan_lut = 40'sd20;
                6'd25: atan_lut = 40'sd10;
                6'd26: atan_lut = 40'sd5;
                6'd27: atan_lut = 40'sd3;
                6'd28: atan_lut = 40'sd1;
                6'd29: atan_lut = 40'sd1;
                6'd30: atan_lut = 40'sd0;
                default: atan_lut = 40'sd0;
            endcase
        end
    endfunction

    function [`CMH_INDEX_WIDTH-1:0] angle_to_sector;
        input signed [39:0] angle_in;
        reg signed [7:0] branch_count;
        reg signed [47:0] product;
        reg signed [47:0] numerator;
        reg signed [47:0] quotient;
        begin
            branch_count = `CMH_BRANCHES;
            product = $signed(angle_in) * $signed(branch_count);
            numerator = product - 48'sd1073741824;

            quotient = numerator >>> 31;
            if (|numerator[30:0])
                quotient = quotient + 48'sd1;

            if (quotient < 0)
                quotient = quotient + `CMH_BRANCHES;
            else if (quotient >= `CMH_BRANCHES)
                quotient = quotient - `CMH_BRANCHES;

            angle_to_sector = quotient[`CMH_INDEX_WIDTH-1:0];
        end
    endfunction

    always @* begin
        atan_value = atan_lut(iter_q);
        x_next = x_q;
        y_next = y_q;
        angle_next = angle_q;

        if (y_q > 0) begin
            x_next = x_q + (y_q >>> iter_q);
            y_next = y_q - (x_q >>> iter_q);
            angle_next = angle_q + atan_value;
        end else if (y_q < 0) begin
            x_next = x_q - (y_q >>> iter_q);
            y_next = y_q + (x_q >>> iter_q);
            angle_next = angle_q - atan_value;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            busy_q         <= 1'b0;
            calc_pending_q <= 1'b0;
            iter_q         <= 6'd0;
            x_q            <= 40'sd0;
            y_q            <= 40'sd0;
            angle_q        <= 40'sd0;
            out_valid      <= 1'b0;
            sector_idx     <= {`CMH_INDEX_WIDTH{1'b0}};
        end else begin
            out_valid <= 1'b0;

            if (in_valid && in_ready) begin
                iter_q <= 6'd0;
                if ((x_in == 32'sd0) && (y_in == 32'sd0)) begin
                    x_q            <= 40'sd0;
                    y_q            <= 40'sd0;
                    angle_q        <= 40'sd0;
                    busy_q         <= 1'b0;
                    calc_pending_q <= 1'b1;
                end else if (x_in < 0) begin
                    x_q <= -$signed({{8{x_in[31]}}, x_in});
                    y_q <= -$signed({{8{y_in[31]}}, y_in});
                    angle_q <= (y_in >= 0) ? PI_CODE : -PI_CODE;
                    busy_q         <= 1'b1;
                    calc_pending_q <= 1'b0;
                end else begin
                    x_q <= $signed({{8{x_in[31]}}, x_in});
                    y_q <= $signed({{8{y_in[31]}}, y_in});
                    angle_q        <= 40'sd0;
                    busy_q         <= 1'b1;
                    calc_pending_q <= 1'b0;
                end
            end else if (busy_q) begin
                x_q     <= x_next;
                y_q     <= y_next;
                angle_q <= angle_next;

                if (iter_q == LAST_ITER) begin
                    busy_q         <= 1'b0;
                    calc_pending_q <= 1'b1;
                end else begin
                    iter_q <= iter_q + 6'd1;
                end
            end else if (calc_pending_q) begin
                sector_idx     <= angle_to_sector(angle_q);
                out_valid      <= 1'b1;
                calc_pending_q <= 1'b0;
            end
        end
    end
endmodule
