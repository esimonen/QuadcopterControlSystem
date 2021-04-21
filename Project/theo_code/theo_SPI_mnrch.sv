// Theo Hornung
// ece 551
// ex17

module SPI_mnrch(clk, rst_n, wrt, SS_n, SCLK, MOSI, MISO, wt_data, done, rd_data);

    input clk, rst_n;       // system clock and async active low reset signal
    input MISO;             // Monarch In Serf Out - input that we get from serf
    input [15:0] wt_data;   // data for us to send to serf
    input wrt;              // high for 1 clk cycle, tells us to send data to serf
    output MOSI;            // Monarch Out Serf In - output that we give to serf
    output reg SCLK;        // clock signal for SPI system
    output reg SS_n;        // low SS_n indicates a transaction (txn) is occurring
    output [15:0] rd_data;  // the data we've read from the serf
    output reg done;        // FSM signal that says we're done with the current write operation

    // FSM states
    typedef enum reg [2:0] { IDLE, TRANSMIT, BACK_PORCH } state_t;
    state_t state;
    state_t next_state;

    reg ld_SCLK; // signal to sync'ly preset sclk counter
    reg [3:0] SCLK_div; // 4bit counter to help generate SCLK

    wire shift; // high when shift reg should shift, should shift 2 clks after posedge SCLK

    reg init; // sync'ly resets bit counter
    reg [4:0] bit_counter; // 5 bit counter to help us know when txn is finished

    reg [15:0] shift_reg; // shift register for transmission

    reg set_done; // sets the SR flop that controls the done signal
    reg set_SS_n_low, clear_SS_n_high;

    wire done16;

    // 4 bit counter used to generate SCLK
    // SCLK freq = 1/16 of freq of clk
    always_ff @(posedge clk)
        if (ld_SCLK) // using different sig than init saves power bc adder not always adding
            SCLK_div <= 4'b1011;
        else
            SCLK_div <= SCLK_div + 1;
    // SCLK generated from MSB of 4-bit counter
    // produces 1/16 of clock frequency
    assign SCLK = SCLK_div[3];
    assign shift = SCLK_div == 4'b1001;

    // 5 bit counter to track number of bits shifted
    // need 5 bits bc otherwise we'll overflow and never reach a count of 16
    always_ff @(posedge clk)
        if (init)
            bit_counter <= 5'b00000;
        else if (shift)
            bit_counter <= bit_counter + 1;
        // otherwise hold bit count
    // transmission done after 16 bits shifted
    // just check MSB bc bit_counter counts up and holding done16 only affects the TRANSMIT state
    assign done16 = bit_counter[4];

    // 16 bit shifter for transmission
    always_ff @(posedge clk)
        if (init)
            shift_reg <= wt_data;
        else if (shift)
            shift_reg <= { shift_reg[14:0], MISO };
        // otherwise hold
    // transmit the MSB of the shift register to the serf
    assign MOSI = shift_reg[15];
    // SPI is full duplex, so we shift in the serf's output, which makes
    // the shift register also be our rd_data output
    assign rd_data = shift_reg;
    
    // SR flop to handle done output
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            done <= 1'b0;
        else if (set_done)
            done <= 1'b1;
        else if (init)
            done <= 1'b0;
        // otherwise hold

    /************FSM************/

    // FSM state flops
    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    
    // FSM state transition and output logic
    always_comb begin
        next_state = state;
        // default signals to prevent latches
        clear_SS_n_high = 1'b1;        // SPI convention for this module specifies high SS_n as default
        set_SS_n_low = 1'b0;
        ld_SCLK = 1'b1;     // default this high to minimze power consumption by SCLK_div counter
        init = 1'b0;
        set_done = 1'b0;
        case (state)
            IDLE: begin
                if (wrt) begin // start txn when told to write
                    init = 1'b1;
                    next_state = TRANSMIT;
                end
            end
            TRANSMIT: begin
                set_SS_n_low = 1'b1; // low for entire txn
                clear_SS_n_high = 1'b0;
                ld_SCLK = 1'b0;
                // wait until 16 bits have been transmitted
                if (done16) begin
                    next_state = BACK_PORCH;
                end
            end
            default: begin // BACK_PORCH
                // back porch should keep SS_n low a little longer after txn finishes
                // so that monarch and serf can settle
                set_SS_n_low = 1'b1; // low for entire txn
                clear_SS_n_high = 1'b0;
                ld_SCLK = 1'b0;

                // wait until E because SCLK will be high when txn finishes,
                // and waiting any longer would let SCLK go back down briefly before back porch finishes
                if (SCLK_div == 4'hE) begin
                    set_done = 1'b1;
                    next_state = IDLE;
                end
            end
        endcase
    end

    // SR flop for SS_n to prevent glitching on outputs
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            SS_n <= 1'b1;
        else if (set_SS_n_low)
            SS_n <= 1'b0;
        else if (clear_SS_n_high)
            SS_n <= 1'b1;

endmodule