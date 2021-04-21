module ethan_SPI_mnrch_tb();

//Signals
    logic            clk;   // clk signal 50MHz
    logic          rst_n;   // active low rst
    logic            wrt;   // assert wrt to send cmd

    wire            SS_n;   // unasserted when cmd is being sent, else high
    wire            SCLK;   // 16x the period of cmd, also asserted when SS_n
    wire            MOSI;   // SPI protocol signal: data output
    wire            MISO;   // SPI protocol signal: data input
    logic [15:0] wt_data;   // Data to send to serf
    wire  [15:0] rd_data;   // Data recieved, only valid when done is asserted
    wire             INT;   // asserted when data is loaded into NEMO
    wire            done;   // asserted when transmission is complete
    int                i;   // timeout help integer, counts clock cycles
    int                j;   // loop var for golden tests
    int             adjj;   // adjusted j var to show what test iteration it is on
    reg [95:0]golden[0:63]; // golden test data

    //iDUTs
    
    SPI_mnrch iDUT(
        .clk(clk),  // 50MHz clock
        .rst_n(rst_n),  // Active low reset signal
        .wrt(wrt),  // A high for 1 clock period would initiate a SPI transaction
        .SS_n(SS_n),  // SPI protocol signal: low during an SPI transaction
        .SCLK(SCLK),  // SPI protocol signal: while SS_n is low, SCLK is 1/16th the freq of clk (3.125MHz)
        .MOSI(MOSI),  // SPI protocol signal: data output
        .MISO(MISO),  // SPI protocol signal: data input
        .wt_data(wt_data),  // Data to send to serf
        .done(done),  // Asserted when transmission is complete
        .rd_data(rd_data) // Data recieved, only valid when done is asserted
    );

    SPI_iNEMO1 nemo(
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MISO(MISO),
        .MOSI(MOSI),
        .INT(INT)
    );

    //clk signal
    always #5 clk = ~clk;

    initial begin
        //$readmemh("inert_data.hex",)
        //initial setup
        i = 0;
        wrt = 0;
        clk = 0;
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;

        repeat(10) @(negedge clk);
        /*
         * Test 1: WHO_AM_I? 
         *
         * wt_data = 16'h8FXX
         *
         * Expected:
         * rd_data = 16'hXX6A
         *
         */
        sendcmd(16'h8Fxx);

        while(!done) begin
            i = i + 1;
            if( i > 40000) begin
                $display("Test 1 timed out");
                $stop();
            end
            @(negedge clk);
        end
        expect_output(16'hxx6A, 1, 0);



        /*
         * Test 2: INT pin assert 
         *
         * wt_data = 16'0D02
         *
         * Expected:
         * INT == 1
         *
         */
        sendcmd(16'h0D02);
        wait_timeout(2);
        if(INT !== 1)begin
            $display("Test 2 failed, expected INT == 1 and recieved %h",INT);
            $stop();
        end

        /*
         * Test 3-67: 
         *
         * get data from NEMO
         * compares to golden results
         *
         */

        @(negedge clk);
        $readmemh("inert_data.hex",golden); //initialize golden results
        @(negedge clk)

        for(j = 0; j < 63; j++) begin

            //the test number should be 3 more than j, to align with prev tests
            adjj = j + 3;



            //pitchH test:
            sendcmd(16'hA3xx);
            wait_timeout(adjj);
            expect_output({8'hxx, golden[j][47:40]}, adjj, 2);

            //rollL test:
            sendcmd(16'hA4xx);
            wait_timeout(adjj);
            expect_output({8'hxx, golden[j][23:16]}, adjj, 3);

            //rollH test:
            sendcmd(16'hA5xx);
            wait_timeout(adjj);
            expect_output({8'hxx, golden[j][31:24]}, adjj, 4);

            //yawL test:
            sendcmd(16'hA6xx);
            wait_timeout(adjj);
            expect_output({8'hxx, golden[j][7:0]}, adjj, 5);

            //yawH test:
            sendcmd(16'hA7xx);
            wait_timeout(adjj);
            expect_output({8'hxx, golden[j][15:8]}, adjj, 6);

            //AXL test:
            sendcmd(16'hA8xx);
            wait_timeout(adjj);
            expect_output({8'hxx, golden[j][87:80]}, adjj, 7);

            //AXH test:
            sendcmd(16'hA9xx);
            wait_timeout(adjj);
            expect_output({8'hxx, golden[j][95:88]}, adjj, 8);

            //AYL test:
            sendcmd(16'hAAxx);
            wait_timeout(adjj);
            expect_output({8'hxx, golden[j][71:64]}, adjj, 9);

            //AYH test:
            sendcmd(16'hABxx);
            wait_timeout(adjj);
            expect_output({8'hxx, golden[j][79:72]}, adjj, 10);

            //pitchL test:
            sendcmd(16'hA2xx);
            wait_timeout(adjj);
            expect_output({8'hxx, golden[j][39:32]}, adjj, 1);

            //move to next reg location
            sendcmd(16'h0D02);
            wait_timeout(adjj);
        end

        $display("Yahoo! All tests passed!");
        $stop();
    end


    // sends a command to nemo
    task sendcmd;
        input [15:0] wt; //input command
        wt_data = wt;
        @(negedge clk); // send command
        wrt = 1;
        @(negedge clk);
        wrt = 0;

    endtask

    // error detection for if the DUT has broken and wont assert done or int
    task wait_timeout;
        input int test; // test #, for display purposes
        i = 0;
        while((!done) || (!INT)) begin //must wait for done and int
            i = i + 1;
            if( i > 40000) begin //40000 cycles is more than enough for a transmission
                $display("Test %2d timed out",test);
                $stop();
            end
            @(negedge clk);
        end
    endtask 

    // error detection for if we recieve the expected output
    task expect_output;
        input [15:0] expected; // expected output
        input int test; // test #
        input int test2; // test iteration for what data is requested, debug purposes

        if(rd_data[7:0] !== expected[7:0])begin
            $display("Test %2d requested: %2d failed, expected %2h and recieved %2h", test ,test2, expected[7:0], rd_data[7:0]);
            $stop();
        end 
    endtask       
endmodule

