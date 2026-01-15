// uart_tx.v - 8N1 transmitter.
`timescale 1ns/1ps

module uart_tx #(
    parameter integer CLKS_PER_BIT = 16
)(
    input  wire clk,
    input  wire rst_n,

    input  wire [7:0] data_in,
    input  wire       data_valid,
    output wire       ready,

    output reg        tx
);

    localparam integer IDLE  = 0;
    localparam integer START = 1;
    localparam integer DATA  = 2;
    localparam integer STOP  = 3;

    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shift;

    assign ready = (state == IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            clk_cnt <= 0;
            bit_idx <= 0;
            shift   <= 0;
            tx      <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (data_valid) begin
                        shift <= data_in;
                        state <= START;
                    end
                end

                START: begin
                    tx <= 1'b0;
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        state <= DATA;
                    end else clk_cnt <= clk_cnt + 1;
                end

                DATA: begin
                    tx <= shift[bit_idx];
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 0;
                            state <= STOP;
                        end else bit_idx <= bit_idx + 1;
                    end else clk_cnt <= clk_cnt + 1;
                end

                STOP: begin
                    tx <= 1'b1;
                    if (clk_cnt == CLKS_PER_BIT-1) begin
                        clk_cnt <= 0;
                        state <= IDLE;
                    end else clk_cnt <= clk_cnt + 1;
                end
            endcase
        end
    end

endmodule
