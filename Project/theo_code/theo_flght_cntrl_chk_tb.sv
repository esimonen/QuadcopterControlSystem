// Theo Hornung
// ece 551
// ex16
module theo_flight_control_check_tb();

    reg [107:0] stim [0:1999];
    reg [43:0] resp [0:1999];

    // stim signals
    logic clk;
    logic rst_n;                    // stim[107]
    logic vld;                      // stim[106]
    logic inertial_cal;             // stim[105]
    logic [15:0] d_ptch;            // stim[104:89]
    logic [15:0] d_roll;            // stim[88:73]
    logic [15:0] d_yaw;             // stim[72:57]
    logic [15:0] ptch;              // stim[56:41]
    logic [15:0] roll;              // stim[40:25]
    logic [15:0] yaw;               // stim[24:9]
    logic [8:0] thrust;             // stim[8:0]

    // resp signals
    logic [10:0] front_speed;       // resp[43:33]
    logic [10:0] back_speed;        // resp[32:22]
    logic [10:0] left_speed;        // resp[21:11]
    logic [10:0] right_speed;       // resp[10:0]

    logic fail;

    flght_cntrl iDUT(.clk(clk), .rst_n(rst_n), .vld(vld), .inertial_cal(inertial_cal), .d_ptch(d_ptch), .d_roll(d_roll), .d_yaw(d_yaw),
                        .ptch(ptch), .roll(roll), .yaw(yaw), .thrst(thrust), .frnt_spd(front_speed), .bck_spd(back_speed),
                        .lft_spd(left_speed), .rght_spd(right_speed));

initial begin
    clk = 0;
    fail = 0;
    // read random vectors into simulated memory
    $readmemh("flght_cntrl_stim_nq.hex", stim);
    $readmemh("flght_cntrl_resp_nq.hex", resp);

    for (int i = 0; i < 2000; i = i + 1) begin
        // assign stim inputs
        rst_n =         stim[i][107];
        vld =           stim[i][106];
        inertial_cal =  stim[i][105];
        d_ptch =        stim[i][104:89];
        d_roll =        stim[i][88:73];
        d_yaw =         stim[i][72:57];
        ptch =          stim[i][56:41];
        roll =          stim[i][40:25];
        yaw =           stim[i][24:9];
        thrust =        stim[i][8:0];
        @(posedge clk);
        #1;
        // now check outputs
        if (front_speed !== resp[i][43:33]) begin
            $display("i=%d :: front_speed should be %h, instead got %h", i, resp[i][43:33], front_speed);
            fail = 1;
        end
        if (back_speed !== resp[i][32:22]) begin
            $display("i=%d :: back_speed should be %h, instead got %h", i, resp[i][32:22], back_speed);
            fail = 1;
        end
        if (left_speed !== resp[i][21:11]) begin
            $display("i=%d :: left_speed should be %h, instead got %h", i, resp[i][21:11], left_speed);
            fail = 1;
        end
        if (right_speed !== resp[i][10:0]) begin
            $display("i=%d :: right_speed should be %h, instead got %h", i, resp[i][10:0], right_speed);
            fail = 1;
        end
    end
    if (fail) $display("TEST(S) FAILED");
    else $display("ALL TESTS PASSED");
    $stop;
end

always #5 clk = ~clk;

endmodule