// -----------------------------------------------------------------------------
// Self-checking testbench for speck32_64_enc
//
// Coverage:
//   1. Reset behaviour (outputs idle after reset, reset in the middle of a run)
//   2. Official Speck32/64 test vector from the Speck paper
//   3. Boundary vectors: all-zero / all-ones key and plaintext
//   4. Handshake rules: done timing (exactly 22 clocks), done clears on start,
//      done + ciphertext hold while idle, start ignored while busy
//   5. Back-to-back encryptions
//   6. 500 random vectors against an independent reference function
//
// The directed expected values were produced by a separate Python model that
// reproduces the official vector, so the DUT, the in-testbench reference
// function, and the Python model are three independent checks.
// -----------------------------------------------------------------------------
`timescale 1ns/1ps

module tb_speck32_64_enc;

    reg         clk;
    reg         rst_n;
    reg         start;
    reg  [63:0] key;
    reg  [31:0] plaintext;
    wire [31:0] ciphertext;
    wire        done;

    integer errors;
    integer tests;
    integer seed;

    speck32_64_enc dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .key        (key),
        .plaintext  (plaintext),
        .ciphertext (ciphertext),
        .done       (done)
    );

    // 100 MHz clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Reference model: written differently from the RTL (loop + array of l words)
    // -------------------------------------------------------------------------
    function [31:0] ref_speck;
        input [63:0] k_in;
        input [31:0] p_in;
        reg [15:0] rx, ry, rk, t1, t2;
        reg [15:0] lw [0:24];
        integer i;
        begin
            rk    = k_in[15:0];
            lw[0] = k_in[31:16];
            lw[1] = k_in[47:32];
            lw[2] = k_in[63:48];
            rx    = p_in[31:16];
            ry    = p_in[15:0];
            for (i = 0; i < 22; i = i + 1) begin
                t1 = (rx >> 7) | (rx << 9);          // ROR 7
                t1 = t1 + ry;
                rx = t1 ^ rk;
                t2 = (ry << 2) | (ry >> 14);         // ROL 2
                ry = t2 ^ rx;
                t1 = (lw[i] >> 7) | (lw[i] << 9);    // ROR 7
                t1 = t1 + rk;
                lw[i+3] = t1 ^ i[15:0];
                t2 = (rk << 2) | (rk >> 14);         // ROL 2
                rk = t2 ^ lw[i+3];
            end
            ref_speck = {rx, ry};
        end
    endfunction

    // -------------------------------------------------------------------------
    // Helpers (all stimulus is driven on negedge, DUT samples on posedge)
    // -------------------------------------------------------------------------
    task check_bit;
        input [511:0] name;
        input         cond;
        begin
            tests = tests + 1;
            if (!cond) begin
                errors = errors + 1;
                $display("FAIL: %0s  (t=%0t)", name, $time);
            end
        end
    endtask

    task do_reset;
        begin
            @(negedge clk);
            rst_n = 1'b0;
            start = 1'b0;
            repeat (2) @(negedge clk);
            rst_n = 1'b1;
            @(negedge clk);
        end
    endtask

    // Pulse start for one clock with the given key/plaintext
    task launch;
        input [63:0] k_in;
        input [31:0] p_in;
        begin
            @(negedge clk);
            key       = k_in;
            plaintext = p_in;
            start     = 1'b1;
            @(negedge clk);
            start     = 1'b0;
        end
    endtask

    // Wait for done; returns number of clocks after the start edge
    task wait_done;
        output integer cycles;
        integer n;
        begin
            n = 0;
            while (!done && n < 60) begin
                @(posedge clk);
                @(negedge clk);   // sample mid-cycle: safe with unit-delay cell models
                n = n + 1;
            end
            cycles = n;
        end
    endtask

    // Full encryption + compare against an expected ciphertext
    task run_and_check;
        input [511:0] name;
        input [63:0]  k_in;
        input [31:0]  p_in;
        input [31:0]  expected;
        integer cyc;
        begin
            launch(k_in, p_in);
            wait_done(cyc);
            tests = tests + 1;
            if (!done || cyc != 22) begin
                errors = errors + 1;
                $display("FAIL: %0s  done/latency wrong (done=%b, clocks=%0d, want 22)",
                         name, done, cyc);
            end else if (ciphertext !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s  key=%h pt=%h  got=%h  want=%h",
                         name, k_in, p_in, ciphertext, expected);
            end else begin
                $display("PASS: %0s  ct=%h", name, ciphertext);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Test sequence
    // -------------------------------------------------------------------------
    integer i, cyc;
    reg [63:0] rk;
    reg [31:0] rp;
    reg [31:0] first_ct;

    initial begin
        $dumpfile("speck_tb.vcd");
        $dumpvars(0, tb_speck32_64_enc);

        errors = 0;
        tests  = 0;
        seed   = 32'h5EC0_0032;
        rst_n  = 1'b0;
        start  = 1'b0;
        key    = 64'd0;
        plaintext = 32'd0;

        // ---- 1. Reset behaviour ---------------------------------------------
        repeat (3) @(negedge clk);
        check_bit("done low while in reset", done === 1'b0);
        rst_n = 1'b1;
        repeat (3) @(negedge clk);
        check_bit("done low after reset, before any start", done === 1'b0);
        check_bit("controller idle after reset", dut.busy === 1'b0);

        // ---- 2. Official test vector (Speck paper, Speck32/64) --------------
        run_and_check("official vector", 64'h1918_1110_0908_0100,
                      32'h6574_694c, 32'ha868_42f2);

        // ---- 4a. done and ciphertext hold while idle ------------------------
        first_ct = ciphertext;
        repeat (10) @(negedge clk);
        check_bit("done holds high while idle", done === 1'b1);
        check_bit("ciphertext stable while idle", ciphertext === first_ct);

        // ---- 3. Boundary vectors (expected values from the Python model) ----
        run_and_check("all-zero key & pt",   64'h0000_0000_0000_0000,
                      32'h0000_0000, 32'h2bb9_c642);
        run_and_check("all-ones key & pt",   64'hFFFF_FFFF_FFFF_FFFF,
                      32'hFFFF_FFFF, 32'hda39_7bef);
        run_and_check("zero key, ones pt",   64'h0000_0000_0000_0000,
                      32'hFFFF_FFFF, 32'hc3d4_93c9);
        run_and_check("ones key, zero pt",   64'hFFFF_FFFF_FFFF_FFFF,
                      32'h0000_0000, 32'h61f5_37b8);

        // ---- 4b. done clears when a new encryption starts -------------------
        launch(64'h1918_1110_0908_0100, 32'h6574_694c);
        check_bit("done cleared after start accepted", done === 1'b0);
        check_bit("busy after start", dut.busy === 1'b1);
        wait_done(cyc);
        check_bit("encryption finished again", done === 1'b1);

        // ---- 4c. start ignored while busy -----------------------------------
        launch(64'h1918_1110_0908_0100, 32'h6574_694c);
        repeat (5) @(negedge clk);
        key       = 64'hDEAD_BEEF_CAFE_F00D;      // try to hijack the run
        plaintext = 32'h1234_5678;
        start     = 1'b1;
        @(negedge clk);
        start     = 1'b0;
        wait_done(cyc);
        check_bit("start while busy is ignored (official vector survives)",
                  ciphertext === 32'ha868_42f2);

        // ---- 1b. reset in the middle of an encryption -----------------------
        launch(64'h1918_1110_0908_0100, 32'h6574_694c);
        repeat (7) @(negedge clk);
        rst_n = 1'b0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        check_bit("reset aborts the run: done low", done === 1'b0);
        check_bit("reset aborts the run: controller idle", dut.busy === 1'b0);
        repeat (30) @(negedge clk);
        check_bit("no spurious done after aborted run", done === 1'b0);
        run_and_check("encrypt correctly after mid-run reset",
                      64'h1918_1110_0908_0100, 32'h6574_694c, 32'ha868_42f2);

        // ---- 5. Back-to-back encryptions ------------------------------------
        run_and_check("b2b #1", 64'h1918_1110_0908_0100, 32'h6574_694c, 32'ha868_42f2);
        run_and_check("b2b #2", 64'h0000_0000_0000_0000, 32'h0000_0000, 32'h2bb9_c642);
        run_and_check("b2b #3", 64'hFFFF_FFFF_FFFF_FFFF, 32'hFFFF_FFFF, 32'hda39_7bef);

        // ---- 6. Random vectors vs reference function ------------------------
        for (i = 0; i < 500; i = i + 1) begin
            rk = {$random(seed), $random(seed)};
            rp = $random(seed);
            launch(rk, rp);
            wait_done(cyc);
            tests = tests + 1;
            if (!done || cyc != 22 || ciphertext !== ref_speck(rk, rp)) begin
                errors = errors + 1;
                $display("FAIL: random #%0d key=%h pt=%h got=%h want=%h clocks=%0d",
                         i, rk, rp, ciphertext, ref_speck(rk, rp), cyc);
            end
        end
        $display("random vectors: 500 run");

        // ---- Summary --------------------------------------------------------
        $display("------------------------------------------------");
        if (errors == 0)
            $display("ALL TESTS PASSED  (%0d checks)", tests);
        else
            $display("%0d of %0d CHECKS FAILED", errors, tests);
        $display("------------------------------------------------");
        $finish;
    end

    // Global watchdog
    initial begin
        #2_000_000;
        $display("FAIL: simulation watchdog expired");
        $finish;
    end

endmodule
