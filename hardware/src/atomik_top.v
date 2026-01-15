// atomik_top.v
// Stream wrapper + 1-deep output holding register + telemetry.
// For UART-only MVP, we tie out_ready=1 and ignore the event payload,
// but counters prove behavior.
`timescale 1ns/1ps

module atomik_top #(
    parameter integer DEPTH  = 625,
    parameter integer ADDR_W = 10
)(
    input  wire              clk,
    input  wire              rst_n,

    input  wire              in_valid,
    output wire              in_ready,
    input  wire [ADDR_W-1:0] in_addr,
    input  wire [3:0]        in_pattern,

    output reg               out_valid,
    input  wire              out_ready,

    output reg               out_ev_delta,
    output reg               out_ev_first_touch,
    output reg               out_ev_drop_invalid,
    output reg  [ADDR_W-1:0] out_addr,
    output reg  [3:0]        out_delta,
    output reg               out_is_zero,

    output reg [31:0]        cnt_in_accepted,
    output reg [31:0]        cnt_ev_emitted,
    output reg [31:0]        cnt_delta,
    output reg [31:0]        cnt_first_touch,
    output reg [31:0]        cnt_drop_invalid,
    output reg [31:0]        cnt_out_stalls
);

    // Stall input only if output buffer is holding data and downstream isn't ready.
    assign in_ready = !(out_valid && !out_ready);

    wire               ev_valid;
    wire               ev_delta;
    wire               ev_first_touch;
    wire               ev_drop_invalid;
    wire [ADDR_W-1:0]  ev_addr;
    wire [3:0]         ev_delta_val;
    wire               ev_is_zero;

    atomik_core #(
        .DEPTH(DEPTH),
        .ADDR_W(ADDR_W)
    ) u_core (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(in_valid && in_ready),
        .addr(in_addr),
        .pattern_in(in_pattern),

        .ev_valid(ev_valid),
        .ev_delta(ev_delta),
        .ev_first_touch(ev_first_touch),
        .ev_drop_invalid(ev_drop_invalid),
        .ev_addr(ev_addr),
        .ev_delta_val(ev_delta_val),
        .ev_is_zero(ev_is_zero)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid          <= 1'b0;
            out_ev_delta       <= 1'b0;
            out_ev_first_touch <= 1'b0;
            out_ev_drop_invalid<= 1'b0;
            out_addr           <= {ADDR_W{1'b0}};
            out_delta          <= 4'h0;
            out_is_zero        <= 1'b0;

            cnt_in_accepted    <= 32'd0;
            cnt_ev_emitted     <= 32'd0;
            cnt_delta          <= 32'd0;
            cnt_first_touch    <= 32'd0;
            cnt_drop_invalid   <= 32'd0;
            cnt_out_stalls     <= 32'd0;
        end else begin
            if (out_valid && !out_ready)
                cnt_out_stalls <= cnt_out_stalls + 1;

            if (in_valid && in_ready)
                cnt_in_accepted <= cnt_in_accepted + 1;

            // Drain buffer if downstream accepts it
            if (out_valid && out_ready)
                out_valid <= 1'b0;

            // Capture event from core if buffer is free (or being freed)
            if (ev_valid) begin
                if (!out_valid || (out_valid && out_ready)) begin
                    out_valid          <= 1'b1;
                    out_ev_delta       <= ev_delta;
                    out_ev_first_touch <= ev_first_touch;
                    out_ev_drop_invalid<= ev_drop_invalid;
                    out_addr           <= ev_addr;
                    out_delta          <= ev_delta_val;
                    out_is_zero        <= ev_is_zero;

                    cnt_ev_emitted <= cnt_ev_emitted + 1;
                    if (ev_delta)        cnt_delta        <= cnt_delta + 1;
                    if (ev_first_touch)  cnt_first_touch  <= cnt_first_touch + 1;
                    if (ev_drop_invalid) cnt_drop_invalid <= cnt_drop_invalid + 1;
                end
            end
        end
    end

endmodule
