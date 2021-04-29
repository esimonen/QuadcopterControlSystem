/*
 * Team:            The Moorons
 * Course:          ECE551
 * Professor:       Eric Hoffman
 * Team Members:    Ethan Simonen, Scott Woolf, Zach Berglund, Theo Hornung
 * Date:            4/29/2021
 */

module inert_intf_test(clk, NEXT, RST_n, LED, SS_n, SCLK, MOSI, MISO, INT);

    input clk;
    // push button inputs
    input NEXT;
    input RST_n;
    
    // SPI inputs from inertial sensor
    input MISO;
    input INT;

    // output to LEDs on FPGA board
    output reg [7:0] LED;

    // SPI outputs to inertial sensor
    output SS_n;
    output SCLK;
    output MOSI;

    // constants to use with FPGA LED mux
    localparam SEL_IDLE     = 2'b00;
    localparam SEL_PITCH    = 2'b01;
    localparam SEL_ROLL     = 2'b10;
    localparam SEL_YAW      = 2'b11;

    // internal signals
    wire [15:0] pitch;
    wire [15:0] roll;
    wire [15:0] yaw;
    wire cal_done;

    reg strt_cal;
    
    // high for one cycle, indicates the 'next' button is pressed on fpga
    // so we go to the next state to show pitch/roll/yaw with LEDs
    wire next;
    wire rst_n; // outupt from reset button, is our system's async reset signal
    reg stat;

    // modules to interface with the FPGA push buttons
    PB_release next_btn(.clk(clk), .rst_n(rst_n), .PB(NEXT), .released(next));
    reset_synch reset_btn(.clk(clk), .RST_n(RST_n), .rst_n(rst_n));

    // instantiate inert_intf
    inert_intf inert_intf(.clk(clk), .rst_n(rst_n), .ptch(pitch), .roll(roll), .yaw(yaw), .strt_cal(strt_cal),
                          .cal_done(cal_done), .vld(), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .INT(INT));

    // enum to describe our FSM's states
    typedef enum reg [2:0] { IDLE, CAL, PITCH, ROLL, YAW } state_t;
    state_t state;
    state_t next_state;

    // FSM outputs
    reg [1:0] sel;

    // FSM state register
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    
    // FSM output logic
    always_comb begin
        next_state = state;
        // default outputs to prevent latches
        sel = SEL_IDLE;
        strt_cal = 0;
        stat = 0;
        case(state)
            IDLE: begin
                if(next) begin
                    next_state = CAL;
                    strt_cal = 1;
                end
            end
            CAL: begin
                stat = 1;
                if(cal_done) begin
                    next_state = PITCH;
                end
            end
            PITCH: begin
                sel = SEL_PITCH;
                if(next) begin
                    next_state = ROLL;
                end
            end
            ROLL: begin
                sel = SEL_ROLL;
                if(next) begin
                    next_state = YAW;
                end
            end
            default: begin //state for yaw
                sel = SEL_YAW;
                if(next) begin
                    next_state = PITCH;
                end
            end
        endcase
    end

    // LED mux
    always_comb begin
        unique case (sel)
            SEL_IDLE: begin
                LED = {7'h00, stat };
            end
            SEL_PITCH: begin
                LED = pitch[8:1]; 
            end
            SEL_ROLL: begin
                LED = roll[8:1]; 
            end
            SEL_YAW: begin
                LED = yaw[8:1]; 
            end
        endcase
    end
endmodule