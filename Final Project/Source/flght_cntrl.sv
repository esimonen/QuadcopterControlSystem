// Theo Hornung
// ece 551

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

  // sign extended inputs to motor speed calculations
  wire [12:0] thrust_13b;
  wire [12:0] ptch_pterm_13b, roll_pterm_13b, yaw_pterm_13b;
  wire [12:0] ptch_dterm_13b, roll_dterm_13b, yaw_dterm_13b;

  // hold 13 bit summations before outputting saturated speed values
  wire [12:0] front_speed_temp, back_speed_temp, right_speed_temp, left_speed_temp;

  // flops to pipeline *_speed_temp values
  reg [12:0] pipe_fs, pipe_bs, pipe_rs, pipe_ls;

  // flops to pipeline intermediate in the large additions to make the *_speed_temp
  reg [12:0] ptch_ff,roll_ff,yaw_ff, thrst_ff;
  ///////////////////////////////////////////////////////////////
  // some Parameters to keep things more generic and flexible //
  /////////////////////////////////////////////////////////////
  localparam CAL_SPEED = 11'h290;		// speed to run motors at during inertial calibration
  localparam MIN_RUN_SPEED = 13'h2C0;	// minimum speed while running  
  localparam D_COEFF = 5'b00111;		// D coefficient in PID control = +7
  
  // pipeline *_speed_temp values
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
	    pipe_fs <= 0;
	    pipe_bs <= 0;
	    pipe_rs <= 0;
	    pipe_ls <= 0;
    end
    else begin
	    pipe_fs <= front_speed_temp;
	    pipe_bs <= back_speed_temp;
	    pipe_rs <= right_speed_temp;
	    pipe_ls <= left_speed_temp;
    end
  end


  always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
      ptch_ff <=0;
      roll_ff <= 0;
      yaw_ff <= 0;
      thrst_ff <= 0;       
    end else begin
      ptch_ff <= ptch_pterm_13b + ptch_dterm_13b;
      roll_ff <= roll_dterm_13b + roll_pterm_13b;
      yaw_ff <= yaw_pterm_13b + yaw_dterm_13b;
      thrst_ff <= thrust_13b + MIN_RUN_SPEED;   
    end
  end


  //////////////////////////////////////
  // Instantiate 3 copies of PD_math //
  ////////////////////////////////////
  PD_math iPTCH(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_ptch),.actual(ptch),.pterm(ptch_pterm),.dterm(ptch_dterm));
  PD_math iROLL(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_roll),.actual(roll),.pterm(roll_pterm),.dterm(roll_dterm));
  PD_math iYAW(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_yaw),.actual(yaw),.pterm(yaw_pterm),.dterm(yaw_dterm));

  // sign extend all inputs to 13 bits to prevent overflow during speed calculation
  assign thrust_13b     = {4'h0, thrst[8:0]}; // but keep thrust zero-extended, is unsigned number {4{thrst[8]}}
  assign ptch_pterm_13b = {{3{ptch_pterm[9]}},  ptch_pterm[9:0]};
  assign ptch_dterm_13b = {{1{ptch_dterm[11]}}, ptch_dterm[11:0]};
  assign roll_pterm_13b = {{3{roll_pterm[9]}},  roll_pterm[9:0]};
  assign roll_dterm_13b = {{1{roll_dterm[11]}}, roll_dterm[11:0]};
  assign yaw_pterm_13b  = {{3{yaw_pterm[9]}},   yaw_pterm[9:0]};
  assign yaw_dterm_13b  = {{1{yaw_dterm[11]}},  yaw_dterm[11:0]};
  
  // speed outputs should help to stabilize the quadcopter and bring it to stable equilibrium
  // so, add terms that dec, sub terms that inc

  // faster front motor --> inc pitch, inc yaw
  assign front_speed_temp = thrst_ff - ptch_ff - yaw_ff; 
  
  // faster back motor --> dec pitch, inc yaw
  assign back_speed_temp = thrst_ff + ptch_ff - yaw_ff;
  
  // faster left motor --> inc roll, dec yaw
  assign left_speed_temp = thrst_ff - roll_ff + yaw_ff;
  
  // faster right motor --> dec roll, dec yaw
  assign right_speed_temp = thrst_ff + roll_ff + yaw_ff;
  
  // infer muxes and perform unsigned saturate
  assign frnt_spd = inertial_cal ?              CAL_SPEED :
                    |pipe_fs[12:11] ?  11'h7FF   :
                                                pipe_fs[10:0];

  assign bck_spd =  inertial_cal ?              CAL_SPEED :
                    |pipe_bs[12:11]  ?  11'h7FF   :
                                                pipe_bs[10:0];

  assign lft_spd =  inertial_cal ?              CAL_SPEED :
                    |pipe_ls[12:11]  ?  11'h7FF   :
                                                pipe_ls[10:0];

  assign rght_spd = inertial_cal ?              CAL_SPEED :
                    |pipe_rs[12:11] ?  11'h7FF   :
                                                pipe_rs[10:0];
  
endmodule 
