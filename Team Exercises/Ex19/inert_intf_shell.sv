module inert_intf(clk,rst_n,ptch,roll,yaw,strt_cal,cal_done,vld,SS_n,SCLK,
                  MOSI,MISO,INT);
				  
  parameter FAST_SIM = 1;		// used to accelerate simulation
 
  input clk, rst_n;
  input MISO;					// SPI input from inertial sensor
  input INT;					// goes high when measurement ready
  input strt_cal;				// from comand config.  Indicates we should start calibration
  
  output signed [15:0] ptch,roll,yaw;	// fusion corrected angles
  output cal_done;						// indicates calibration is done
  output reg vld;						// goes high for 1 clock when new outputs available
  output SS_n,SCLK,MOSI;				// SPI outputs

  ////////////////////////////////////////////
  // Declare any needed internal registers //
  //////////////////////////////////////////
   << holding registers, timer, double flop of INT, ...>>
  
  //////////////////////////////////////
  // Outputs of SM are of type logic //
  ////////////////////////////////////
    << declare all the output signals of your SM >>


  //////////////////////////////////////////////////////////////
  // Declare any needed internal signals that connect blocks //
  ////////////////////////////////////////////////////////////
  wire signed [15:0] ptch_rt,roll_rt,yaw_rt;	// feeds inertial_integrator
  wire signed [15:0] ax,ay;						// accel data to inertial_integrator
  << might need a few more >>
  
  
  ///////////////////////////////////////
  // Create enumerated type for state //
  /////////////////////////////////////
  << declare your states and state register >>
  
  
  ////////////////////////////////////////////////////////////
  // Instantiate SPI monarch for Inertial Sensor interface //
  //////////////////////////////////////////////////////////
  SPI_mnrch iSPI(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI),
                 .wrt(wrt),.done(done),.rd_data(inert_data),.wt_data(cmd));
				  
  ////////////////////////////////////////////////////////////////////
  // Instantiate Angle Engine that takes in angular rate readings  //
  // and acceleration info and produces ptch,roll, & yaw readings //
  /////////////////////////////////////////////////////////////////
  inertial_integrator #(FAST_SIM) iINT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal), .cal_done(cal_done),
                                       .vld(vld), .ptch_rt(ptch_rt), .roll_rt(roll_rt), .yaw_rt(yaw_rt), .ax(ax),
						               .ay(ay), .ptch(ptch), .roll(roll), .yaw(yaw));
	

 << Rest is up to you >>
  
endmodule
	  