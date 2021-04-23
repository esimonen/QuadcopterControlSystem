/*
UART_tx.SV
Ethan Simonen
ECE 551
3/5/2021
*/
module UART_tx(
    input           clk,  //50 MHz clock signal
    input         rst_n,  //Active low reset
    input          trmt,  //Assrted for 1 clk cycle to initiate transmisson
    input [7:0] tx_data,  //Byte to transmit
    output           TX,  //Serial data output
    output reg  tx_done   //Asserted when byte is done transmitting. Stays high until next byte is transmitted.
);

    //signals

    logic          init,    //asserted when new byte is starting
                  shift,    //asserted when tx_shift_reg is shifting
           transmitting;    //asserted while a Byte is being transmitted

    reg [3:0]   bit_cnt;    //Bit count counts to 9 for the state machine to remember how many bits it has transmitted
    reg [11:0] baud_cnt;    //Baud count  counts to 19200 bit cycles per TX bit asserted.
    reg  [8:0] tx_shift_reg;//reg that keeps track of the byte being sent

    //IDLE: SM is waiting for a byte to transmit, as well as the trmt signal
    //TRANSMIT: SM is transmitting a byte
    typedef enum reg {IDLE, TRANSMIT} state_t;
    state_t state, nxt_state;


    //State Machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= nxt_state;
    end
    always_comb begin

        //Default state outputs
        init          = 0;
        transmitting  = 0;
        nxt_state  = IDLE;

        case(state)
            TRANSMIT: begin
                
                transmitting = 1;
                nxt_state = TRANSMIT;
                if(bit_cnt == 4'b1010) begin
                    nxt_state = IDLE;
                end
            end
            default: begin //IDLE STATE

                if (trmt) begin
                    init = 1;
                    //transmitting = 1;
                    nxt_state = TRANSMIT;
                end
            end
        endcase
    end

    //bit counter: keeps track of how many bits have been transmitted this transmission
    always_ff @ (posedge clk) begin

        if (init)
            bit_cnt <= 4'b0000;
        
        else if (shift)
            bit_cnt <= bit_cnt + 1;

    end

    //baud counter: keeps track of how many clk cycles have happened during this baud
    always_ff @ (posedge clk) begin
        if (init || shift)
            baud_cnt <= 12'd2604;

        else if (transmitting)
            baud_cnt <= baud_cnt - 1;
    end

    //Shift logic: tells SM when to shift
    assign shift = ~|baud_cnt;

    //TX shifting output
    always_ff @ (posedge clk, negedge rst_n) begin

        if (!rst_n)
            tx_shift_reg <= 9'h1FF;

        else if (init)
            tx_shift_reg <= {tx_data, 1'b0};
        
        else if (shift)
            tx_shift_reg <= {1'b1, tx_shift_reg[8:1]};

    end

    assign TX = tx_shift_reg[0];

    //tx_done flop/logic
    always_ff @ (posedge clk, negedge rst_n) begin
        //Behavior of this ff models a SR ff, undefined behavior for both init and set_done being asserted concurrently
        if(!rst_n)
            tx_done <= 1'b0;

        else if (init)
            tx_done <= 1'b0;

        else if (bit_cnt == 4'b1010)
            tx_done <= 1'b1;

    end
endmodule