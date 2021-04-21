module flght_cntrl_chk_tb();

logic clk;
logic rst_n;
logic vld;				// updates to prev_err queue happen on new vld inertial reading
logic inertial_cal;		// controls final output mux
logic [15:0] d_ptch;	// desired pitch (from cmd_cfg)
logic [15:0] d_roll;	// desired roll (from cmd_cfg)
logic [15:0] d_yaw;		// desired yaw (from cmd_cfg)
logic [15:0] ptch;		// actual pitch ((from inertial interface)
logic [15:0]roll;		// actual roll (from inertial interface)
logic [15:0] yaw;		// actual yaw (from inertial interface)
logic [8:0] thrst;							// thrust level from slider
logic [10:0] frnt_spd;						// 11-bit unsigned speed at which to run front motor
logic [10:0] bck_spd;						// 11-bit unsigned speed at which to back front motor
logic [10:0] lft_spd;						// 11-bit unsigned speed at which to left front motor
logic [10:0] rght_spd;						// 11-bit unsigned speed at which to right front motor
logic [107:0] stim_array[0:1999];	// random test values from flght_cntrl_stim_nq.hex
logic [43:0] resp_array[0:1999];	// expected responses from flght_cntrl_resp_nq.hex
logic [107:0] stim;		// current test
logic [43:0] resp;		// expected result of current test

//instantiate DUT
flght_cntrl iDUT(.clk(clk), .rst_n(rst_n), .vld(vld), .inertial_cal(inertial_cal), .d_ptch(d_ptch), .d_roll(d_roll), .d_yaw(d_yaw), .ptch(ptch), .roll(roll), .yaw(yaw), .thrst(thrst), .frnt_spd(frnt_spd), .bck_spd(bck_spd), .lft_spd(lft_spd), .rght_spd(rght_spd));

initial begin
clk = 0;
//read in random tests and expected results of those tests
$readmemh("flght_cntrl_stim_nq.hex", stim_array);
$readmemh("flght_cntrl_resp_nq.hex", resp_array);

// loop to go through all tests
for(integer row = 0; row < 2000; row++) begin
	// assign current test and current response
	resp = resp_array[row];
	stim = stim_array[row];

	//apply stimulus
	rst_n = stim[107];
	vld = stim[106];
	inertial_cal = stim[105];
	d_ptch = stim[104:89];
	d_roll = stim[88:73];
	d_yaw = stim[72:57];
	ptch = stim[56:41];
	roll = stim[40:25];
	yaw = stim[24:9];
	thrst = stim[8:0];

	// wait until posedge clk then one more time unit before performing self check
	@(posedge clk) begin

		#1;

		if(frnt_spd !== resp[43:33]) begin
			$display("front speed wrong in test %d", row);
			$display("should be %d, was %d", resp[43:33], frnt_spd);
			$stop;
		end
		if(bck_spd !== resp[32:22]) begin
			$display("back speed wrong in test %d", row);
			$display("should be %d, was %d", resp[32:22], bck_spd);
			$stop;
		end
		if(lft_spd !== resp[21:11]) begin
			$display("left speed wrong in test %d", row);
			$display("should be %d, was %d", resp[21:11], lft_spd);
			$stop;
		end
		if(rght_spd !== resp[10:0]) begin
			$display("right speed wrong in test %d", row);
			$display("should be %d, was %d", resp[10:0], rght_spd);
			$stop;
		end
	end
end

$display("YAHOO all tests passed");
$stop;
end

always begin
#5 clk = ~clk;
end

endmodule
