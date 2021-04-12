/*
 * Team:            The Moorons
 * Course:          ECE551
 * Professor:       Eric Hoffman
 * Team Members:    Ethan Simonen, Scott Woolf, Zach Berglund, Theo Hornung
 * Date:            4/12/2021
 */
module cmd_cfg_tb();

wire clk;               // clock
wire rst_n;             // active low asynch reset
wire RX_TX;             // data transferred from UART_comm to RemoteComm
wire TX_RX;             // data transferred from RemoteComm to UART_comm
reg [7:0] cmd_in;       // 8-bit command to send
reg [15:0] data_in;     // 16-bit data that accompanies command
wire send_cmd;          // indicates to tranmit 24-bit command (cmd)
reg cmd_sent;           // indicates transmission of command complete from RemoteComm to UART_comm
reg cmd_rdy;            // indicates 24-bit command has been received by UART_comm
wire [7:0] cmd;         // Command opcode
wire [15:0] data;       // the data read from the UART_comm 
wire clr_cmd_rdy;       // asserted when we want to clear the command ready signal from UART
reg [7:0] resp;         // the response that is being sent to the UART_comm 
wire send_resp;         // asserted when sending the response from cmd_cfg to UART_comm
reg [15:0] d_ptch;      // Holding register for desired pitch
reg [15:0] d_roll;      // Holding register for desired roll
reg [15:0] d_yaw;       // Holding register for desired yaw
reg [7:0] thrst;        // Holding register for thrust
reg strt_cal;           // Asserted when we want to start the calabration from the inertial integrator
reg inertial_cal;       // Held high during duration of calibration
wire cal_done;          // indicates the calibration is complete
reg motors_off;         // goes to ESC, shuts off motors


// instantiate DUTs
RemoteComm iRemote(.clk(clk), .rst_n(rst_n), .RX(RX_TX), .TX(TX_RX), .cmd(cmd_in), .data(data_in), .send_cmd(send_cmd), .cmd_sent(cmd_sent), .resp_rdy(), .resp(), .clr_resp_rdy());
UART_comm iUART(.clk(clk), .rst_n(rst_n), .RX(TX_RX), .TX(RX_TX), .resp(resp), .send_resp(send_resp), .resp_sent(), .cmd_rdy(cmd_rdy), .cmd(cmd), .data(data), .clr_cmd_rdy(clr_cmd_rdy));
cmd_cfg icmd_cfg(.clk(clk), .rst_n(rst_n), .cmd_rdy(cmd_rdy), .cmd(cmd), .data(data), .clr_cmd_rdy(clr_cmd_rdy), .resp(resp), .send_resp(send_resp), .d_roll(d_roll), .d_yaw(d_yaw), .d_ptch(d_ptch), .thrst(thrst), .strt_cal(strt_cal), .inertial_cal(inertial_cal), .cal_done(cal_done), .motors_off(motors_off);

logic error;

initial begin
    clk = 0;
    error = 0;
    
    rst_n = 0;
    
    @(posedge clk); // wait a clock cycle
    @(negedge clk) begin 
        rst_n = 1; // deassert reset on opposite edge of flops
        cmd = 8'h06;
    end
    @(posedge strt_cal) begin
        if(!inertial_cal) begin
            $display("inertial_cal should be high after calibration command");
            error = 1;
        end
        if(d_ptch !== 11'h290 || d_roll !== 11'h290 || d_yaw !== 11'h290) begin
            $display("Calibration Test Failed:\nDesired pitch: 11'h290, Actual pitch: %h\nDesired roll: 11'h290, Actual roll: %h\nDesired yaw: 11'h290, Actual yaw: %h\n",d_ptch,d_roll,d_yaw);
            error = 1;
        end
        cal_done = 1;
        clr_cmd_rdy = 1;
    end


    
    
    

    if(!error)
        $display("YAHOO!! All tests passed!");
    $stop;
end


always
    #5 clk = ~clk;

endmodule
