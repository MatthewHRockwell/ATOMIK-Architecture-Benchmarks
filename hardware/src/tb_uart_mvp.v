`timescale 1ns/1ps

module tb_uart_mvp;

    // Simulation clock
    reg clk = 0;
    always #5 clk = ~clk; // 100 MHz

    reg rst_n = 0;

    wire uart_tx;

    // Tune for sim speed
    localparam integer CLKS_PER_BIT  = 16;
    localparam integer REPORT_CYCLES = 20000;

    atomik_uart_mvp_top #(
        .CLKS_PER_BIT(CLKS_PER_BIT),
        .REPORT_CYCLES(REPORT_CYCLES)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .uart_tx_o(uart_tx)
    );

    // Decode UART in sim and print as characters
    wire [7:0] rx_byte;
    wire       rx_valid;

    uart_rx_sim #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_tx),
        .data_out(rx_byte),
        .data_valid(rx_valid)
    );

    initial begin
        $dumpfile("uart_mvp.vcd");
        $dumpvars(0, tb_uart_mvp);

        // reset
        rst_n = 0;
        repeat (10) @(posedge clk);
        rst_n = 1;

        // Run long enough to see multiple reports
        repeat (200000) @(posedge clk);

        $finish;
    end

    // Print decoded stream
    always @(posedge clk) begin
        if (rx_valid) begin
            // print as ASCII
            $write("%c", rx_byte);
        end
    end

endmodule
