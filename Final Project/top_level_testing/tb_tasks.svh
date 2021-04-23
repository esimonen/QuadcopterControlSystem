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

task check_cyclone_outputs;

    // constants to make commands from uart more readable
    localparam SET_PTCH     = 8'h02;
    localparam SET_ROLL     = 8'h03;
    localparam SET_YAW      = 8'h04;
    localparam SET_THRST    = 8'h05;
    localparam CALIBRATE    = 8'h06;
    localparam EMER_LAND    = 8'h07;
    localparam MTRS_OFF     = 8'h08;
    reg tempdata [15:0]; // we have this register so we can get a snapshot of the data that is being sent, so we can compare
                         // the requested value to the value in the iDUT
    
    begin
        
        case (host_cmd)
            SET_PTCH : begin 
                assert(resp_out === 8'hA5)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_PTCH, expected response of 8'A5, instead recieved %2h", resp_out);
                    $stop();
                end
                assert(d_ptch === data2send)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_PTCH, expected response of %4h from data_in, instead recieved %4h", data2send, d_ptch);
                    $stop();
                end
            end
            SET_ROLL : begin
                assert(resp_out === 8'hA5)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_ROLL, expected response of 8'A5, instead recieved %2h", resp_out);
                    $stop();
                end
                assert(d_roll === data2send)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_ROLL, expected response of %4h from data_in, instead recieved %4h", data2send, d_roll);
                    $stop();
                end
            end
            SET_YAW : begin
                assert(resp_out === 8'hA5)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_YAW, expected response of 8'A5, instead recieved %2h", resp_out);
                    $stop();
                end
                assert(d_yaw === data2send)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_YAW, expected response of %4h from data_in, instead recieved %4h", data2send, d_yaw);
                    $stop();
                end
            end
            SET_THRST : begin
                // when we set the thrust, we would expect the thrust to increase over time
                // 
                fork
                    begin : 
                        
                    end
                    begin
                        @(iDUT.thrust >= ) // we expect thrust to get above some threshold when we ask for a desired thrust
                    end
                join


                /*assert(resp_out === 8'hA5) 
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_THRST, expected response of 8'A5, instead recieved %2h", resp_out);
                    $stop();
                end
                assert (thrst === data2send)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_THRST, expected response of %3h from data_in, instead recieved %3h", data2send[8:0], thrst);
                    $stop();
                end*/
            end
/*
            // don't need to check here, included for completeness
            CALIBRATE : begin
                // we do nothing!
            end

            // all values should be zero to stop quadcopter
            EMER_LAND : begin
                assert(d_ptch === 16'h0000)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Emergency land command sent: expected response of 16'h0000 for d_ptch, instead recieved %4h", d_ptch);
                    $stop();
                end
                assert(d_roll === 16'h0000)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Emergency land command sent: expected response of 16'h0000 for d_roll, instead recieved %4h", d_roll);
                    $stop();
                end
                assert(d_yaw === 16'h0000) 
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Emergency land command sent: expected response of 16'h0000 for d_yaw, instead recieved %4h", d_yaw);
                    $stop();
                end
                assert(thrst === 9'h000) 
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Emergency land command sent: expected response of 16'h0000 for thrst, instead recieved %3h", thrst);
                    $stop();
                end
                assert(resp_out === 8'hA5) 
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command EMER_LAND, expected response of 8'hA5, instead recieved %2h", resp);
                    $stop();
                end
            end

            // the motors off signal should be one
            MTRS_OFF : begin
                assert (motors_off === 1'b1) 
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Motors off, expected response of 1'b1, instead received %1h", motors_off);
                    $stop();
                end
            end
        */
        endcase
    
    end



endtask
