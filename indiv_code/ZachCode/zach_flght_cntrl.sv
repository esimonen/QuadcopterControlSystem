module flght_cntrl(clk,rst_n,vld,inertial_cal,d_ptch,d_roll,d_yaw,ptch,
					roll,yaw,thrst,frnt_spd,bck_spd,lft_spd,rght_spd);
				
input clk,rst_n;
input vld;									// tells when a new valid inertial reading ready
											// only update D_QUEUE on vld readings
input inertial_cal;							// need to run motors at CAL_SPEED during inertial calibration
input signed [15:0] d_ptch,d_roll,d_yaw;	// desired pitch roll and yaw (from cmd_cfg)
input signed [15:0] ptch,roll,yaw;			// actual pitch roll and yaw (from inertial interface)
input [8:0] thrst;							// thrust level from slider
output [10:0] frnt_spd;						// 11-bit unsigned speed at which to run front motor
output [10:0] bck_spd;						// 11-bit unsigned speed at which to back front motor
output [10:0] lft_spd;						// 11-bit unsigned speed at which to left front motor
output [10:0] rght_spd;						// 11-bit unsigned speed at which to right front motor


  //////////////////////////////////////////////////////
  // You will need a bunch of interal wires declared //
  // for intermediate math results...do that here   //
  ///////////////////////////////////////////////////
  wire [9:0] ptch_pterm, roll_pterm, yaw_pterm;
  wire [11:0] ptch_dterm, roll_dterm, yaw_dterm;
  logic [12:0] thrst_ext;
  logic [12:0] ptch_pterm_ext, roll_pterm_ext, yaw_pterm_ext;
  logic [12:0] ptch_dterm_ext, roll_dterm_ext, yaw_dterm_ext;
  logic [12:0] frnt_spd_ext, bck_spd_ext, lft_spd_ext, rght_spd_ext;
  logic [10:0] frnt_spd_sat, bck_spd_sat, lft_spd_sat, rght_spd_sat;

  ///////////////////////////////////////////////////////////////
  // some Parameters to keep things more generic and flexible //
  /////////////////////////////////////////////////////////////
  localparam CAL_SPEED = 11'h290;		// speed to run motors at during inertial calibration
  localparam MIN_RUN_SPEED = 13'h2C0;	// minimum speed while running  
  localparam D_COEFF = 5'b00111;		// D coefficient in PID control = +7
  
  //////////////////////////////////////
  // Instantiate 3 copies of PD_math //
  ////////////////////////////////////
  PD_math iPTCH(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_ptch),.actual(ptch),.pterm(ptch_pterm),.dterm(ptch_dterm));
  PD_math iROLL(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_roll),.actual(roll),.pterm(roll_pterm),.dterm(roll_dterm));
  PD_math iYAW(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_yaw),.actual(yaw),.pterm(yaw_pterm),.dterm(yaw_dterm));  
  
  // Sign extending to 13 bits
  assign thrst_ext = {{4{1'b0}},thrst};
  assign ptch_pterm_ext = {{3{ptch_pterm[9]}},ptch_pterm};
  assign ptch_dterm_ext = {{1{ptch_dterm[9]}},ptch_dterm};
  assign roll_pterm_ext = {{3{roll_pterm[9]}},roll_pterm};
  assign roll_dterm_ext = {{1{roll_dterm[9]}},roll_dterm};
  assign yaw_pterm_ext = {{3{yaw_pterm[9]}},yaw_pterm};
  assign yaw_dterm_ext = {{1{yaw_dterm[9]}},yaw_dterm};
  
  // assign speeds
  assign frnt_spd_ext = thrst_ext + MIN_RUN_SPEED - ptch_pterm_ext - ptch_dterm_ext - yaw_pterm_ext - yaw_dterm_ext;
  assign bck_spd_ext = thrst_ext + MIN_RUN_SPEED + ptch_pterm_ext + ptch_dterm_ext - yaw_pterm_ext - yaw_dterm_ext;
  assign lft_spd_ext = thrst_ext + MIN_RUN_SPEED - roll_pterm_ext - roll_dterm_ext + yaw_pterm_ext + yaw_dterm_ext;
  assign rght_spd_ext = thrst_ext + MIN_RUN_SPEED + roll_pterm_ext + roll_dterm_ext + yaw_pterm_ext + yaw_dterm_ext;
  
  // saturate speeds to 11 bits
  assign frnt_spd_sat = |frnt_spd_ext[12:11] ? 11'b11111111111 : frnt_spd_ext[10:0];
  assign bck_spd_sat = |bck_spd_ext[12:11] ? 11'b11111111111 : bck_spd_ext[10:0];
  assign lft_spd_sat = |lft_spd_ext[12:11] ? 11'b11111111111 : lft_spd_ext[10:0];
  assign rght_spd_sat = |rght_spd_ext[12:11] ? 11'b11111111111 : rght_spd_ext[10:0];
  
  // mux between saturated speeds and CAL_SPEED
  assign frnt_spd = inertial_cal ? CAL_SPEED : frnt_spd_sat;
  assign bck_spd = inertial_cal ? CAL_SPEED : bck_spd_sat;
  assign lft_spd = inertial_cal ? CAL_SPEED : lft_spd_sat;
  assign rght_spd = inertial_cal ? CAL_SPEED : rght_spd_sat;
  
endmodule 
