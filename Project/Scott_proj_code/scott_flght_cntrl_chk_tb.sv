module scott_flght_cntrl_chk_tb();

	reg [107:0] stimMem [1999:0]; // stimulus memory bank
	reg [43:0] respMem [1999:0]; // response reference memory bank
	reg [107:0] stim; // stimulus to apply to DUT
	reg clk; // 50MHz clock
	reg error; // self checking error term
	
	// DUT input signals
	reg rst_n, vld, inertial_cal; 
	reg [15:0] d_ptch, d_roll, d_yaw, ptch, roll, yaw;
	reg [8:0] thrst;
	
	// DUT output signals
	reg [10:0] frnt_spd, bck_spd, lft_spd, rght_spd;
	
	// reference output signals
	reg [10:0] frnt_spd_resp;
	reg [10:0] bck_spd_resp;
	reg [10:0] lft_spd_resp;
	reg [10:0] rght_spd_resp;
	
	// instantiate dut
	flght_cntrl iDUT(.clk(clk),.rst_n(rst_n),.vld(vld),.inertial_cal(inertial_cal),.d_ptch(d_ptch),.d_roll(d_roll),.d_yaw(d_yaw),.ptch(ptch),
					.roll(roll),.yaw(yaw),.thrst(thrst),.frnt_spd(frnt_spd),.bck_spd(bck_spd),.lft_spd(lft_spd),.rght_spd(rght_spd));
	
	initial begin
		// read in stimulus and reference - new queue files used for part II
		$readmemh("flght_cntrl_stim_nq.hex",stimMem);
		$readmemh("flght_cntrl_resp_nq.hex",respMem);
		
		// do not use queue files for part I
		// $readmemh("flght_cntrl_stim.hex",stimMem);
		// $readmemh("flght_cntrl_resp.hex",respMem);
		
		error = 0; // innocent until proven guilty
		clk = 0; // clock starts at 0
		
		// loop through each entry in the stim memory and apply it to the DUT, ensuring output matches resp
		for(int i = 0; i < 2000; i++) begin
			// get the ith stim vector from memory
			stim = stimMem[i][107:0];
			// apply all signals to the dut
			rst_n = stim[107];
			vld = stim[106];
			inertial_cal = stim[105];
			d_ptch = stim[104:89];
			d_roll = stim[88:73];
			d_yaw = stim[72:57];
			ptch = stim [56:41];
			roll = stim[40:25];
			yaw = stim[24:9];
			thrst = stim[8:0];
			
			// get reference signals from memory
			frnt_spd_resp = respMem[i][43:33];
			bck_spd_resp = respMem[i][32:22];
			lft_spd_resp = respMem[i][21:11];
			rght_spd_resp = respMem[i][10:0];
			
			// wait for posedge of clock + 1 time unit to ensure correct response
			@(posedge clk) begin
				#1 if(frnt_spd_resp !== frnt_spd || bck_spd_resp !== bck_spd || lft_spd_resp !== lft_spd || rght_spd_resp !== rght_spd) begin
					error = 1;
					$display("Expected Front Speed: %h, Recieved Front Speed: %h", frnt_spd_resp, frnt_spd);
					$display("Expected Back Speed: %h, Recieved Back Speed: %h", bck_spd_resp, bck_spd);
					$display("Expected Left Speed: %h, Recieved Left Speed: %h", lft_spd_resp, lft_spd);
					$display("Expected Right Speed: %h, Recieved Right Speed: %h", rght_spd_resp, rght_spd);
					$stop;
				end
			end
		end
		
	// display happy message if all tests pass
	if (!error)
			$display("YAHOO!! test passed");
	$stop;
	end

	always
		#5 clk = ~clk;
endmodule

