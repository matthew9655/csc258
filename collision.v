module collision_test(clk, regx, regy, collision);
	input clk;
	input [6:0]regx, regy;
	output reg [0:0]collision;
	reg [0:0] boarder;
	always @(posedge clk)
	begin
	boarder <= ((regx == 0) || (regx == 159) || (regy == 0) || (regy == 119));
	end 
	always @(*)
	collision <= boarder;
endmodule