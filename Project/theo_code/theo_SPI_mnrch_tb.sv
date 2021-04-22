// Theo Hornung
// ece 551
// ex17
module theo_SPI_mnrch_tb();

    logic clk;
    logic rst_n;

    // input data signals
    logic MISO;
    logic [15:0] wt_data;
    logic wrt;

    // dut outputs
    logic MOSI;
    logic SCLK;
    logic SS_n;
    logic [15:0] rd_data;
    logic done;

    // NEMO interrupt output signal
    logic interrupt;

    // one-way flag, indicates if all tests passed
    logic fail;

    SPI_mnrch iDUT(.clk(clk), .rst_n(rst_n), .wrt(wrt), .SCLK(SCLK), .SS_n(SS_n), .MOSI(MOSI), .MISO(MISO), .wt_data(wt_data), .done(done), .rd_data(rd_data));
    SPI_iNEMO1 iNEMO(.SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .INT(interrupt));

    initial begin
        fail = 0;

        // init signals
        clk = 0;
        rst_n = 1;
        MISO = 0;
        wt_data = 16'h0000;
        wrt = 0;

        // assert reset
        @(negedge clk)
        rst_n = 0;
        @(negedge clk)
        rst_n = 1;

        // Test Format:
        // (test #) <Test Description>
        /*******************************************************************************************************
            NOTE:   INTENTIONALLY USING != HERE INSTEAD OF !== B/C THE 2 MSBytes ARE DON'T CARES WHEN WE
                    ARE READING FROM THE NEMO
         ********************************************************************************************************/

        // (1) Read from NEMO's WHO_AM_I register @0x0F
        @(posedge clk);
        wrt = 1;
        wt_data = 16'h8Fxx; // 0x0F in MSB bc MSB shifted out first
        @(posedge clk);
        wrt = 0;
        // wait for finished transaction
        @(posedge done);
        // WHO_AM_I reg always holds 0x6A
        if (rd_data != 16'hxx6A) begin
            fail = 1;
            $display("(1) FAILED TO READ WHO_AM_I (0x0F) :: got %h instead of 16'hxx6A", rd_data);
        end

        repeat (100) @(posedge clk); // so we can check waveform for stability

        // (2) Configure NEMO.INT pin so that it asserts when new data is ready
        //     write 0x02 to register 0x0D
        @(posedge clk);
        wrt = 1;
        wt_data = 16'h0D02;
        @(posedge clk);
        wrt = 0;
        
        @(posedge done);
        // sig internal to NEMO module should go high
        if (iNEMO.NEMO_setup === 0) begin
            fail = 1;
            $display("(2) FAILED TO SET UP INTerrupt PIN, iNEMO.NEMO_setup was not high");
        end

        // NEMO's INTerrupt signal will eventually go high after writing 02 to addr 0D
        fork
            begin: timeout2
                repeat (100000) @(posedge clk);
                fail = 1;
                $display("(2) INT DID NOT GO HIGH IN TIME, WAITED 100000 clk CYCLES");
                disable timeout5;
            end
            begin
                @(posedge interrupt);
                disable timeout2;
            end
        join

        // (3) read high byte of roll rate from gyro
        @(posedge clk);
        wrt = 1;
        wt_data = 16'hA5xx;
        @(posedge clk);
        wrt = 0;

        @(posedge done)
        if (rd_data != 16'hxx7b) begin
            fail = 1;
            $display("(3) FAILED TO READ HIGH BYTE OF ROLL @00, instead got %h", rd_data);
        end

        // (4) read low byte of roll rate from gyro
        @(posedge clk);
        wrt = 1;
        wt_data = 16'hA4xx;
        @(posedge clk);
        wrt = 0;

        @(posedge done)
        if (rd_data != 16'hxx0d) begin
            fail = 1;
            $display("(4) FAILED TO READ LOW BYTE OF ROLL @00, instead got %h", rd_data);
        end

        // (5) read low byte of roll rate from gyro and wait for interrupt signal to reassert
        @(posedge clk);
        wrt = 1;
        wt_data = 16'hA2xx;
        @(posedge clk);
        wrt = 0;

        @(posedge done)
        if (rd_data != 16'hxx63) begin
            fail = 1;
            $display("(5) FAILED TO READ LOW BYTE OF PITCH @00, instead got %h", rd_data);
        end

        fork
            begin: timeout5
                repeat (100000) @(posedge clk);
                fail = 1;
                $display("(5) INT DID NOT GO HIGH IN TIME, WAITED 100000 clk CYCLES");
                disable timeout5;
            end
            begin
                @(posedge interrupt);
                disable timeout5;
            end
        join
        
        // (6) read low byte of acceleration rate in y direction
        @(posedge clk);
        wrt = 1;
        wt_data = 16'hAAxx;
        @(posedge clk);
        wrt = 0;

        @(posedge done)
        if (rd_data != 16'hxx12) begin
            fail = 1;
            $display("(6) FAILED TO READ LOW BYTE OF Y ACCELERATION @01, instead got %h", rd_data);
        end

        // (7) read high byte of yaw rate
        @(posedge clk);
        wrt = 1;
        wt_data = 16'hA7xx;
        @(posedge clk);
        wrt = 0;

        @(posedge done)
        if (rd_data != 16'hxxcd) begin
            fail = 1;
            $display("(7) FAILED TO READ LOW BYTE OF ROLL @01, instead got %h", rd_data);
        end

        // (8) read low byte of roll rate from gyro and wait for interrupt signal to reassert
        @(posedge clk);
        wrt = 1;
        wt_data = 16'hA2xx;
        @(posedge clk);
        wrt = 0;

        @(posedge done)
        if (rd_data != 16'hxx0D) begin
            fail = 1;
            $display("(8) FAILED TO READ LOW BYTE OF PITCH @01, instead got %h", rd_data);
        end

        fork
            begin: timeout8
                repeat (100000) @(posedge clk);
                fail = 1;
                $display("(8) INT DID NOT GO HIGH IN TIME, WAITED 100000 clk CYCLES");
                disable timeout5;
            end
            begin
                @(posedge interrupt);
                disable timeout8;
            end
        join
        
        // (9) read high byte of acceleration rate in x direction
        @(posedge clk);
        wrt = 1;
        wt_data = 16'hA9xx;
        @(posedge clk);
        wrt = 0;

        @(posedge done)
        if (rd_data != 16'hxx57) begin
            fail = 1;
            $display("(9) FAILED TO READ HIGH BYTE OF X ACCELERATION @02, instead got %h", rd_data);
        end


        if (fail) $display("TEST(S) FAILED.");
        else $display("TESTS PASSED.");
        $stop;


    end


    always #5 clk = ~clk;

endmodule
