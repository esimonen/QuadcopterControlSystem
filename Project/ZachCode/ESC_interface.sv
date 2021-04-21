module ESC_interface(
	input clk,
	input rst_n,
	input wrt,
	input [10:0] SPEED,
	output PWM
);

logic [13:0]setting;
logic [12:0]mult_result;
logic[13:0] d1;
logic [13:0] q1;
logic q2;
logic Rst;
logic [13:0] down_count;

assign mult_result = SPEED * 2'b11;

assign setting = mult_result + 13'b1100001101010;

always_ff@(posedge clk, negedge rst_n, wrt, d1) begin
	if(wrt)
		d1 <= setting;
	else
		d1 <= down_count;
	if(!rst_n)
		q1 <= 14'b00000000000000;
	else
		q1 <= d1;
end

always_ff@(q1) begin
	down_count = q1 - 1;
end

assign Rst = ~|q1[13:0];

always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		q2 <= 1'b0;
	if(Rst)
		q2 <= 1'b0;
	else if(wrt)
		q2 <= 1'b1;
	else
		q2 <= q2;
end
assign PWM = q2;
endmodule