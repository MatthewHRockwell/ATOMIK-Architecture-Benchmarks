// uart_rx_sim.v - simulation UART receiver (8N1), matches uart_tx CLKS_PER_BIT.
`timescale 1ns/1ps

module uart_rx_sim #(
    parameter integer CLKS_PER_BIT = 16
)(
    input  wire clk,
    input  wire rst_n,
    input  wire rx,

    output reg  [7:0] data_out,
    output reg        data_valid
);

    localparam integer IDLE  = 0;
    localparam integer START = 1;
    localparam integer DATA  = 2;
    localparam integer STOP  = 3;

    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            clk_cnt    <= 0;
            bit_idx    <= 0;
            shift      <= 0;
            data_out   <= 0;
            data_valid <= 0;
        end else begin
            data_valid <= 0;

            case (state)
                IDLE: begin
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (rx == 1'b0) state <= START;
                end

                START: begin
                    if (clk_cnt == (CLKS_PER_BIT/2)) begin
                        if (rx == 1'b0) begin
                            clk_cnt <= 0;
                            state   <= DATA;
                        end else state <= IDLE;
                    end else clk_cnt <= clk_cnt + 1;
                end

                DATA: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        shift[bit_idx] <= rx;
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 0;
                            state   <= STOP;
                        end else bit_idx <= bit_idx + 1;
                    end else clk_cnt <= clk_cnt + 1;
                end

                STOP: begin
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        data_out <= shift;
                        data_valid <= 1'b1;
                        state <= IDLE;
                    end else clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end

endmodule
