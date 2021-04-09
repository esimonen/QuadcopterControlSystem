module SPI_mnrch(
    input             clk,  // 50MHz clock
    input           rst_n,  // Active low reset signal
    input             wrt,  // A high for 1 clock period would initiate a SPI transaction
    output           SS_n,  // SPI protocol signal: low during an SPI transaction
    output           SCLK,  // SPI protocol signal: while SS_n is low, SCLK is 1/16th the freq of clk (3.125MHz)
    output           MOSI,  // SPI protocol signal: data output
    input            MISO,  // SPI protocol signal: data input - SHIFTED ON SCLK RISE
    input  [15:0] wt_data,  // Data to send to serf
    output reg       done,  // Asserted when transmission is complete
    output [15:0] rd_data   // Data recieved, only valid when done is asserted
);

    //bitcntr signals / reg

    reg [4:0] bit_cntr;

    wire shft;
    //State Machine Signals
    logic      ld_SCLK,
          SCLK_div_rst,
                  init;

    typedef enum reg [1:0] {
        IDLE,       //
        SHIFT,      //This is the state that happens while a transmission is occuring -shifts the MOSI during positive sclk,
                    // samples MISO
        BACKPORCH   //
          } state_t;
    state_t nxt_state, state;
    //State Machine

    always_ff @ (posedge clk, negedge rst_n) begin
        //if we reset, return to idle
        if (!rst_n)
            state <= IDLE;
        else
            state <= nxt_state;
        end


    always_comb begin
        //Default signals
        nxt_state   = state; 
        ld_SCLK      = 1'b1; // default ld_sclk high so we don't consume as much power
        SCLK_div_rst = 1'b0; // rsts SCLK_div when high
        init         = 1'b0; //inits SCLK_div to 1011

        case (state)

            BACKPORCH: begin
                ld_SCLK = 1'b0;
                if (SCLK) begin
                    nxt_state = IDLE;
                end
            end

            SHIFT: begin
                ld_SCLK = 1'b0;
                if (bit_cntr[4]) begin
                    SCLK_div_rst   = 1'b1;
                    nxt_state = BACKPORCH;
                end
            end

            default: begin //IDLE state
                if(wrt) begin // Leave idle if wrt data is recieved
                    init       = 1'b1;
                    nxt_state = SHIFT;
                end
            end
        endcase
    end

    //SS_n
    assign SS_n = ld_SCLK;

    //SCLK signals / regs

    reg [3:0] SCLK_div;

    //SCLK logic

    always_ff @(posedge clk, negedge rst_n) begin
        if((!rst_n) || SCLK_div_rst)
            SCLK_div <= 4'b0000;
        if(ld_SCLK)
            SCLK_div <= 4'b1011; // load for front porch
        else
            SCLK_div <= SCLK_div + 1;
    end

    assign SCLK = SCLK_div[3];
    assign shft = (SCLK_div == 4'b1001); //shft 2 cycles after rising edge
    // Shifting signals / regs

    reg [15:0] shft_reg;

    //Shifting logic

    always_ff @(posedge clk, negedge rst_n)
        if (init)
            shft_reg <= wt_data;
        else if (shft)
            shft_reg <= {shft_reg[14:0], MISO}; //shifting reg for MOSI

    assign MOSI = shft_reg[15]; // Shifting bit
    assign rd_data  = shft_reg;  // data only valid when done


    //bitcntr logic

    always_ff @(posedge clk, negedge rst_n)
        if ((!rst_n) || init)
            bit_cntr <= 5'b00000;
        else if (shft)
            bit_cntr <= bit_cntr + 1;


    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            done = 1'b0;
        else if (init | wrt)
            done = 1'b0;
        else if (bit_cntr[4]) //done if we count 16 SCLK cycles
            done = 1'b1;

endmodule