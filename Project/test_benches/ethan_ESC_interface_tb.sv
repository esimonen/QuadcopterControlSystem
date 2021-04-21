module ethan_ESC_interface_tb();

    //signals for testbench

    reg clk,            //50MHz clock
    rst_n,              //Active low asynch reset
    wrt;                //Initiates new pulse. Synched with PD control loop
    reg [10:0] SPEED;   //Result from flight controller telling how fast to run each motor. 
    wire PWM;           //Output to the ESC to control motor speed. It is effectively a PWM signal.

    //clock

    always #5 clk = ~ clk;

    //iDUT

    ESC_interface iDUT(.clk(clk) , .rst_n(rst_n) , .wrt(wrt) , .SPEED(SPEED) , .PWM(PWM));

    //Testbench

    initial begin
        clk = 0;
        rst_n = 0;
        wrt = 0;
        SPEED = 10'd0;

        @(negedge clk);

        rst_n = 1;

        @(negedge clk);

        /*
            Test 1:

            No added speed, baseline

        */

        //Sending the shot
        @ (negedge clk);
        wrt = 1;
        @ (negedge clk);
        wrt = 0;

        //making sure PWM is asserted
        repeat(6250) begin
            @ (negedge clk);
            if (!PWM) begin
                $display("Test 1 Failed at time %d PWM should have been asserted",$time);
                $fatal();
            end
        end

        @ (negedge clk);
        if (PWM) begin
            $display("Test 1 Failed at time %d PWM should have not been asserted",$time);
            $fatal();
        end
        $display("Test 1 Passed!            Baseline");



        /*
            Test 2:

            Fully Saturated Speed

        */
        //Asserting SPEED
        SPEED = 11'h7FF; //speed of 2047 should result in 2047*3+6250=12391 clock cycles

        //Sending the shot
        @ (negedge clk);
        wrt = 1;
        @ (negedge clk);
        wrt = 0;

        //making sure PWM is asserted
        repeat(12391) begin
            @ (negedge clk);
            if (!PWM) begin
                $display("Test 2 Failed at time %d PWM should have been asserted",$time);
                $fatal();
            end
        end

        @ (negedge clk);
        if (PWM) begin
            $display("Test 2 Failed at time %d PWM should have not been asserted",$time);
            $fatal();
        end
        $display("Test 2 Passed!            Maximum Speed");

        /*
            Test 3:

            Fully Generic Speed

        */
        //Asserting SPEED
        SPEED = 11'd1024; //speed of 1024 should result in 1024*3+6250=9322 clock cycles

        //Sending the shot
        @ (negedge clk);
        wrt = 1;
        @ (negedge clk);
        wrt = 0;

        //making sure PWM is asserted
        repeat(9322) begin
            @ (negedge clk);
            if (!PWM) begin
                $display("Test 3 Failed at time %d PWM should have been asserted",$time);
                $fatal();
            end
        end

        @ (negedge clk);
        if (PWM) begin
            $display("Test 3 Failed at time %d PWM should have not been asserted",$time);
            $fatal();
        end
        $display("Test 3 Passed!            Generic Speed");

        /*
            Test 4:

            Reset during opperation

        */
        //Asserting SPEED
        SPEED = 11'd1024; //speed of 1024 should result in 1024*3+6250=9322 clock cycles

        //Sending the shot
        @ (negedge clk);
        wrt = 1;
        @ (negedge clk);
        wrt = 0;

        //making sure PWM is asserted
        repeat(3000) begin
            @ (negedge clk);
            if (!PWM) begin
                $display("Test 4 Failed at time %d PWM should have been asserted",$time);
                $fatal();
            end
        end

        //reset should clear PWM
        @(negedge clk);
        rst_n = 0;
        @ (negedge clk);
        rst_n = 1;

        if (PWM) begin
            $display("Test 4 Failed at time %d PWM should have not been asserted",$time);
            $fatal();
        end
        $display("Test 4 Passed!            Reset During Opperation");

        $display("YAHOO! All Tests Passed!");
        $finish();
    end


endmodule