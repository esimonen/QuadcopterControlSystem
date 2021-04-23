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
    real LOW_THRESHOLD = 0.9; // a coefficient that we use as part of the cutoff to check for our data
    real HIGH_THRESHOLD = 1.1; // a coefficient that we use as part of the cutoff to check for our data
    begin
        tempdata = data; //copy data so we can send another signal from RemoteComm and still let this task work correctly
        case (host_cmd)
            SET_PTCH : begin 
                fork
                    begin : timeout_ptch
                        repeat (3000000) @(posedge clk);
                        $error("Task 'check_cyclone_outputs' Failed: Waiting for pitch to near %0h", tempdata);
                        $stop;
                    end
                    begin
                        @(iDUT.ptch <= tempdata * HIGH_THRESHOLD  && iDUT.ptch >= tempdata * LOW_THRESHOLD); // we expect pitch to get above some threshold when we ask for a desired pitch
                        disable timeout_ptch;
                    end
                join
            end
            SET_ROLL : begin
                fork
                    begin : timeout_roll
                        repeat (3000000) @(posedge clk);
                        $error("Task 'check_cyclone_outputs' Failed: Waiting for roll to near %0h", tempdata);
                        $stop;
                    end
                    begin
                        @(iDUT.roll <= tempdata * HIGH_THRESHOLD  && iDUT.roll >= tempdata * LOW_THRESHOLD); // we expect roll to get above (or below) some threshold when we ask for a desired roll
                        disable timeout_roll;
                    end
                join
            end
            SET_YAW : begin

                fork
                    begin : timeout_yaw
                        repeat (3000000) @(posedge clk);
                        $error("Task 'check_cyclone_outputs' Failed: Waiting for yaw to near %0h", tempdata);
                        $stop;
                    end
                    begin
                        @(iDUT.yaw <= tempdata * HIGH_THRESHOLD  && iDUT.yaw >= tempdata * LOW_THRESHOLD); // we expect yaw to get above (or below) some threshold when we ask for a desired yaw
                        disable timeout_yaw;
                    end
                join

            end
            SET_THRST : begin
                // when we set the thrust, we would expect the thrust to increase over time
                // 

                fork
                    begin : timeout_thrst
                        repeat (3000000) @(posedge clk);
                        $error("Task 'check_cyclone_outputs' Failed: Waiting for thrust to near %0h", tempdata);
                        $stop;
                    end
                    begin
                        @(iDUT.thrust <= tempdata * HIGH_THRESHOLD  && iDUT.thrust >= tempdata * LOW_THRESHOLD); // we expect thrust to get above (or below) some threshold when we ask for a desired thrust
                        disable timeout_thrst;
                    end
                join

            end

            // don't need to check here, included for completeness
            CALIBRATE : begin
                // we do nothing!
            end

            // all values should be zero to stop quadcopter
            EMER_LAND : begin
                fork
                    begin : timeout_thrst_emer
                        repeat (3000000) @(posedge clk);
                        $error("Task 'check_cyclone_outputs' Failed: Waiting for thrust to near 0");
                        $stop;
                    end
                    begin
                        @(iDUT.thrust === 0); // we expect thrust to get towards 0
                        disable timeout_thrst_emer;
                    end
                    begin : timeout_roll_emer
                        repeat (3000000) @(posedge clk);
                        $error("Task 'check_cyclone_outputs' Failed: Waiting for roll to near 0");
                        $stop;
                    end
                    begin
                        @(iDUT.roll === 0); // we expect roll to get towards 0
                        disable timeout_roll_emer;
                    end
                    begin : timeout_yaw_emer
                        repeat (3000000) @(posedge clk);
                        $error("Task 'check_cyclone_outputs' Failed: Waiting for yaw to near 0");
                        $stop;
                    end
                    begin
                        @(iDUT.roll === 0); // we expect yaw to get towards 0
                        disable timeout_yaw_emer;
                    end
                    begin : timeout_ptch_emer
                        repeat (3000000) @(posedge clk);
                        $error("Task 'check_cyclone_outputs' Failed: Waiting for pitch to near 0");
                        $stop;
                    end
                    begin
                        @(iDUT.pitch === 0); // we expect pitch to get towards 0
                        disable timeout_ptch_emer;
                    end
                join

            end

            // the motors off signal should be one
            default : begin // MTRSOFF
                fork
                    begin : timeout_mtrsoff
                        repeat (3000000) @(posedge clk);
                        $error("Task 'check_cyclone_outputs' Failed: Waiting for thrust to near 0, as MTRSOFF has been called");
                        $stop;
                    end
                    begin
                        @(iDUT.thrust === 0); // we expect thrust to be 0 when we turn off the motors
                        disable timeout_mtrsoff;
                    end
                join
            end
        endcase
    
    end



endtask
