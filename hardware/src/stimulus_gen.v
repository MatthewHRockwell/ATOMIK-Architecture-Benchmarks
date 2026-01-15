// stimulus_gen.v
// Deterministic internal stimulus:
// - Walk addr 0..DEPTH-1
// - 4-bit LFSR pattern
// - Always asserts valid (UART never throttles the core in this MVP)
`timescale 1ns/1ps

module stimulus_gen #(
    parameter integer DEPTH  = 625,
    parameter integer ADDR_W = 10
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              in_ready,

    output reg               in_valid,
    output reg  [ADDR_W-1:0] in_addr,
    output reg  [3:0]        in_pattern
);

    reg [3:0] lfsr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_valid   <= 1'b0;
            in_addr    <= {ADDR_W{1'b0}};
            in_pattern <= 4'h1;
            lfsr       <= 4'hB; // seed
        end else begin
            in_valid <= 1'b1;

            if (in_ready) begin
                // addr walk
                if (in_addr == (DEPTH-1))
                    in_addr <= {ADDR_W{1'b0}};
                else
                    in_addr <= in_addr + 1'b1;

                // 4-bit LFSR: x^4 + x^3 + 1 (one of several acceptable taps)
                lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[2]};
                in_pattern <= lfsr;
            end
        end
    end

endmodule
