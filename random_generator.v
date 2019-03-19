module random_generator(CLOCK_50, randomX, randomY);
	input CLOCK_50;
	output reg [9:0] randomX;
	output reg [8:0] randomY;

	reg [7:0] x = 10; //.5 -> 0 - 255 -> 62
	reg [6:0] y = 10; //.5 -> 0 - 127 -> 46
	
	always@(posedge CLOCK_50)
		x <= x + 4;
		
	always@(posedge CLOCK_50)
		y <= y + 2;
	
	always@(posedge CLOCK_50)
	begin
		if(x > 62)
			randomX <= ((x % 62) + 1) * 10 ;
		else if (x < 5)
			randomX <= ((x + 1) * 4) * 10;
		else
			randomX <= (x * 10);
	end
	
	always@(posedge CLOCK_50)
	begin
		if (y > 46)
			randomY <= ((y % 46) + 1) * 10;
		else if (y < 5)
			randomY <= ((y + 1) * 3) * 10;
		else 
			randomY <= (y * 10);
	end
	endmodule 
	
module foodTest(CLOCK_50, snakeX, snakeY, foodX, foodY, outX, outY);
	input CLOCK_50;
	 input[9:0] snakeX, foodX;
	 input[8:0] snakeY, foodY;
	 output reg[9:0] outX;
	 output reg[8:0] outY;
	 assign regenerate_food = (snakeX == foodX)&&(snakeY == foodY);
	 always @(posedge CLOCK_50)
	 begin
		if(regenerate_food == 1'b1)
			random_generator random(CLOCK_50, outX, outY);
		else 
			outX <= foodX;
			outY <= foodY;
		end
	endmodule
