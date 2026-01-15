// atomik_uart_mvp_top.v
// UART-only MVP top for simulation-first.
// FIXES:
//  1) Prevent report overlap: only trigger a report when not currently sending.
//  2) Add a 1-byte pending stage so uart_tx latches a stable byte.
//  3) Snapshot counters only when a report actually begins.
//  4) Do NOT use "\r" / "\n" escapes in 8-bit assignments; use 8'h0D / 8'h0A.
`timescale 1ns/1ps

module atomik_uart_mvp_top #(
    parameter integer DEPTH         = 625,
    parameter integer ADDR_W        = 10,
    parameter integer CLKS_PER_BIT  = 16,
    parameter integer REPORT_CYCLES = 20000  // MUST be >= ~11000 for CLKS_PER_BIT=16
)(
    input  wire clk,
    input  wire rst_n,
    output wire uart_tx_o
);

    // -------------------------
    // ATOMiK input stimulus
    // -------------------------
    wire stim_valid;
    wire [ADDR_W-1:0] stim_addr;
    wire [3:0] stim_pattern;
    wire in_ready;

    stimulus_gen #(
        .DEPTH(DEPTH),
        .ADDR_W(ADDR_W)
    ) u_stim (
        .clk(clk),
        .rst_n(rst_n),
        .in_ready(in_ready),
        .in_valid(stim_valid),
        .in_addr(stim_addr),
        .in_pattern(stim_pattern)
    );

    // -------------------------
    // ATOMiK wrapper
    // -------------------------
    wire out_valid;
    wire out_ready = 1'b1;

    wire out_ev_delta, out_ev_first_touch, out_ev_drop_invalid;
    wire [ADDR_W-1:0] out_addr;
    wire [3:0] out_delta;
    wire out_is_zero;

    wire [31:0] cnt_in_accepted;
    wire [31:0] cnt_ev_emitted;
    wire [31:0] cnt_delta;
    wire [31:0] cnt_first_touch;
    wire [31:0] cnt_drop_invalid;
    wire [31:0] cnt_out_stalls;

    atomik_top #(
        .DEPTH(DEPTH),
        .ADDR_W(ADDR_W)
    ) u_atomik (
        .clk(clk),
        .rst_n(rst_n),

        .in_valid(stim_valid),
        .in_ready(in_ready),
        .in_addr(stim_addr),
        .in_pattern(stim_pattern),

        .out_valid(out_valid),
        .out_ready(out_ready),

        .out_ev_delta(out_ev_delta),
        .out_ev_first_touch(out_ev_first_touch),
        .out_ev_drop_invalid(out_ev_drop_invalid),
        .out_addr(out_addr),
        .out_delta(out_delta),
        .out_is_zero(out_is_zero),

        .cnt_in_accepted(cnt_in_accepted),
        .cnt_ev_emitted(cnt_ev_emitted),
        .cnt_delta(cnt_delta),
        .cnt_first_touch(cnt_first_touch),
        .cnt_drop_invalid(cnt_drop_invalid),
        .cnt_out_stalls(cnt_out_stalls)
    );

    // -------------------------
    // UART TX
    // -------------------------
    reg  [7:0] tx_byte_reg;
    reg        tx_fire_reg;
    wire       tx_ready;

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
        .clk(clk), .rst_n(rst_n),
        .data_in(tx_byte_reg),
        .data_valid(tx_fire_reg),
        .ready(tx_ready),
        .tx(uart_tx_o)
    );

    // -------------------------
    // Constants
    // -------------------------
    localparam [7:0] CR = 8'h0D;
    localparam [7:0] LF = 8'h0A;

    // -------------------------
    // ASCII helpers (hex)
    // -------------------------
    function [7:0] hexchar(input [3:0] n);
        begin
            if (n < 10) hexchar = "0" + n;
            else        hexchar = "A" + (n - 10);
        end
    endfunction

    // Snapshot registers (stable while printing)
    reg [31:0] snap_in, snap_em, snap_ft, snap_iv, snap_st;

    // Report scheduler
    reg [31:0] report_cnt;
    reg        want_report;

    // Stream state
    reg        sending;
    reg [7:0]  idx;
    reg        header_sent;

    // 1-byte pending stage
    reg        pend_valid;
    reg [7:0]  pend_byte;

    // -------------------------
    // Header: "ATOMiK UART MVP\r\n"
    // -------------------------
    localparam integer HDR_LEN = 17;

    function [7:0] hdr_byte(input [7:0] i);
        begin
            hdr_byte = 8'h20;
            case (i)
                8'd0:  hdr_byte = "A";
                8'd1:  hdr_byte = "T";
                8'd2:  hdr_byte = "O";
                8'd3:  hdr_byte = "M";
                8'd4:  hdr_byte = "i";
                8'd5:  hdr_byte = "K";
                8'd6:  hdr_byte = " ";
                8'd7:  hdr_byte = "U";
                8'd8:  hdr_byte = "A";
                8'd9:  hdr_byte = "R";
                8'd10: hdr_byte = "T";
                8'd11: hdr_byte = " ";
                8'd12: hdr_byte = "M";
                8'd13: hdr_byte = "V";
                8'd14: hdr_byte = "P";
                8'd15: hdr_byte = CR;
                8'd16: hdr_byte = LF;
            endcase
        end
    endfunction

    // -------------------------
    // CFG line (static numbers are OK in simulation; keep it simple)
    // "CFG DEPTH=625 CPB=16 RC=20000\r\n"
    // If you later want true decimal formatting from parameters, we can add it,
    // but for MVP this fixed string is enough for licensee demos.
    // -------------------------
    localparam integer CFG_LEN = 31;

    function [7:0] cfg_byte(input [7:0] i);
        begin
            cfg_byte = 8'h20;
            case (i)
                8'd0:  cfg_byte = "C";
                8'd1:  cfg_byte = "F";
                8'd2:  cfg_byte = "G";
                8'd3:  cfg_byte = " ";
                8'd4:  cfg_byte = "D";
                8'd5:  cfg_byte = "E";
                8'd6:  cfg_byte = "P";
                8'd7:  cfg_byte = "T";
                8'd8:  cfg_byte = "H";
                8'd9:  cfg_byte = "=";
                8'd10: cfg_byte = "6";
                8'd11: cfg_byte = "2";
                8'd12: cfg_byte = "5";
                8'd13: cfg_byte = " ";
                8'd14: cfg_byte = "C";
                8'd15: cfg_byte = "P";
                8'd16: cfg_byte = "B";
                8'd17: cfg_byte = "=";
                8'd18: cfg_byte = "1";
                8'd19: cfg_byte = "6";
                8'd20: cfg_byte = " ";
                8'd21: cfg_byte = "R";
                8'd22: cfg_byte = "C";
                8'd23: cfg_byte = "=";
                8'd24: cfg_byte = "2";
                8'd25: cfg_byte = "0";
                8'd26: cfg_byte = "0";
                8'd27: cfg_byte = "0";
                8'd28: cfg_byte = "0";
                8'd29: cfg_byte = CR;
                8'd30: cfg_byte = LF;
            endcase
        end
    endfunction

    // -------------------------
    // Report line:
    // "IN=XXXXXXXX EM=XXXXXXXX FT=XXXXXXXX IV=XXXXXXXX ST=XXXXXXXX\r\n"
    // -------------------------
    localparam integer REP_LEN = 61;

    function [7:0] rep_byte(input [7:0] i);
        reg [31:0] v;
        reg [3:0]  nib;
        begin
            rep_byte = 8'h20;

            if (i==0) rep_byte="I";
            else if (i==1) rep_byte="N";
            else if (i==2) rep_byte="=";
            else if (i>=3 && i<=10) begin
                v = snap_in;
                nib = (v >> (4*(10-i))) & 4'hF;
                rep_byte = hexchar(nib);
            end
            else if (i==11) rep_byte=" ";
            else if (i==12) rep_byte="E";
            else if (i==13) rep_byte="M";
            else if (i==14) rep_byte="=";
            else if (i>=15 && i<=22) begin
                v = snap_em;
                nib = (v >> (4*(22-i))) & 4'hF;
                rep_byte = hexchar(nib);
            end
            else if (i==23) rep_byte=" ";
            else if (i==24) rep_byte="F";
            else if (i==25) rep_byte="T";
            else if (i==26) rep_byte="=";
            else if (i>=27 && i<=34) begin
                v = snap_ft;
                nib = (v >> (4*(34-i))) & 4'hF;
                rep_byte = hexchar(nib);
            end
            else if (i==35) rep_byte=" ";
            else if (i==36) rep_byte="I";
            else if (i==37) rep_byte="V";
            else if (i==38) rep_byte="=";
            else if (i>=39 && i<=46) begin
                v = snap_iv;
                nib = (v >> (4*(46-i))) & 4'hF;
                rep_byte = hexchar(nib);
            end
            else if (i==47) rep_byte=" ";
            else if (i==48) rep_byte="S";
            else if (i==49) rep_byte="T";
            else if (i==50) rep_byte="=";
            else if (i>=51 && i<=58) begin
                v = snap_st;
                nib = (v >> (4*(58-i))) & 4'hF;
                rep_byte = hexchar(nib);
            end
            else if (i==59) rep_byte = CR;
            else if (i==60) rep_byte = LF;
        end
    endfunction

    // -------------------------
    // TX sequencing
    // Header first, then CFG once, then periodic reports
    // -------------------------
    localparam [1:0] PH_HDR = 2'd0;
    localparam [1:0] PH_CFG = 2'd1;
    localparam [1:0] PH_REP = 2'd2;

    reg [1:0] phase;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            report_cnt   <= 0;
            want_report  <= 0;
            sending      <= 0;
            idx          <= 0;
            header_sent  <= 0;
            phase        <= PH_HDR;

            snap_in <= 0; snap_em <= 0; snap_ft <= 0; snap_iv <= 0; snap_st <= 0;

            pend_valid   <= 0;
            pend_byte    <= 8'h00;

            tx_byte_reg  <= 8'h00;
            tx_fire_reg  <= 1'b0;
        end else begin
            tx_fire_reg <= 1'b0;

            // Scheduler: only arm a report when idle and past header+cfg
            if (report_cnt == REPORT_CYCLES-1) begin
                report_cnt <= 0;
                if (!sending && header_sent) begin
                    want_report <= 1'b1;
                end
            end else begin
                report_cnt <= report_cnt + 1;
            end

            // Start header once
            if (!header_sent && !sending) begin
                sending <= 1'b1;
                idx     <= 0;
                phase   <= PH_HDR;
            end

            // After header completes, send CFG once
            if (header_sent && (phase == PH_CFG) && !sending) begin
                // idle state after cfg; nothing special here
            end

            // Start report if armed and idle and header+cfg have been sent
            if (want_report && !sending && header_sent && (phase == PH_REP)) begin
                want_report <= 1'b0;

                // snapshot ONLY when report begins
                snap_in <= cnt_in_accepted;
                snap_em <= cnt_ev_emitted;
                snap_ft <= cnt_first_touch;
                snap_iv <= cnt_drop_invalid;
                snap_st <= cnt_out_stalls;

                sending <= 1'b1;
                idx     <= 0;
            end

            // If UART is ready and we have a pending byte, fire it.
            if (pend_valid && tx_ready) begin
                tx_byte_reg <= pend_byte;
                tx_fire_reg <= 1'b1;
                pend_valid  <= 1'b0;
            end

            // If sending and no pending byte is staged, stage next byte.
            if (sending && !pend_valid) begin
                if (phase == PH_HDR) begin
                    pend_byte  <= hdr_byte(idx);
                    pend_valid <= 1'b1;

                    if (idx == HDR_LEN-1) begin
                        sending     <= 1'b0;
                        header_sent <= 1'b1;
                        idx         <= 0;

                        // Immediately queue CFG as next phase
                        phase       <= PH_CFG;
                        sending     <= 1'b1;
                    end else begin
                        idx <= idx + 1;
                    end

                end else if (phase == PH_CFG) begin
                    pend_byte  <= cfg_byte(idx);
                    pend_valid <= 1'b1;

                    if (idx == CFG_LEN-1) begin
                        sending <= 1'b0;
                        idx     <= 0;

                        // Now we are in steady-state periodic reports
                        phase   <= PH_REP;
                    end else begin
                        idx <= idx + 1;
                    end

                end else begin
                    // PH_REP
                    pend_byte  <= rep_byte(idx);
                    pend_valid <= 1'b1;

                    if (idx == REP_LEN-1) begin
                        sending <= 1'b0;
                        idx     <= 0;
                    end else begin
                        idx <= idx + 1;
                    end
                end
            end

            // If we're in PH_REP but want_report got set while busy, we start on idle above
            if (phase == PH_REP) begin
                // no-op; phase remains
            end
        end
    end

endmodule
