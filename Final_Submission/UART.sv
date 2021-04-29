/*
 * Team:            The Moorons
 * Course:          ECE551
 * Professor:       Eric Hoffman
 * Team Members:    Ethan Simonen, Scott Woolf, Zach Berglund, Theo Hornung
 * Date:            4/29/2021
 */

module UART(clk, rst_n, trmt, tx_data, tx_done, rx_rdy, clr_rx_rdy, rx_data, TX, RX);

input clk,rst_n;                // clock and active low reset
input trmt;                     // starts a new outgoing transmission
input [7:0] tx_data;            // byte to transmit
input clr_rx_rdy;                  // rdy can be cleared by this or new start bit
input RX;                       // serial data in line
output tx_done;                 // indicates a completed outgoing transmission
output rx_rdy;                     // asserted when byte received
output [7:0] rx_data;           // byte received
output TX;                      // serial data out line

//////////////////////////////
// Instantiate Transmitter //
////////////////////////////
UART_tx iTX(.clk(clk), .rst_n(rst_n), .TX(TX), .trmt(trmt),
        .tx_data(tx_data), .tx_done(tx_done));

///////////////////////////
// Instantiate Receiver //
/////////////////////////
UART_rcv iRX(.clk(clk), .rst_n(rst_n), .RX(RX), .rdy(rx_rdy),
             .clr_rdy(clr_rx_rdy), .rx_data(rx_data));

endmodule
