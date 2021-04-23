// Theo Hornung
// ece 551
// ex11
module theo_ESC_interface_tb();

    reg clk, rst_n, wrt;
    reg [10:0] speed;
    reg pwm;

    reg fail;
    integer i; // loop var for waiting on counter
    integer MIN_PWM_CLKS = 6250;

    ESC_interface iDUT(.clk(clk), .rst_n(rst_n), .wrt(wrt), .SPEED(speed), .PWM(pwm));

    initial begin
        // init input signals
        clk = 0;
        wrt = 0;
        speed = 11'h0;

        // (1) test reset, low wrt
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;
        @(posedge clk);
        if (pwm !== 0) begin
            fail = 1;
            $display("(1) PWM should have been zero after reset. Instead got %b", pwm);
        end

        // (2) test all zeroes, wrt high
        @(negedge clk);
        wrt = 1;
        @(posedge clk);
        wrt = 0;
        // pwm high for 6250 clks
        for (i = MIN_PWM_CLKS; i > 0; i--) begin
            @(posedge clk);
            if (pwm !== 1'b1) begin
                fail = 1;
                $display("(2-%0d) PWM should have been 1. Instead was %b", i, pwm);
            end
        end
        // pwm low after 6250 clks
        @(posedge clk);
        if (pwm !== 1'b0) begin
            fail = 1;
            $display("(2-end) PWM should have been 0. Instead was %b", pwm);
        end

        // (3) test max speed
        @(negedge clk);
        wrt = 1;
        speed = 11'h7FF; // max speed
        @(posedge clk);
        wrt = 0;
        // pwm high for 6250 + 2047*3 clks
        for (i = MIN_PWM_CLKS + 6141; i > 0; i--) begin
            @(posedge clk);
            if (pwm !== 1'b1) begin
                fail = 1;
                $display("(3-%0d) PWM should have been 1. Instead was %b", i, pwm);
            end
        end
        // pwm low after 6250 + 2047*3 clks
        @(posedge clk);
        if (pwm !== 1'b0) begin
            fail = 1;
            $display("(3-end) PWM should have been 0. Instead was %b", pwm);
        end
        // (4) test intermediate speed
        @(negedge clk);
        wrt = 1;
        speed = 11'h021; // some intermediate speed value = 33d
        @(posedge clk);
        wrt = 0;
        // pwm high for 6250 + 33*3 clks
        for (i = MIN_PWM_CLKS + 99; i > 0; i--) begin
            @(posedge clk);
            if (pwm !== 1'b1) begin
                fail = 1;
                $display("(4-%0d) PWM should have been 1. Instead was %b", i, pwm);
            end
        end
        // pwm low after 6250 + 2047*3 clks
        @(posedge clk);
        if (pwm !== 1'b0) begin
            fail = 1;
            $display("(4-end) PWM should have been 0. Instead was %b", pwm);
        end
        // (5) interrupt w/ assert wrt
        @(negedge clk);
        wrt = 1;
        speed = 11'h0; // min speed
        @(posedge clk);
        wrt = 0;
        // pwm high for 20 clks before interrupting w/ wrt
        for (i = 20; i >= 0; i--) begin
            @(posedge clk);
            if (pwm !== 1'b1) begin
                fail = 1;
                $display("(5.1-%0d) PWM should have been 1. Instead was %b", i, pwm);
            end
        end
        @(negedge clk);
        wrt = 1;
        // rewrite min speed
        @(posedge clk);
        wrt = 0;
        // pwm high for 6250 clks before interrupting w/ wrt
        for (i = MIN_PWM_CLKS; i > 0; i--) begin
            @(posedge clk);
            if (pwm !== 1'b1) begin
                fail = 1;
                $display("(5.2-%0d) PWM should have been 1. Instead was %b", i, pwm);
            end
        end
        // pwm low after 6250 more clks
        @(posedge clk);
        if (pwm !== 1'b0) begin
            fail = 1;
            $display("(5-end) PWM should have been 0. Instead was %b", pwm);
        end

        // (6) interrupt w/ assert rst_n
        @(negedge clk);
        wrt = 1;
        speed = 11'h0;
        @(posedge clk);
        wrt = 0;
        // pwm high for 10 clks before reseting
        for (i = 10; i >= 0; i--) begin
            @(posedge clk);
            if (pwm !== 1'b1) begin
                fail = 1;
                $display("(6-%0d) PWM should have been 1. Instead was %b", i, pwm);
            end
        end
        @(negedge clk);
        rst_n = 0;
        #1; // delay one time step to let reset happen and to show reset is async
        // pwm low after rst_n asserted
        if (pwm !== 1'b0) begin
            fail = 1;
            $display("(6-end.1) PWM should have been 0. Instead was %b", pwm);
        end
        @(posedge clk);
        rst_n = 1;
        @(negedge clk);
        // pwm stays low after rst_n asserted
        if (pwm !== 1'b0) begin
            fail = 1;
            $display("(6-end.2) PWM should have been 0. Instead was %b", pwm);
        end

        // (7) check that PWM=0 is held when wrt not asserted
        wrt = 0; // redundant, but setting for readability
        for (i = 100; i >= 0; i--) begin
            @(posedge clk);
            if (pwm !== 1'b0) begin
                fail = 1;
                $display("(7-%0d) PWM should have been 0. Instead was %b", i, pwm);
            end
        end

        if (fail) $display("TEST(S) FAILED.");
        else $display("TESTS PASSED.");
        $finish;
    end

    // make clk shorter than #5 to reduce sim time
    always #5 clk = ~clk;

endmodule
