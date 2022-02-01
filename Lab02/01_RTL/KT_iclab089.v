module KT(
    clk,
    rst_n,
    in_valid,
    in_x,
    in_y,
    move_num,
    priority_num,
    out_valid,
    out_x,
    out_y,
    move_out
);

input clk,rst_n;
input in_valid;
input [2:0] in_x,in_y;
input [4:0] move_num;
input [2:0] priority_num;

output reg out_valid;
output reg [2:0] out_x,out_y;
output reg [4:0] move_out;

//***************************************************//
//Finite State Machine example
//***************************************************//
parameter IDLE = 2'b00, INPUT = 2'b01, COMPUTE = 2'b10, OUTPUT = 2'b11;

reg [1:0] state, n_state;
reg [2:0] dirs[23:0], dirs_ns[23:0];
reg [2:0] prior, prior_ns;
reg [4:0] i, i_ns;
reg [4:0] cur_move, cur_move_ns, cur_move_minus, cur_move_plus;
reg [2:0] start_x, start_x_ns, start_y, start_y_ns;
wire [2:0] prev_x, prev_y;
reg [2:0] cur_x, cur_y, next_x, next_y;
reg [2:0] cur_dir, next_dir;
wire [2:0] next_dir_x, next_dir_y;
wire [2:0] next_move_x, next_move_y, next_move_dir;
wire [2:0] prev_move_x, prev_move_y;
wire [2:0] prev_dir;
wire dir_valid, cur_valid;
reg [4:0] visited[4:0], visited_ns[4:0];
reg back, back_ns;

NEXTDIR nextDir(.in_x(cur_x), .in_y(cur_y), .dir(dirs[cur_move_minus]), .out_x(next_dir_x), .out_y(next_dir_y), .valid(dir_valid));
PREVDIR prevDir(.in_x(cur_x), .in_y(cur_y), .dir(dirs[cur_move_minus]), .out_x(prev_x), .out_y(prev_y));
PICKDIR pickDir(.in_x(cur_x), .in_y(cur_y), .start(cur_dir), .prior(prior), .back(back), .in_visited({visited[4], visited[3], visited[2], visited[1], visited[0]}), .valid(cur_valid), .out_x(next_move_x), .out_y(next_move_y), .out_dir(next_move_dir));
CALPREVDIR calPrevDir(.prev_x(cur_x), .prev_y(cur_y), .cur_x(in_x), .cur_y(in_y), .dir(prev_dir));
//***************************************************//

always@(*) begin
	n_state = state;

	out_valid = 0;
	out_x = 0;
	out_y = 0;	
	move_out = 0;
	for (i_ns = 0; i_ns < 24; i_ns = i_ns + 1) begin
		dirs_ns[i_ns] = dirs[i_ns];			
	end	
	for (i_ns = 0; i_ns < 5; i_ns = i_ns + 1) begin
		visited_ns[i_ns] = visited[i_ns];
	end	
	prior_ns = prior;
	cur_move_ns = cur_move;	
	next_x = cur_x;
	next_y = cur_y;
	next_dir = cur_dir;
	back_ns = back;

	start_x_ns = start_x;
	start_y_ns = start_y;
	cur_move_minus = cur_move - 1;	
	cur_move_plus = cur_move + 1;	

	case(state)		
		IDLE: begin
			for (i_ns = 0; i_ns < 5; i_ns = i_ns + 1) begin
				visited_ns[i_ns] = 5'b00000;
			end									
			back_ns = 0;

			if (in_valid) begin
				n_state = INPUT;
				
				start_x_ns = in_x;
				start_y_ns = in_y;
				next_x = in_x;
				next_y = in_y;
				visited_ns[in_x][in_y] = 1'b1;
				cur_move_ns = 1;				
				prior_ns = priority_num;				
			end
		end
		INPUT: begin
			if (in_valid) begin
				dirs_ns[cur_move_minus] = prev_dir;
				visited_ns[in_x][in_y] = 1'b1;
				next_x = in_x;
				next_y = in_y;
				cur_move_ns = cur_move_plus;
			end
			else begin				
				n_state = COMPUTE;					
				next_dir = prior;
				cur_move_ns = cur_move_minus;
			end
		end
		COMPUTE: begin			
			if (cur_valid || cur_move == 24) begin
				next_x = next_move_x;
				next_y = next_move_y;
				next_dir = prior;
				cur_move_ns = cur_move_plus;
				back_ns = 0;
				visited_ns[cur_x][cur_y] = 1'b1;
				dirs_ns[cur_move] = next_move_dir;										

				if (cur_move_ns == 24 || cur_move == 24) begin
					n_state = OUTPUT;										
					cur_move_ns = 1;
					next_x = start_x;
					next_y = start_y;
				end

			end
			else begin				
				visited_ns[cur_x][cur_y] = 1'b0;
				back_ns = 1;
				next_x = prev_x;
				next_y = prev_y;
				cur_move_ns = cur_move_minus;
				next_dir = dirs[cur_move_ns] + 1;
			end					
		end
		OUTPUT: begin
			out_valid = 1;			
			out_x = cur_x;
			out_y = cur_y;
			move_out = cur_move;
			cur_move_ns = cur_move_plus;
			next_x = next_dir_x;
			next_y = next_dir_y;
			if (cur_move == 25) begin
				n_state = IDLE;
				cur_move_ns = 0;
			end
		end
	endcase
