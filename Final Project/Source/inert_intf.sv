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
    wire signed [15:0] ptch_rt,roll_rt,yaw_rt;	    // feeds inertial_integrator
    wire signed [15:0] ax,ay;						// accel data to inertial_integrator

    reg [7:0] ptch_rt_H, ptch_rt_L;
    reg [7:0] roll_rt_H, roll_rt_L;
    reg [7:0] yaw_rt_H, yaw_rt_L;
    reg [7:0] ax_H, ax_L;
    reg [7:0] ay_H, ay_L;

    reg INT_f1, INT_f2;   // single- and double-flopped values of INT for metastability
    reg [15:0] timer;     // used to let sensor perform it's own init process

    wire [15:0] inert_data;
    wire done;            // Done signal asserted when SPI has completed transmission
    reg [3:0] pointer;    // register that points to the current command being recieved
  
    //////////////////////////////////////
    // Outputs of SM are of type logic //
    ////////////////////////////////////
    wire C_P_L, C_P_H;    // capture pitch low, high
    wire C_R_L, C_R_H;    // capture roll low, high
    wire C_Y_L, C_Y_H;    // capture yaw low, high
    wire C_AX_L, C_AX_H;  // capture acceleration x direction low, high
    wire C_AY_L, C_AY_H;  // capture acceleration y direction low, high
    reg wrt;             // high to tell SPI_mnrch to send data to the sensor
    reg [15:0] cmd;      // data to send through the SPI_mnrch
    reg pointer_reset;   // asserted when reseting the register pointer

    
  
    ///////////////////////////////////////
    // Create enumerated type for state //
    /////////////////////////////////////
    typedef enum reg [2:0] {  INIT_INTERRUPT, INIT_ACCEL, INIT_GYRO, INIT_ROUNDING, 
                            READ /*R_pitchL, R_pitchH, R_rollL, R_rollH, R_yawL, R_yawH, R_axL, R_axH, R_ayL, R_ayH*/, IDLE } state_t;
    state_t next_state, state;
    
    // FSM state register
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            state <= INIT_INTERRUPT;
        end
        else begin
            state <= next_state;
        end
    end

    // FSM output logic and state transition logic
    always_comb begin
        next_state = state;
        // default comb outputs to prevent latches
        /*C_P_L = 0;
        C_P_H = 0;
        C_R_L = 0;
        C_R_H = 0;
        C_Y_L = 0;
        C_Y_H = 0;
        C_AX_L = 0;
        C_AX_H = 0;
        C_AY_L = 0;
        C_AY_H = 0;
        wrt = 0;*/
        vld = 0;
        cmd = 16'hxxxx;
        pointer_reset = 0;
        wrt = 0;

        // cmd in each state is { R/~W, ADDR, DATA } for the next state
        // this way, we are reading/writing the data in each state that 
        // corresponds to the name of the state
        case (state)
            // init sensor to enable interrupt on data ready
            INIT_INTERRUPT: begin
                cmd = 16'h0D02;
                if (&timer) begin
                    next_state = INIT_ACCEL;
                    wrt = 1;
                end
            end
            // init sensor to setup 416Hz accel data rate, +/- 2g accel range
            INIT_ACCEL: begin
                cmd = 16'h1062;
                if (done) begin
                    next_state = INIT_GYRO;
                    wrt = 1;
                end
            end
            // init sensor to setup 416Hz gyro data rate, +/- 125deg/sec range
            INIT_GYRO: begin
                cmd = 16'h1162;
                if(done) begin
                    next_state = INIT_ROUNDING;
                    wrt = 1;
                end
            end
            // init sensor to round accel and gyro data
            INIT_ROUNDING: begin
                cmd = 16'h1460;
                if(done) begin
                    next_state = IDLE;
                    wrt = 1;
                end
            end
            /*R_pitchL: begin
                cmd = 16'hA3xx;
                if (done) begin
                    next_state = R_pitchH;
                    C_P_L = 1;
                    wrt = 1;
                end
            end
            R_pitchH: begin
                cmd = 16'hA4xx;
                if (done) begin
                    next_state = R_rollL;
                    C_P_H = 1;
                    wrt = 1;
                end
            end    
            R_rollL: begin
                cmd = 16'hA5xx;
                if (done) begin
                    next_state = R_rollH;
                    C_R_L = 1;
                    wrt = 1;
                end
            end
            R_rollH: begin
                cmd = 16'hA6xx;
                if (done) begin
                    next_state = R_yawL;
                    C_R_H = 1;
                    wrt = 1;
                end
            end
            R_yawL: begin
                cmd = 16'hA7xx;
                if (done) begin
                    next_state = R_yawH;
                    C_Y_L = 1;
                    wrt = 1;
                end
            end
            R_yawH: begin
                cmd = 16'hA8xx;
                if (done) begin
                    next_state = R_axL;
                    C_Y_H = 1;
                    wrt = 1;
                end
            end
            R_axL: begin
                cmd = 16'hA9xx;
                if (done) begin
                    next_state = R_axH;
                    C_AX_L = 1;
                    wrt = 1;
                end
            end
            R_axH: begin
                cmd = 16'hAAxx;
                if (done) begin
                    next_state = R_ayL;
                    C_AX_H = 1;
                    wrt = 1;
                end
            end
            R_ayL: begin
                cmd = 16'hABxx;
                if (done) begin
                    next_state = R_ayH;
                    C_AY_L = 1;
                    wrt = 1;
                end
            end
            R_ayH: begin
                if (done) begin
                    next_state = IDLE;
                    C_AY_H = 1;
                    vld = 1;
                end
            end*/
            READ: begin
                cmd = {4'hA, pointer, 8'hxx};
                if (pointer == 4'hC) begin
                    next_state = IDLE;
                    vld = 1;
                end
                if (done) 
                    wrt = 1;
            end
            default: begin // IDLE state to wait in between new sensor readings
                if(INT_f2 && done) begin
                    next_state = READ;
                    pointer_reset = 1; //resetting the pointer to its initial value
                end
            end
        endcase
            
    end
    
    // POINTER LOGIC to reduce states while reading from registers
    // the command sent is A(2-B)xx, so we can concat 4'hA with a 4 bit wide vector,
    // and once pointer is B, we can transition to idle
    
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            pointer <= 4'h1;
        else if (pointer_reset)
            pointer <= 4'h1;
        else if (done && state == READ) begin
            pointer <= pointer + 1;
        end

    
    // we only capture into one register at a time
    // to make capture work with the pointer method for addressing registers
    // we use a 11 bit register, one bit for each capture signal, and 11th bit is non-read
    // Rotate left 
    reg [10:0] capture;
    // [0] capture pitch low
    // [1] capture pitch high
    // [2] capture roll low
    // [3] capture roll high
    // [4] capture yaw low
    // [5] capture yaw high
    // [6] capture acceleration x low
    // [7] capture acceleration x high
    // [8] capture acceleration y low
    // [9] capture acceleration y high
    // [10] dont capture anything, here so that we can
    //      keep this to a rotate, instead of a shift with reset
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            capture <= 11'h200;
        else if (done && wrt)
            capture <= { capture[9:0], capture[10] };

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
	assign C_P_L = capture[0]  && done;
    assign C_P_H = capture[1]  && done;
    assign C_R_L = capture[2]  && done;
    assign C_R_H = capture[3]  && done;
    assign C_Y_L = capture[4]  && done;
    assign C_Y_H = capture[5]  && done;
    assign C_AX_L = capture[6] && done;
    assign C_AX_H = capture[7] && done;
    assign C_AY_L = capture[8] && done;
    assign C_AY_H = capture[9] && done;
    // internal registers
     // pitch low
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            ptch_rt_L <= 8'h00;
        else if (C_P_L)
            ptch_rt_L <= inert_data[7:0];
    // pitch high
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            ptch_rt_H <= 8'h00;
        else if (C_P_H)
            ptch_rt_H <= inert_data[7:0];
    // roll low
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            roll_rt_L <= 8'h00;
        else if (C_R_L)
            roll_rt_L <= inert_data[7:0];
    // roll high
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            roll_rt_H <= 8'h00;
        else if (C_R_H)
            roll_rt_H <= inert_data[7:0];
    // yaw low
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            yaw_rt_L <= 8'h00;
        else if (C_Y_L)
            yaw_rt_L <= inert_data[7:0];
    // yaw high
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            yaw_rt_H <= 8'h00;
        else if (C_Y_H)
            yaw_rt_H <= inert_data[7:0];
    // ax low
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            ax_L <= 8'h00;
        else if (C_AX_L)
            ax_L <= inert_data[7:0];
    // ax high
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            ax_H <= 8'h00;
        else if (C_AX_H)
            ax_H <= inert_data[7:0];
    // ay low
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            ay_L <= 8'h00;
        else if (C_AY_L)
            ay_L <= inert_data[7:0];
    // ay high
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            ay_H <= 8'h00;
        else if (C_AY_H)
            ay_H <= inert_data[7:0];

    // 16 bit timer, used to waiting out sensor init
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            timer <= 16'h0000;
        else if (state == INIT_INTERRUPT)
            timer <= timer + 1;
    
    // double flop INT for metastability
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n) begin
            INT_f1 <= 1'b0;
            INT_f2 <= 1'b0;
        end
        else begin
            INT_f1 <= INT;
            INT_f2 <= INT_f1;
        end

    assign ptch_rt = { ptch_rt_H, ptch_rt_L };
    assign roll_rt = { roll_rt_H, roll_rt_L };
    assign yaw_rt = { yaw_rt_H, yaw_rt_L };
    assign ax = { ax_H, ax_L };
    assign ay = { ay_H, ax_L };

  
endmodule
	  