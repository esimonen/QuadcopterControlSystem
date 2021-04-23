// module to manage Electronic Speed Controllers for front, left, back, right motors
module ESCs (clk, rst_n, frnt_spd, bck_spd, lft_spd, rght_spd, frnt, bck, lft, rght, motors_off, wrt);

    input clk, rst_n;
    input [10:0] frnt_spd, bck_spd, lft_spd, rght_spd;
    input motors_off, wrt;

    output frnt, bck, lft, rght;

    wire [10:0] sfront, sback, sleft, sright; // muxed speeds to go to each esc_interface module

    ESC_interface esc_front(.clk(clk), .rst_n(rst_n), .wrt(wrt), .SPEED(sfront), .PWM(frnt));
    ESC_interface esc_back (.clk(clk), .rst_n(rst_n), .wrt(wrt), .SPEED(sback),  .PWM(bck));
    ESC_interface esc_left (.clk(clk), .rst_n(rst_n), .wrt(wrt), .SPEED(sleft),  .PWM(lft));
    ESC_interface esc_right(.clk(clk), .rst_n(rst_n), .wrt(wrt), .SPEED(sright), .PWM(rght));

    assign sfront = motors_off ? 11'h000 : frnt_spd;
    assign sback  = motors_off ? 11'h000 : bck_spd;
    assign sleft  = motors_off ? 11'h000 : lft_spd;
    assign sright = motors_off ? 11'h000 : rght_spd;

endmodule