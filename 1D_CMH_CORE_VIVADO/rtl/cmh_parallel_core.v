`timescale 1ns/1ps
`include "cmh_config.vh"

module cmh_parallel_core #(
    parameter signed [31:0] SIGMA_RE = `CMH_SIGMA_RE_Q824,
    parameter signed [31:0] SIGMA_IM = `CMH_SIGMA_IM_Q824,
    parameter signed [31:0] Z0_RE    = `CMH_Z0_RE_Q824,
    parameter signed [31:0] Z0_IM    = `CMH_Z0_IM_Q824
) (
    input  wire                                  clk,
    input  wire                                  rstn,

    input  wire                                  seed_valid,
    output wire                                  seed_ready,
    input  wire signed [31:0]                    seed_re,
    input  wire signed [31:0]                    seed_im,

    input  wire                                  step_valid,
    output wire                                  step_ready,

    output reg  [`CMH_BRANCHES*32-1:0]           branches_re,
    output reg  [`CMH_BRANCHES*32-1:0]           branches_im,
    output reg                                   branches_valid,
    input  wire                                  branches_ready,

    output wire signed [31:0]                    state_re,
    output wire signed [31:0]                    state_im
);
    localparam [2:0] S_IDLE        = 3'd0;
    localparam [2:0] S_WAIT_SECTOR = 3'd1;
    localparam [2:0] S_ISSUE       = 3'd2;
    localparam [2:0] S_WAIT_MUL    = 3'd3;
    localparam [2:0] S_HOLD        = 3'd4;

    reg [2:0] fsm_q;
    reg signed [31:0] z_re_q;
    reg signed [31:0] z_im_q;
    reg signed [31:0] base_re_q;
    reg signed [31:0] base_im_q;
    reg signed [31:0] fold_re_q;
    reg signed [31:0] fold_im_q;
    reg [`CMH_INDEX_WIDTH-1:0] sector_q;

    wire signed [31:0] fold_re_now;
    wire signed [31:0] fold_im_now;

    wire sector_in_valid;
    wire sector_in_ready;
    wire sector_out_valid;
    wire [`CMH_INDEX_WIDTH-1:0] sector_now;

    wire issue = (fsm_q == S_ISSUE);
    wire sigma_valid;
    wire signed [31:0] sigma_term_re;
    wire signed [31:0] sigma_term_im;

    wire [`CMH_BRANCHES-1:0] branch_mul_valid;
    wire [`CMH_BRANCHES*32-1:0] branch_next_re_bus;
    wire [`CMH_BRANCHES*32-1:0] branch_next_im_bus;

    assign seed_ready = (fsm_q == S_IDLE) && !branches_valid;
    assign step_ready = (fsm_q == S_IDLE) && !branches_valid
                      && !seed_valid && sector_in_ready;
    assign state_re = z_re_q;
    assign state_im = z_im_q;
    assign sector_in_valid = step_valid && step_ready;

    cfold_mod1_q824 u_cfold (
        .z_re(z_re_q),
        .z_im(z_im_q),
        .fold_re(fold_re_now),
        .fold_im(fold_im_now)
    );

    cmh_arg_sector_cordic u_arg_sector (
        .clk(clk),
        .rstn(rstn),
        .in_valid(sector_in_valid),
        .in_ready(sector_in_ready),
        .x_in(z_re_q),
        .y_in(z_im_q),
        .out_valid(sector_out_valid),
        .sector_idx(sector_now)
    );

    cmul_q824_pipe u_sigma_mul (
        .clk(clk),
        .rstn(rstn),
        .in_valid(issue),
        .a_re(SIGMA_RE),
        .a_im(SIGMA_IM),
        .b_re(fold_re_q),
        .b_im(fold_im_q),
        .out_valid(sigma_valid),
        .p_re(sigma_term_re),
        .p_im(sigma_term_im)
    );

    function [`CMH_INDEX_WIDTH-1:0] coeff_index;
        input [`CMH_INDEX_WIDTH-1:0] branch_j;
        input [`CMH_INDEX_WIDTH-1:0] sector_idx;
        reg signed [`CMH_INDEX_WIDTH:0] diff;
        begin
            diff = $signed({1'b0, branch_j}) - $signed({1'b0, sector_idx});
            if (diff < 0)
                diff = diff + `CMH_BRANCHES;
            coeff_index = diff[`CMH_INDEX_WIDTH-1:0];
        end
    endfunction

    genvar g;
    generate
        for (g = 0; g < `CMH_BRANCHES; g = g + 1) begin : G_BRANCH
            localparam [`CMH_INDEX_WIDTH-1:0] BRANCH_J = g;
            wire [`CMH_INDEX_WIDTH-1:0] rom_idx;
            wire signed [31:0] coeff_re;
            wire signed [31:0] coeff_im;
            wire signed [31:0] nominal_re;
            wire signed [31:0] nominal_im;
            wire signed [32:0] next_re_ext;
            wire signed [32:0] next_im_ext;
            wire signed [31:0] next_re;
            wire signed [31:0] next_im;

            assign rom_idx = coeff_index(BRANCH_J, sector_q);

            cmh_branch_coeff_rom u_coeff_rom (
                .idx(rom_idx),
                .coeff_re(coeff_re),
                .coeff_im(coeff_im)
            );

            cmul_q824_pipe u_branch_mul (
                .clk(clk),
                .rstn(rstn),
                .in_valid(issue),
                .a_re(coeff_re),
                .a_im(coeff_im),
                .b_re(base_re_q),
                .b_im(base_im_q),
                .out_valid(branch_mul_valid[g]),
                .p_re(nominal_re),
                .p_im(nominal_im)
            );

            assign next_re_ext = $signed({nominal_re[31], nominal_re})
                               + $signed({sigma_term_re[31], sigma_term_re});
            assign next_im_ext = $signed({nominal_im[31], nominal_im})
                               + $signed({sigma_term_im[31], sigma_term_im});
            assign next_re = next_re_ext[31:0];
            assign next_im = next_im_ext[31:0];

            assign branch_next_re_bus[g*32 +: 32] = next_re;
            assign branch_next_im_bus[g*32 +: 32] = next_im;
        end
    endgenerate

    always @(posedge clk) begin
        if (!rstn) begin
            fsm_q          <= S_IDLE;
            z_re_q         <= Z0_RE;
            z_im_q         <= Z0_IM;
            base_re_q      <= 32'sd0;
            base_im_q      <= 32'sd0;
            fold_re_q      <= 32'sd0;
            fold_im_q      <= 32'sd0;
            sector_q       <= {`CMH_INDEX_WIDTH{1'b0}};
            branches_re    <= {(`CMH_BRANCHES*32){1'b0}};
            branches_im    <= {(`CMH_BRANCHES*32){1'b0}};
            branches_valid <= 1'b0;
        end else begin
            case (fsm_q)
                S_IDLE: begin
                    if (seed_valid && seed_ready) begin
                        z_re_q <= seed_re;
                        z_im_q <= seed_im;
                    end else if (step_valid && step_ready) begin
                        base_re_q <= z_re_q;
                        base_im_q <= z_im_q;
                        fold_re_q <= fold_re_now;
                        fold_im_q <= fold_im_now;
                        fsm_q     <= S_WAIT_SECTOR;
                    end
                end

                S_WAIT_SECTOR: begin
                    if (sector_out_valid) begin
                        sector_q <= sector_now;
                        fsm_q    <= S_ISSUE;
                    end
                end

                S_ISSUE: begin
                    fsm_q <= S_WAIT_MUL;
                end

                S_WAIT_MUL: begin
                    if (sigma_valid && branch_mul_valid[0]) begin
                        branches_re    <= branch_next_re_bus;
                        branches_im    <= branch_next_im_bus;
                        branches_valid <= 1'b1;
                        z_re_q         <= branch_next_re_bus[31:0];
                        z_im_q         <= branch_next_im_bus[31:0];
                        fsm_q          <= S_HOLD;
                    end
                end

                S_HOLD: begin
                    if (branches_valid && branches_ready) begin
                        branches_valid <= 1'b0;
                        fsm_q          <= S_IDLE;
                    end
                end

                default: begin
                    fsm_q <= S_IDLE;
                end
            endcase
        end
    end
endmodule
