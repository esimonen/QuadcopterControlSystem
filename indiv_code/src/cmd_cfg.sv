/*
 * Team:            The Moorons
 * Course:          ECE551
 * Professor:       Eric Hoffman
 * Team Members:    Ethan Simonen, Scott Woolf, Zach Berglund, Theo Hornung
 * Date:            4/12/2021
 */

module cmd_cfg(
    input      clk,             // Clock signal
    input      rst_n,           // Asynch active low reset
    input      cmd_rdy,         // New command valid from UART_wrapper
    input      [7:0] cmd,       // Command opcode
    input      [15:0] data,     // the data read from the UART_comm   
    output reg clr_cmd_rdy,     // asserted when we want to clear the command ready signal from UART
    output reg [7:0] resp,      // the response that is being sent to the UART_Comm
    output reg send_resp,       // asserted when sending the response
    output reg [15:0] d_roll,   // Holding register for desired roll
    output reg [15:0]  d_yaw,   // Holding register for desired yaw
    output reg [15:0] d_ptch,   // Holding register for desired pitch
    output reg [8:0]  thrst,    // Holding register for thrust
    output reg strt_cal,        // Asserted when we want to start the calabration from the inertial integrator
    output reg inertial_cal,    // Held high during duration of calibration
    input      cal_done,        // indicates the calibration is complete
    output reg motors_off       // goes to ESC, shuts off motors.
    );

    // 1 to reduce register sizes that will make simulation run faster
    parameter FAST_SIM = 1;

    // constants to make commands from uart more readable
    localparam SET_PTCH     = 8'h02;
    localparam SET_ROLL     = 8'h03;
    localparam SET_YAW      = 8'h04;
    localparam SET_THRST    = 8'h05;
    localparam CALIBRATE    = 8'h06;
    localparam EMER_LAND    = 8'h07;
    localparam MTRS_OFF     = 8'h08;

    // Signals
    reg wpitch, wroll, wyaw, wthrust;           // write to desired pitch, roll, yaw, thrust registers
    reg clr_motors;                             // high to assert motors_off sig thru SR flop
    reg emergency_land;                         // high when we want to emergency land
    wire timer_full;                            // high when done waiting for motors to ramp up to calibration speed
    reg clr_tmr;
    reg [(8*FAST_SIM + 25*!FAST_SIM):0] timer;  // 9 or 26 bit timer depending on FAST_SIM
    reg strt_cal_comb;                          // feeds into flop that outputs strt_cal, flop used to prevent output from glitching

    // State Machine
    typedef enum reg [1:0] {IDLE, RAMP_MOTORS, CAL} state_t;
    state_t state;
    state_t next_state;

    // state registers
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    
    // state machine output and transition logic
    always_comb begin
        next_state = state;
        // default comb outputs to prevent latches
        clr_tmr = 1'b1;
        send_resp = 1'b0;
        clr_cmd_rdy = 1'b0;
        resp = 8'hxx;
        clr_motors = 1'b0;
        strt_cal_comb = 1'b0;
        emergency_land = 1'b0;
        wpitch = 1'b0;
        wroll = 1'b0;
        wyaw = 1'b0;
        wthrust = 1'b0;
        inertial_cal = 1'b0;
        case (state)
            // state to get motors up to speed while calibrating
            RAMP_MOTORS: begin
                clr_tmr = 0;
                if (timer_full) begin
                    strt_cal_comb = 1;
                    next_state = CAL;
                end
                inertial_cal = 1'b1;
            end
            // state to wait for calibration
            CAL: begin
                if (cal_done) begin
                    resp = 8'hA5;
                    send_resp = 1'b1;
                    next_state = IDLE;
                end
                inertial_cal = 1'b1;
            end
            // IDLE handles reading all cmds and and responding
            default: begin // IDLE
                if (cmd_rdy) begin
                    case (cmd)
                        MTRS_OFF: begin
                            clr_motors = 1'b1;
                            acknowledge();
                        end
                        CALIBRATE: begin
                            next_state = RAMP_MOTORS;
                            clr_tmr = 1'b0;
                            clr_cmd_rdy = 1'b1;
                        end
                        SET_PTCH: begin
                            wpitch = 1'b1;
                            acknowledge();
                        end
                        SET_ROLL: begin 
                            wroll = 1'b1;
                            acknowledge();
                        end
                        SET_YAW: begin 
                            wyaw = 1'b1;
                            acknowledge();
                        end
                        SET_THRST: begin 
                            wthrust = 1'b1;
                            acknowledge();
                        end
                        default: begin // EMER_LAND
                            // Emergency Land, set ptch roll yaw thrst to zero
                            emergency_land = 1'b1;
                            acknowledge();
                        end
                    endcase
                end
            end
        endcase
    end

    // Registers
    
    // d_ptch
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            d_ptch <= 16'h0000;
        else if (emergency_land)
            d_ptch <= 16'h0000;
        else if (wpitch)
            d_ptch <= data;
    end

    // d_roll
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            d_roll <= 16'h0000;
        else if (emergency_land)
            d_roll <= 16'h0000;
        else if (wroll)
            d_roll <= data;
    end

    // d_yaw
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            d_yaw <= 16'h0000;
        else if (emergency_land)
            d_yaw <=  16'h0000;
        else if (wyaw)
            d_yaw <= data;
    end
    
    // thrust
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            thrst <= 9'h000;
        else if (emergency_land)
            thrst <= 9'h000;
        else if (wthrust)
            thrst <= data[8:0];
    end     

    // timer
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            timer <= 0;
        else if (clr_tmr)
            timer <= 0;
        else
            timer <= timer + 1;
    assign timer_full = &timer;

    // strt_cal flop to make sure is high for exactly one clock cycle
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            strt_cal <= 1'b0;
        else if (strt_cal_comb)
            strt_cal <= 1'b1;
        else
            strt_cal <= 1'b0;

    // SR flop for mototrs off
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            motors_off <= 1'b1;
        else if (clr_motors)
            motors_off <= 1'b1;
        else if (inertial_cal)
            motors_off <= 1'b0;

    // to improve readability in FSM comb logic
    task acknowledge();
        resp = 8'hA5;
        send_resp = 1'b1;
        clr_cmd_rdy = 1'b1;
    endtask

endmodule
