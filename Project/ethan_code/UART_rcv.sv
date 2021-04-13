/*
UART_rcv.SV
Ethan Simonen
ECE 551
3/7/2021
*/
module UART_rcv(
    input                clk,  //50 MHz clock signal
    input              rst_n,  //Active low reset
    input            clr_rdy,  //knocks down rdy when asserted
    input                 RX,  //signal recieved from transmitter
    output reg [7:0] rx_data,  //Byte to recieve
    output reg           rdy   //Asserted when byte recieved.
    //Stays high until start bit of next byte start, or until clr_rdy asserted.
);

    //Signals
    reg [3:0]       bit_cnt;    //Bit count counts to 9 for the state machine to remember how many bits it has recieved
    reg [11:0]     baud_cnt;    //Baud count  counts to 19200 bit cycles per RX bit asserted.
    reg [1:0]          F_RX;    //double flopped RX signal. F_RX[0] is what is double flopped.
    reg [8:0]       shifter;

    logic recieving,    // recieve is high while we are recieving a byte
              shift,    // high while shifting
               init,    // starts the baud counter logic from the SM
            set_rdy;    // sets the ready signal when asserted


    //IDLE: SM is waiting for a byte to recieve, as well as the trmt signal
    //RECIEVE: SM is recieving a byte
    typedef enum reg {IDLE, RECIEVE} state_t;
    state_t state, nxt_state;


    //State Machine
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= nxt_state;
    end

    always_comb begin
        //default state outputs
        init         = 0;
        recieving    = 0;
        set_rdy      = 0;
        nxt_state = IDLE;

        //nxt_state logic
        case(state)
            RECIEVE: begin
                recieving = 1;
                nxt_state = RECIEVE;
                if (bit_cnt == 4'b1010) begin
                    nxt_state = IDLE;
                    set_rdy = 1;
                end
            end
            default: begin // IDLE CASE
                if (!F_RX[0]) begin
                    init = 1;
                    //recieving = 1;
                    nxt_state = RECIEVE;
                end
            end
        endcase

    end


    //Double Flopped RX (Preset)
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            //preset
            F_RX <= 2'h3;
        else begin
            F_RX[1] <=   RX;
            F_RX[0] <= F_RX[1];
        end
    end

    //bit counter: keeps track of how many bits have been recieved this transmission
    always_ff @ (posedge clk) begin

        if (init)
            bit_cnt <= 4'b0000;
        
        else if (shift)
            bit_cnt <= bit_cnt + 1;

    end

    //baud counter: keeps track of how many clk cycles have happened during this baud
    always_ff @ (posedge clk) begin

        //half baud cycle to sample in the middle of the baud
        if (init) 
            baud_cnt <= 12'd1302;

        else if (shift)
            baud_cnt <= 12'd2604;

        else if (recieving)
            baud_cnt <= baud_cnt - 1;
    end


    //Shift logic: tells SM when to shift
    assign shift = ~|baud_cnt;

    //RX shifting output
    always_ff @(posedge clk) begin
        if (shift)
            shifter <= {F_RX[0], shifter[8:1]};
    end

    assign rx_data = shifter[7:0];
    //rx_done flop/logic
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            rdy <= 1'b0;
        else if (clr_rdy || init)
            rdy <= 1'b0;
        else if (set_rdy)
            rdy <= 1'b1;
    end
endmodule