end

always@(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state <= IDLE;							
	end
	else begin
		state <= n_state;
		
		for (i = 0; i < 24; i = i + 1) begin			
			dirs[i] <= dirs_ns[i];						
		end		
		for (i = 0; i < 5; i = i + 1) begin
			visited[i] <= visited_ns[i];
		end
		start_x <= start_x_ns;
		start_y <= start_y_ns;		
		prior <= prior_ns;
		cur_move <= cur_move_ns;				
		cur_x <= next_x;
		cur_y <= next_y;
		cur_dir <= next_dir;
		back <= back_ns;
	end
end

endmodule

module PICKDIR(in_x, in_y, start, prior, back, in_visited, out_x, out_y, out_dir, valid);
input [2:0] in_x;
input [2:0] in_y;
input [2:0] start;
input [2:0] prior;
input back;
input [24:0] in_visited;
output reg valid;
output reg [2:0] out_x;
output reg [2:0] out_y;
output reg [2:0] out_dir;

reg [2:0] cur_dir, tempt_dir;
reg [2:0] limit;
wire cur_valid [7:0];
wire [2:0] cur_out_x [7:0], cur_out_y [7:0];
wire [4:0] visited [4:0];

assign {visited[4], visited[3], visited[2], visited[1], visited[0]} = in_visited;
NEXTDIR nextDir0(.in_x(in_x), .in_y(in_y), .dir(3'b000), .out_x(cur_out_x[0]), .out_y(cur_out_y[0]), .valid(cur_valid[0]));
NEXTDIR nextDir1(.in_x(in_x), .in_y(in_y), .dir(3'b001), .out_x(cur_out_x[1]), .out_y(cur_out_y[1]), .valid(cur_valid[1]));
NEXTDIR nextDir2(.in_x(in_x), .in_y(in_y), .dir(3'b010), .out_x(cur_out_x[2]), .out_y(cur_out_y[2]), .valid(cur_valid[2]));
NEXTDIR nextDir3(.in_x(in_x), .in_y(in_y), .dir(3'b011), .out_x(cur_out_x[3]), .out_y(cur_out_y[3]), .valid(cur_valid[3]));
NEXTDIR nextDir4(.in_x(in_x), .in_y(in_y), .dir(3'b100), .out_x(cur_out_x[4]), .out_y(cur_out_y[4]), .valid(cur_valid[4]));
NEXTDIR nextDir5(.in_x(in_x), .in_y(in_y), .dir(3'b101), .out_x(cur_out_x[5]), .out_y(cur_out_y[5]), .valid(cur_valid[5]));
NEXTDIR nextDir6(.in_x(in_x), .in_y(in_y), .dir(3'b110), .out_x(cur_out_x[6]), .out_y(cur_out_y[6]), .valid(cur_valid[6]));
NEXTDIR nextDir7(.in_x(in_x), .in_y(in_y), .dir(3'b111), .out_x(cur_out_x[7]), .out_y(cur_out_y[7]), .valid(cur_valid[7]));

always@(*) begin
	cur_dir = start;
	tempt_dir = start;
	valid = 1'b1;
	
	if (back && start == prior)
		valid = 0;		

	if (!cur_valid[cur_dir] || visited[cur_out_x[cur_dir]][cur_out_y[cur_dir]] == 1'b1) begin
		cur_dir = start + 1;
		tempt_dir = cur_dir;
		if (cur_dir == prior)
			valid = 1'b0;
		if (!cur_valid[cur_dir] || visited[cur_out_x[cur_dir]][cur_out_y[cur_dir]] == 1'b1) begin			
			cur_dir = tempt_dir + 1;
			tempt_dir = cur_dir;
			if (cur_dir == prior)
				valid = 1'b0;
			if (!cur_valid[cur_dir] || visited[cur_out_x[cur_dir]][cur_out_y[cur_dir]] == 1'b1) begin
				cur_dir = tempt_dir + 1;
				tempt_dir = cur_dir;
				if (cur_dir == prior)
					valid = 1'b0;
				if (!cur_valid[cur_dir] || visited[cur_out_x[cur_dir]][cur_out_y[cur_dir]] == 1'b1) begin
					cur_dir = tempt_dir + 1;
					tempt_dir = cur_dir;
					if (cur_dir == prior)
						valid = 1'b0;
					if (!cur_valid[cur_dir] || visited[cur_out_x[cur_dir]][cur_out_y[cur_dir]] == 1'b1) begin
						cur_dir = tempt_dir + 1;
						tempt_dir = cur_dir;
						if (cur_dir == prior)
							valid = 1'b0;
						if (!cur_valid[cur_dir] || visited[cur_out_x[cur_dir]][cur_out_y[cur_dir]] == 1'b1) begin
							cur_dir = tempt_dir + 1;
							tempt_dir = cur_dir;
							if (cur_dir == prior)
								valid = 1'b0;
							if (!cur_valid[cur_dir] || visited[cur_out_x[cur_dir]][cur_out_y[cur_dir]] == 1'b1) begin
								cur_dir = tempt_dir + 1;
								if (cur_dir == prior)
									valid = 1'b0;
								if (!cur_valid[cur_dir] || visited[cur_out_x[cur_dir]][cur_out_y[cur_dir]] == 1'b1) begin
									valid = 1'b0;
								end
							end
						end						
					end
				end
			end			
		end								
	end		
	out_x = cur_out_x[cur_dir];	
	out_y = cur_out_y[cur_dir];
	out_dir = cur_dir;
end

endmodule

module NEXTDIR(in_x, in_y, dir, out_x, out_y, valid);
input [2:0] in_x;
input [2:0] in_y;
input [2:0] dir;
output reg [2:0] out_x;
output reg [2:0] out_y;
output reg valid;

reg signed [2:0] offset_x, offset_y;

always@(*) begin
	valid = 1;
	offset_x = 0;
	offset_y = 0;

	case(dir)
		3'b000: begin
			if (in_x < 1 || in_y > 2) begin
				valid = 0;
			end
			else begin
				offset_x = -1;
				offset_y = 2;
			end
		end
		3'b001: begin
			if (in_x > 3 || in_y > 2) begin
				valid = 0;
			end
			else begin
				offset_x = 1;
				offset_y = 2;
			end
		end
		3'b010: begin
			if (in_x > 2 || in_y > 3) begin
				valid = 0;
			end
			else begin
				offset_x = 2;
				offset_y = 1;
			end
		end
		3'b011: begin
			if (in_x > 2 || in_y < 1) begin
				valid = 0;
			end
			else begin
				offset_x = 2;
				offset_y = -1;
			end
		end
		3'b100: begin
			if (in_x > 3 || in_y < 2) begin
				valid = 0;
			end
			else begin
				offset_x = 1;
				offset_y = -2;
			end
		end
		3'b101: begin
			if (in_x < 1 || in_y < 2) begin
				valid = 0;
			end
			else begin
				offset_x = -1;
				offset_y = -2;
			end
		end
		3'b110: begin
			if (in_x < 2 || in_y < 1) begin
				valid = 0;
			end
			else begin
				offset_x = -2;
				offset_y = -1;
			end

		end
		3'b111: begin
			if (in_x < 2 || in_y > 3) begin
				valid = 0;
			end
			else begin
				offset_x = -2;
				offset_y = 1;
			end
		end
	endcase
	out_x = in_x + offset_x;
	out_y = in_y + offset_y;
end

endmodule


module CALPREVDIR(prev_x, prev_y, cur_x, cur_y, dir);
input [2:0] prev_x;
input [2:0] prev_y;
input [2:0] cur_x;
input [2:0] cur_y;
output reg [2:0] dir;

reg signed [3:0] offset_x, offset_y;

always@(*) begin	
	offset_x = $signed({1'b0, cur_x}) - $signed({1'b0, prev_x});
	offset_y = $signed({1'b0, cur_y}) - $signed({1'b0, prev_y});

	dir = 0;	

	case(offset_x) 
		-2'b01: begin
			if (offset_y == 2'b10) 
				dir = 3'b000;			
			else 
				dir = 3'b101;			
		end
		-2'b10: begin
			if (offset_y == 2'b01) 
				dir = 3'b111;			
			else 
				dir = 3'b110;			
		end		
		2'b01: begin
			if (offset_y == 2'b10) 
				dir = 3'b001;			
			else 
				dir = 3'b100;			
		end
		2'b10: begin
			if (offset_y == 3'b01)
				dir = 3'b010;			
			else 
				dir = 3'b011;
		end	
	endcase
end

 
endmodule


module PREVDIR(in_x, in_y, dir, out_x, out_y);
input [2:0] in_x;
input [2:0] in_y;
input [2:0] dir;
output reg [2:0] out_x;
output reg [2:0] out_y;

reg signed [2:0] offset_x, offset_y;

always@(*) begin	
	offset_x = 0;
	offset_y = 0;

	case(dir)
		3'b000: begin			
			offset_x = 1;
			offset_y = -2;			
		end
		3'b001: begin			
			offset_x = -1;
			offset_y = -2;			
		end
		3'b010: begin			
			offset_x = -2;
			offset_y = -1;			
		end
		3'b011: begin			
			offset_x = -2;
			offset_y = 1;			
		end
		3'b100: begin			
			offset_x = -1;
			offset_y = 2;			
		end
		3'b101: begin			
			offset_x = 1;
			offset_y = 2;			
		end
		3'b110: begin			
			offset_x = 2;
			offset_y = 1;
		end
		3'b111: begin			
			offset_x = 2;
			offset_y = -1;		
		end
	endcase
	out_x = in_x + offset_x;
	out_y = in_y + offset_y;
end

endmodule


//FSM current state assignment
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
// 		state <= RESET;
// 	end
// 	else begin
// 		state <= n_state;
// 	end
// end

// //FSM next state assignment
// always@(*) begin
// 	case(state)		
// 		RESET: begin

// 			n_state = IDLE;
// 		end
// 		IDLE: begin
// 			if (in_valid) begin
				
// 			end			
// 		end
// 		INPUT: begin
			
// 		end
// 		COMPUTE: begin
			
// 		end
// 		OUTPUT: begin
			
// 		end
// 		default: begin
// 			n_state = state;
// 		end
	
// 	endcase
// end 

// //Output assignment
// always@(posedge clk or negedge rst_n) begin
// 	if(!rst_n) begin
		
// 	end
// 	else if( ) begin
		
// 	end
// 	else begin
		
// 	end
// end