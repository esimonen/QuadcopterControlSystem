/*
Creator: Ethan Simonen
Course: ECE 551
Date: 2/24/2021
*/
module ESC_interface(
    input clk,          //50MHz clock
    input rst_n,        //Active low asynch reset
    input wrt,          //Initiates new pulse. Synched with PD control loop
    input [10:0] SPEED, //Result from flight controller telling how fast to run each motor. 
    output reg PWM);    //Output to the ESC to control motor speed. It is effectively a PWM signal.
    
    //intermediate signals for comb

    localparam [12:0] MINSPEED = 13'd6250;      //The motors have a minimum speed needed
    localparam [1:0] SPEED_INCREMENT = 2'd3;    //Motor speed is incremented by 3 each time, as 6250/MAX(SPEED) ~= 3
    wire [12:0] speed_offset;                   //our speed indicated from the controller
    wire [13:0] modified_speed;                 //our speed adjusted with the minspeed
    
    //comb logic

    assign speed_offset = SPEED * SPEED_INCREMENT;

    assign modified_speed = MINSPEED + speed_offset;

    //intermediate signals for sequential

    reg [13:0] speed_count; //register for count down of speed

    //sequential logic

    always_ff @ (posedge clk, negedge rst_n) begin
        if(!rst_n) 
            speed_count <= 14'h0000;
        else if(!wrt)
            speed_count <= speed_count - 1;
        else
            speed_count <= modified_speed;
    end

    always_ff @ (posedge clk, negedge rst_n) begin
        if (!rst_n)
            PWM <= 1'b0;
        else if (~(|speed_count)) //reset
            PWM <= 1'b0;
        else if (wrt)             //set
            PWM <= 1'b1;
    end

endmodule