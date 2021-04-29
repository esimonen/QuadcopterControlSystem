/*
 * Team:            The Moorons
 * Course:          ECE551
 * Professor:       Eric Hoffman
 * Team Members:    Ethan Simonen, Scott Woolf, Zach Berglund, Theo Hornung
 * Date:            4/14/2021
 */

// send_packet
//
// Fun little task to send a packet of data to our quadcopter (DUT)
//
// Requires no values for an input, but does read values from the tb:
// send_cmd: 
// clk: clock singal 
// cmd_rdy:
// cal_done:
// resp_rdy:
task send_packet;//(ref send_cmd, ref clk, ref resp_rdy, ref [7:0] resp);
    //pass in 
    begin
        // set the command to be sent to cmd_cfg through RemoteComm
        @(posedge clk) send_cmd = 1'b1;
        @(posedge clk) send_cmd = 1'b0;

        // wait for the response to be ready at RemoteComm from the DUT
        fork
            begin: timeout_resp_rdy
                repeat (1000000) @(posedge clk);
                $error("Task 'send_packet' Failed: Waiting for response at RemoteComm to be ready");
                $stop;
            end
            begin
                @(posedge resp_rdy);
                disable timeout_resp_rdy;
            end
        join
        // response is now ready, expect 8'hA5 as our expected response for a normal output
        assert(resp === 8'hA5)
        else begin
            $error("Task 'send_packet' Failed: Received incorrect response. Received %h, but expected %h.", resp, 8'hA5);
            $stop;
        end
        $display("SENT PACKET");
    end

endtask

