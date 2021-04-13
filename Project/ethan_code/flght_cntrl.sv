module flght_cntrl(clk,rst_n,vld,inertial_cal,d_ptch,d_roll,d_yaw,ptch,
					roll,yaw,thrst,frnt_spd,bck_spd,lft_spd,rght_spd);
				
input clk,rst_n;
input vld;									// tells when a new valid inertial reading ready
											// only update D_QUEUE on vld readings
input inertial_cal;							// need to run motors at CAL_SPEED during inertial calibration
input signed [15:0] d_ptch,d_roll,d_yaw;	// desired pitch roll and yaw (from cmd_cfg)
input signed [15:0] ptch,roll,yaw;			// actual pitch roll and yaw (from inertial interface)
input  [8:0]  thrst;							// thrust level from slider
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
  wire [12:0] ext_ptch_pterm, ext_roll_pterm, ext_yaw_pterm,
              ext_ptch_dterm, ext_roll_dterm, ext_yaw_dterm, ext_thrst ;
  wire[12:0] frnt_spd_us,bck_spd_us,lft_spd_us,rght_spd_us;
  wire[10:0] frnt_spd_s,bck_spd_s,lft_spd_s,rght_spd_s;
  ///////////////////////////////////////////////////////////////
  // some Parameters to keep things more generic and flexible //
  /////////////////////////////////////////////////////////////
  localparam CAL_SPEED = 11'h290;		// speed to run motors at during inertial calibration
  localparam MIN_RUN_SPEED = 13'h02C0;	// minimum speed while running  
  localparam D_COEFF = 5'b00111;		// D coefficient in PID control = +7
  
  //////////////////////////////////////
  // Instantiate 3 copies of PD_math //
  ////////////////////////////////////
  PD_math iPTCH(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_ptch),.actual(ptch),.pterm(ptch_pterm),.dterm(ptch_dterm));
  PD_math iROLL(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_roll),.actual(roll),.pterm(roll_pterm),.dterm(roll_dterm));
  PD_math iYAW(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_yaw),.actual(yaw),.pterm(yaw_pterm),.dterm(yaw_dterm));  
  
  //Sign extend pterm and dterm of pitch, roll, and yaw to 13 bits:
  assign ext_ptch_pterm = {{3{ptch_pterm[9]}},ptch_pterm};
  assign ext_roll_pterm = {{3{roll_pterm[9]}},roll_pterm};
  assign ext_yaw_pterm = {{3{yaw_pterm[9]}},yaw_pterm};
  assign ext_thrst = {4'h0, thrst};

  assign ext_ptch_dterm = {ptch_dterm[11], ptch_dterm};
  assign ext_roll_dterm = {roll_dterm[11], roll_dterm};
  assign ext_yaw_dterm  = {yaw_dterm[11],  yaw_dterm};

  //unsaturated logic
  assign frnt_spd_us = (ext_thrst + MIN_RUN_SPEED - ext_ptch_pterm - ext_ptch_dterm - ext_yaw_pterm - ext_yaw_dterm);
  assign bck_spd_us  = (ext_thrst + MIN_RUN_SPEED + ext_ptch_pterm + ext_ptch_dterm - ext_yaw_pterm - ext_yaw_dterm);
  assign lft_spd_us  = (ext_thrst + MIN_RUN_SPEED - ext_roll_dterm - ext_roll_pterm + ext_yaw_pterm + ext_yaw_dterm); 
  assign rght_spd_us = (ext_thrst + MIN_RUN_SPEED + ext_roll_dterm + ext_roll_pterm + ext_yaw_pterm + ext_yaw_dterm);
  //saturation logic (unsigned)
  assign frnt_spd_s = (|frnt_spd_us[12:11]) ? 11'h7FF : frnt_spd_us[10:0];
  assign bck_spd_s  = (|bck_spd_us[12:11] ) ? 11'h7FF : bck_spd_us[10:0];
  assign lft_spd_s  = (|lft_spd_us[12:11] ) ? 11'h7FF : lft_spd_us[10:0];
  assign rght_spd_s = (|rght_spd_us[12:11]) ? 11'h7FF : rght_spd_us[10:0];
  //Summation logic for motor speed muxed with inertial calibration
  assign frnt_spd = inertial_cal ? CAL_SPEED : frnt_spd_s;
  assign bck_spd  = inertial_cal ? CAL_SPEED : bck_spd_s;
  assign lft_spd  = inertial_cal ? CAL_SPEED : lft_spd_s;
  assign rght_spd = inertial_cal ? CAL_SPEED : rght_spd_s;
  
endmodule 
