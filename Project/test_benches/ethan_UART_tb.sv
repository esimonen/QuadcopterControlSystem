module ethan_UART_tb();
    //testing signals


    //wires
    wire [7:0] rx_data; // monitor wire for UART_rcv output
    wire           rdy, // monitor wire for UART_rcv ready signal
                    TX, // conection between UART_tx and UART_rcv
               tx_done; // wire to monitor when the transmission is complete,
                        // which isn't nessisarily important in oor usage

    //reg
    reg           clk, // clock
                rst_n, // asynch active low reset
                 trmt, // signal to start transmission from UART_tx
              clr_rdy; // signal to clear ready flop in UART_rcv
    reg [7:0] tx_data; // input data to UART_tx

    //int (testing purposes)
    int       timeout; // testing signal to count clocks before rdy is asserted

    //clock
    always #5 clk = ~clk;

    //iDUTs
    UART_rcv iRCV(
    .clk(clk),           //50 MHz clock signal
    .rst_n(rst_n),       //Active low reset
    .clr_rdy(clr_rdy),   //knocks down rdy when asserted
    .RX(TX),             //signal recieved by transmitter
    .rx_data(rx_data),   //Byte to recieve
    .rdy(rdy)            //Asserted when byte recieved.
                         //Stays high until start bit of next byte start, or until clr_rdy asserted.
    );

    UART_tx iTX(
    .clk(clk),           //50 MHz clock signal
    .rst_n(rst_n),       //Active low reset
    .trmt(trmt),         //Assrted for 1 clk cycle to initiate transmisson
    .tx_data(tx_data),   //Byte to transmit
    .TX(TX),             //Serial data output
    .tx_done(tx_done)    //Asserted when byte is done transmitting. Stays high until next byte is transmitted.
    );

    initial begin
        //initial values for our signals

        clk = 0;
        rst_n = 0;
        trmt = 0;
        clr_rdy = 1;
        @(negedge clk);
        rst_n = 1;
        clr_rdy = 0;

        /*
         * Test 1: Send all zeros
         *
         */
         //send transmission
         @(negedge clk);
         tx_data = 8'h00;
         trmt = 1;
         @(negedge clk);
         trmt = 0;

        //wait to recieve. 
        timeout = 0;
        while(!rdy) begin
            @(negedge clk);
            timeout += 1;
            if (timeout >= 40000) begin
                $display("Test 1: timeout, rdy not recieved after %d clock cycles",timeout);
                $fail();
            end
        end

        //check that recieved is what is expected
        if(rx_data !== tx_data) begin
            $display("Test 1: Sent 8'h00 over tx_data, expected to recieve it. Instead recieved %8b", rx_data);
            $fail();
        end

        // wait for previous transmission to finish. Due to rcv being
        // 1/2 a baud cycle ahead
        while(!tx_done) @(negedge clk);
        /*
         * Test 2: all ones
         *
         */

         //send transmission
         @(negedge clk);
         tx_data = 8'hFF;
         trmt = 1;
         clr_rdy = 1;
         @(negedge clk);
         trmt = 0;
         clr_rdy = 0;

        //wait to recieve.
        timeout = 0; 
        while(!rdy) begin
            @(negedge clk);
            timeout += 1;
            if (timeout >= 40000) begin
                $display("Test 2: timeout, rdy not recieved after %d clock cycles",timeout);
                $fail();
            end
        end

        //check that recieved is what is expected
        if(rx_data !== tx_data) begin
            $display("Test 2: Sent 8'hFF over tx_data, expected to recieve it. Instead recieved %8b", rx_data);
            $fail();
        end

        // wait for previous transmission to finish. Due to rcv being
        // 1/2 a baud cycle ahead
        while(!tx_done) @(negedge clk);
        /*
         * Test 3: 10101010
         *
         */
         //send transmission
         @(negedge clk);
         tx_data = 8'hAA;
         trmt = 1;
         clr_rdy = 1;
         @(negedge clk);
         trmt = 0;
         clr_rdy = 0;

        //wait to recieve. 
        timeout = 0;
        while(!rdy) begin
            @(negedge clk);
            timeout += 1;
            if (timeout >= 40000) begin
                $display("Test 3: timeout, rdy not recieved after %d clock cycles",timeout);
                $fail();
            end
        end

        //check that recieved is what is expected
        if(rx_data !== tx_data) begin
            $display("Test 3: Sent 8'hAA over tx_data, expected to recieve it. Instead recieved %8b", rx_data);
            $fail();
        end

        // wait for previous transmission to finish. Due to rcv being
        // 1/2 a baud cycle ahead
        while(!tx_done) @(negedge clk);       
        /*
         * Test 4: 10000001
         *
         */

         //send transmission
         repeat (3) @(negedge clk);
         tx_data = 8'h81;
         trmt = 1;
         clr_rdy = 1;
         @(negedge clk);
         trmt = 0;
         clr_rdy = 0;

        //wait to recieve. 
        timeout = 0;
        while(!rdy) begin
            @(negedge clk);
            timeout += 1;
            if (timeout >= 40000) begin
                $display("Test 4: timeout, rdy not recieved after %d clock cycles",timeout);
                $fail();
            end
        end

        //check that recieved is what is expected
        if(rx_data !== tx_data) begin
            $display("Test 4: Sent 8'h81 over tx_data, expected to recieve it. Instead recieved %8b", rx_data);
            $fail();
        end
        
        // wait for previous transmission to finish. Due to rcv being
        // 1/2 a baud cycle ahead
        while(!tx_done) @(negedge clk);       
        /*
         * Test 5: rst_n
         *
         */

        rst_n = 0;
        @(negedge clk);
        rst_n = 1;
        @(negedge clk);
        //check that rst_n is what is expected
        if(rdy !== 0) begin
            $display("Test 5 err, rst_n should reset rdy");
            $fail();
        end
        if(tx_done !== 0) begin
            $display("Test 5 err, rst_n should reset tx_done");
            $fail();
        end
        if(TX !== 1) begin
            $display("Test 5 err, rst_n should preset TX");
            $fail();
        end


        // Very Nice! All tests passed!
        $display("YAHOO! All tests passed!");
        $finish();
    end


endmodule