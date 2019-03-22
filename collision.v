module collision_test(clk, regx, regy, direction,collision);
	input clk;
	input [7:0]regx;
	input [6:0]regy;
	input [1:0]direction;
	output reg [0:0]collision;
	reg [0:0] boarder;
	always @(posedge clk)
	begin
	case (direction)
	if(direction == 2'd0)
		begin
			collision <= (regx == 0);
		end
	else if(direction == 2'd1)
		begin
			collision <= (regx  == 159);
		end
	else if (direction == 2'd2)
		begin
			collision <= (regy == 0);
		end
	else
		begin
			collision <= (regy == 119);
		end
	end 
endmodule