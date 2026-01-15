// atomik_core.v
// Transient State Evolution core with seen[] admission gate.
// Emits events: DELTA, FIRST_TOUCH, DROP_INVALID.
// No absolute state is ever output.
`timescale 1ns/1ps

module atomik_core #(
    parameter integer DEPTH  = 625,
    parameter integer ADDR_W = 10
)(
    input  wire              clk,
    input  wire              rst_n,

    input  wire              valid_in,
    input  wire [ADDR_W-1:0] addr,
    input  wire [3:0]        pattern_in,

    output reg               ev_valid,
    output reg               ev_delta,
    output reg               ev_first_touch,
    output reg               ev_drop_invalid,
    output reg  [ADDR_W-1:0] ev_addr,
    output reg  [3:0]        ev_delta_val,
    output reg               ev_is_zero
);

    reg [3:0] state_memory [0:DEPTH-1];
    reg       seen_memory  [0:DEPTH-1];

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ev_valid        <= 1'b0;
            ev_delta        <= 1'b0;
            ev_first_touch  <= 1'b0;
            ev_drop_invalid <= 1'b0;
            ev_addr         <= {ADDR_W{1'b0}};
            ev_delta_val    <= 4'h0;
            ev_is_zero      <= 1'b0;

            for (i = 0; i < DEPTH; i = i + 1) begin
                state_memory[i] <= 4'h0;
                seen_memory[i]  <= 1'b0;
            end
        end else begin
            // defaults
            ev_valid        <= 1'b0;
            ev_delta        <= 1'b0;
            ev_first_touch  <= 1'b0;
            ev_drop_invalid <= 1'b0;
            ev_delta_val    <= 4'h0;
            ev_is_zero      <= 1'b0;

            if (valid_in) begin
                ev_addr <= addr;

                if (addr >= DEPTH) begin
                    ev_valid        <= 1'b1;
                    ev_drop_invalid <= 1'b1;
                end else if (!seen_memory[addr]) begin
                    // First touch: learn silently
                    seen_memory[addr]  <= 1'b1;
                    state_memory[addr] <= pattern_in;

                    ev_valid       <= 1'b1;
                    ev_first_touch <= 1'b1;
                end else begin
                    // Delta: Δ = P XOR S_prev
                    ev_valid     <= 1'b1;
                    ev_delta     <= 1'b1;
                    ev_delta_val <= (pattern_in ^ state_memory[addr]);
                    ev_is_zero   <= ((pattern_in ^ state_memory[addr]) == 4'h0);

                    state_memory[addr] <= pattern_in;
                end
            end
        end
    end

endmodule
