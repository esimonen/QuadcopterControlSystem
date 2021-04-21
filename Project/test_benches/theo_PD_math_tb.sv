// Theo Hornung
// ece 551
// ex09
module PD_math_tb();

    // stim inputs
    logic clk, rst_n, vld;
    logic [15:0] desired, actual;
    // iDUT outputs
    logic [9:0] pterm;
    logic [11:0] dterm;

    logic fail;

    PD_math iDUT(.clk(clk), .rst_n(rst_n), .vld(vld), .desired(desired), .actual(actual), .pterm(pterm), .dterm(dterm));

    initial begin
        /* all of these are TODOs */
        fail = 0; // innocent until proven guilty
        // init all input stim signals
        clk = 0;
        rst_n = 1;
        vld = 1;

        /****************** (1-2) TEST - ALL ZEROES ******************/
        desired = 0;
        actual = 0;
        // (1) check for all zeroes in, pterm 0 and dterm x after first clock cycle
        @(posedge clk);
        if (pterm !== 0 || dterm !== 12'hxxx) begin
            fail = 1;
            $display("(1) All zeroes in, check after first clock cycle :: pterm (0 !== %h) :: dterm (12'hxxx !== %h)", pterm, dterm);
        end
        // (2) check for all zeroes in, pterm 0 and dterm 0 after 2nd clock cycle (flop has time to propogate)
        @(posedge clk);
        if (pterm !== 0 || dterm !== 0) begin
            fail = 1;
            $display("(2) All zeroes in, check after 2nd clock cycle :: pterm (0 !== %h) :: dterm (0 !== %h)", pterm, dterm);
        end
        /****************** END - ALL ZEROES ******************/

        /****************** (3-6) TEST - PTERM (non-zeroes) ******************/
        // (3) pos, non saturated err_sat
        actual = 16'h03BC;
        desired = 16'h02AB;
        // err = 17'h0111, err_sat = 10'h111
        // pterm = 10'h088 + 10'h022 = 10'h0AA
        @(posedge clk);
        if (pterm !== 10'h0AA) begin
            fail = 1;
            $display("(3) (expected, actual) :: pterm (10'h0AA, %h)", pterm);
        end
        // (4) pos, saturated err_sat
        actual = 16'h3BC0;
        desired = 16'h0001;
        // err = 17'h03BBF, err_sat = 10'h1FF
        // pterm = 10'h0FF + 10'h03F = 10'h13E
        @(posedge clk);
        if (pterm !== 10'h13E) begin
            fail = 1;
            $display("(4) (expected, actual) :: pterm (10'h13E, %h)", pterm);
        end
        // (5) neg, non saturated err_sat
        actual = 16'hFFFF;
        desired = 16'h00AA;
        // err = 17'h1FF55, err_sat = 10'h355
        // pterm = 10'h3AA + 10'h3EA = 10'h394
        @(posedge clk);
        if (pterm !== 10'h394) begin
            fail = 1;
            $display("(5) (expected, actual) :: pterm (10'h394, %h)", pterm);
        end
        // (6) neg, saturated err_sat
        actual = 16'h8080;
        desired = 16'h9000;
        // err = 17'h1F080, err_sat = 10'h200
        // pterm = 10'h300 + 10'h3C0 = 10'h2C0
        @(posedge clk);
        if (pterm !== 10'h2C0) begin
            fail = 1;
            $display("(6) (expected, actual) :: pterm (10'h394, %h)", pterm);
        end
        /****************** END - PTERM ******************/

        /****************** (7-12) TEST - DTERM (non-zeroes)******************/
        // (7) check reset condition, dterm should go to whatever err_sat is multiplied by DTERM coeff = 5'b00111
        actual = 16'h00AB;
        desired = 16'h009A;
        rst_n = 0; // assert reset to clear prev_err, is non-zero from previous test
        // err = 17'h00011, err_sat = 10'h011, D_diff = 10'h011, dterm = 5'h07 * 10'h011 = 12'h077
        @(posedge clk);
        rst_n = 1;
        if (dterm !== 12'h077) begin
            fail = 1;
            $display("(7) (expected, actual) :: dterm (12'h077, %h)", dterm);
        end

        // (8) check that vld successfully ENables the prev_err flop
        // for first clock cycle, set prev_err (repeating stim signal assignment here for better readability)
        actual = 16'h00AB;
        desired = 16'h009A;
        // err = 17'h00011, err_sat = 10'h011
        vld = 1; // explicitly assign here for sake of test
        @(posedge clk);
        vld = 0; // deassert valid so prev_err is not updated
        // prev_err = 10'h011
        actual = 16'hFFFF; // apply different stims for different err_sat
        desired = 16'h00AA;
        // err = 17'h1FF55, err_sat = 10'h355
        @(posedge clk);
        vld = 1; // set valid for later tests
        // check dterm, should be equal to (current value of err_sat - first prev_err) * const (=5'h07)
        // dterm = sat(10'h355 - 10'h011) * 5'h07 = =7'h40 * 5'h07 = -448 dec = 12'hE40
        if (dterm !== 12'hE40) begin
            fail = 1;
            $display("(8) (expected, actual) :: dterm (12'hE40, %h)", dterm);
        end

        /** TEST FORMAT for calculations and saturation (9-12)
         *  A) set up for first clock cycle to get prev_err to known value
         *  B) check calculation on second clock cycle
         */
        // (9) test positive, non-saturating dterm
        actual = 16'h01EF;
        desired = 16'h0000;
        @(posedge clk);
        // err_sat = 10'h1EF
        actual = 16'h0FFF;
        desired = 16'h0000;
        @(posedge clk);
        // prev_err = 10'h1EF, err_sat = 10'h1FF, D_diff = 10'h010
        if (dterm != 12'h070) begin
            fail = 1;
            $display("(9) (expected, actual) :: dterm(12'h070, %h)", dterm);
        end

        // (10) test positive, saturating dterm
        actual = 16'h7FFF;
        desired = 16'h7FFE;
        @(posedge clk);
        // err_sat = 10'h100
        actual = 16'h0101;
        desired = 16'h0001;
        @(posedge clk);
        // prev_err = 10'h001, err_sat = 10'h100, D_diff = 10'h0FF, dterm = 1F * 7 = 1B9
        if (dterm != 12'h1B9) begin
            fail = 1;
            $display("(10) (expected, actual) :: dterm(12'h1B9, %h)", dterm);
        end

        // (11) test negative, non-saturating dterm
        actual = 16'h00F0;
        desired = 16'h00E0;
        @(posedge clk);
        // err_sat = 10'h010
        actual = 16'h0111;
        desired = 16'h0111;
        @(posedge clk);
        // prev_err = 10'h010, err_sat = 10'h000, D_diff = 10'h3F0, dterm = 3F0 * 7 = 12h'F90
        if (dterm != 12'hF90) begin
            fail = 1;
            $display("(11) (expected, actual) :: dterm(12'hF90, %h)", dterm);
        end

        // (12) test negative, saturating dterm
        actual = 16'hFFFF;
        desired = 16'h0140;
        @(posedge clk);
        // err_sat = 10'hEBF
        actual = 16'h00F0;
        desired = 16'h0FF0;
        @(posedge clk);
        // prev_err = 10'h2BF, err_sat = 10'h200, D_diff = 10'h341, dterm = 40 * 7 = 12'hE40
        if (dterm != 12'hE40) begin
            fail = 1;
            $display("(12) (expected, actual) :: dterm(12'hE40, %h)", dterm);
        end
        /****************** END - DTERM ******************/

        if (fail) $display("TEST(S) FAILED.");
        else $display("TESTS PASSED.");
        $finish;
    end

    always #5 clk = ~clk;

endmodule