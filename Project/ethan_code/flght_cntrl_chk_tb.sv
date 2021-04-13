module flght_cntrl_chk_tb();
    
    reg [107:0] stim [1999:0];  //stimulus for pdmath
    reg [43:0]  resp [1999:0];  //the expected responses for pdmath
    wire [10:0] frnt_spd;	    // 11-bit unsigned speed at which to run front motor
    wire [10:0] bck_spd;	    // 11-bit unsigned speed at which to back front motor
    wire [10:0] lft_spd;		// 11-bit unsigned speed at which to left front motor
    wire [10:0] rght_spd;		// 11-bit unsigned speed at which to right front motor
    int i;
    reg clk;
    reg rst_n;
    reg [10:0] efs, ebs, els, ers;

    //DUT signals have been explained in Ex16
    flght_cntrl iDUT(.clk(clk),.rst_n(stim[i][107]),.vld(stim[i][106]),.inertial_cal(stim[i][105]),
                     .d_ptch(stim[i][104:89]),.d_roll(stim[i][88:73]),.d_yaw(stim[i][72:57]),.ptch(stim[i][56:41]),
					 .roll(stim[i][40:25]),.yaw(stim[i][24:9]),.thrst(stim[i][8:0]),.frnt_spd(frnt_spd),
                     .bck_spd(bck_spd),.lft_spd(lft_spd),.rght_spd(rght_spd));

    //clock signal
    always #5 clk = ~clk;

    //naming signals for easier signal tracing
    always_comb begin
        efs   = resp[i][43:33];
        ebs   = resp[i][32:22];
        els   = resp[i][21:11];
        ers   = resp[i][10:0];
        rst_n = stim[i][107];
    end


    initial begin

        clk = 0;

        $readmemh("flght_cntrl_resp_nq.hex",resp);
        $readmemh("flght_cntrl_stim_nq.hex",stim);


        for(i = 0; i < 2000; i++) begin
            @(posedge clk);
            #1;
            if(resp[i][43:33] !== frnt_spd) begin
                $display("Time %4d: front speed was off, expected %3h, recieved %3h",i,resp[i][43:33],frnt_spd);
                $stop();
            end
            if(resp[i][32:22] !== bck_spd ) begin
                $display("Time %4d: back speed was off, expected %3h, recieved %3h",i,resp[i][32:22],bck_spd);
                $stop();
            end
            if(resp[i][21:11] !== lft_spd ) begin
                $display("Time %4d: left speed was off, expected %3h, recieved %3h",i,resp[i][21:11],lft_spd);
                $stop();
            end
            if(resp[i][10:0]  !== rght_spd) begin
                $display("Time %4d: right speed was off, expected %3h, recieved %3h",i,resp[i][10:0],rght_spd);
                $stop();
            end

        end
        $display("YAHOO! All tests passed!");
        $stop();
    end



endmodule