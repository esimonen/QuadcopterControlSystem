module ESC_interface_tb();

	logic clk;
	logic rst_n;
	logic wrt;
	logic [10:0] SPEED;
	logic PWM;
	
	ESC_interface iDUT(.clk(clk), .rst_n(rst_n), .wrt(wrt), .SPEED(SPEED), .PWM(PWM));
	
	initial begin
		clk = 1'b0;
		rst_n = 1'b1;
		wrt = 1'b0;
		@(negedge clk) begin
			rst_n = 0;
		end
		@(negedge clk) begin
			rst_n = 1;
		end
		@(negedge clk) begin
			SPEED = 10;
			wrt = 1'b1;
		end
		@(negedge clk) begin
			wrt = 1'b0;
		end
		repeat (6280)@(posedge clk);
		@(posedge clk);
		
		@(negedge clk) begin
			rst_n = 0;
		end
		@(negedge clk) begin
			rst_n = 1;
		end
		@(negedge clk) begin
			SPEED = 70;
			wrt = 1'b1;
		end
		@(negedge clk) begin
			wrt = 1'b0;
		end
		repeat(6460)@(posedge clk);
		@(posedge clk);
		
		@(negedge clk) begin
			rst_n = 0;
		end
		@(negedge clk) begin
			rst_n = 1;
		end
		@(negedge clk) begin
			SPEED = 0;
			wrt = 1'b1;
		end
		@(negedge clk) begin
			wrt = 1'b0;
		end
		repeat(6250)@(posedge clk);
		@(posedge clk);
		$stop;
	end
	
	always begin
		#5 clk = ~clk;
	end
	
	
endmodule
