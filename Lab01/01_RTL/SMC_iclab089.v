module SMC(
  // Input signals
    mode,
    W_0, V_GS_0, V_DS_0,
    W_1, V_GS_1, V_DS_1,
    W_2, V_GS_2, V_DS_2,
    W_3, V_GS_3, V_DS_3,
    W_4, V_GS_4, V_DS_4,
    W_5, V_GS_5, V_DS_5,   
  // Output signals
    out_n
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [2:0] W_0, V_GS_0, V_DS_0;
input [2:0] W_1, V_GS_1, V_DS_1;
input [2:0] W_2, V_GS_2, V_DS_2;
input [2:0] W_3, V_GS_3, V_DS_3;
input [2:0] W_4, V_GS_4, V_DS_4;
input [2:0] W_5, V_GS_5, V_DS_5;
input [1:0] mode;
//output [8:0] out_n;         							// use this if using continuous assignment for out_n  // Ex: assign out_n = XXX;
 output reg [9:0] out_n; 								// use this if using procedure assignment for out_n   // Ex: always@(*) begin out_n = XXX; end

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment
wire [7:0] I_0, I_1, I_2, I_3, I_4, I_5;
wire [7:0] G_0, G_1, G_2, G_3, G_4, G_5;
reg [7:0] IG_0, IG_1, IG_2, IG_3, IG_4, IG_5;
reg [7:0] IG0, IG1, IG2, IG3, IG4, IG5;
wire [7:0] IG_out0, IG_out1, IG_out2;
reg [6:0] IG_out_div0, IG_out_div1, IG_out_div2;
reg [9:0] op0, op1, op2, out_n_med;

//================================================================
//    DESIGN
//================================================================
// --------------------------------------------------
// write your design here
// --------------------------------------------------
CALCULATE cal0(.W(W_0), .V_GS(V_GS_0), .V_DS(V_DS_0), .I(I_0), .G(G_0));
CALCULATE cal1(.W(W_1), .V_GS(V_GS_1), .V_DS(V_DS_1), .I(I_1), .G(G_1));
CALCULATE cal2(.W(W_2), .V_GS(V_GS_2), .V_DS(V_DS_2), .I(I_2), .G(G_2));
CALCULATE cal3(.W(W_3), .V_GS(V_GS_3), .V_DS(V_DS_3), .I(I_3), .G(G_3));
CALCULATE cal4(.W(W_4), .V_GS(V_GS_4), .V_DS(V_DS_4), .I(I_4), .G(G_4));
CALCULATE cal5(.W(W_5), .V_GS(V_GS_5), .V_DS(V_DS_5), .I(I_5), .G(G_5));

PICK pick(.in0(IG0), .in1(IG1), .in2(IG2), .in3(IG3), .in4(IG4), .in5(IG5), .out0(IG_out0), .out1(IG_out1), .out2(IG_out2), .mode(mode[1]));

always@(*) begin       
    if (mode[0] == 0) begin
        IG_0 = G_0;
        IG_1 = G_1;
        IG_2 = G_2;
        IG_3 = G_3;
        IG_4 = G_4;
        IG_5 = G_5;
    end
    else begin
        IG_0 = I_0;
        IG_1 = I_1;
        IG_2 = I_2;
        IG_3 = I_3;
        IG_4 = I_4;
        IG_5 = I_5;
    end

    if (mode[1] == 0) begin
        IG0 = ~IG_0;
        IG1 = ~IG_1;
        IG2 = ~IG_2;
        IG3 = ~IG_3;
        IG4 = ~IG_4;
        IG5 = ~IG_5;
    end
    else begin
        IG0 = IG_0;
        IG1 = IG_1;
        IG2 = IG_2;
        IG3 = IG_3;
        IG4 = IG_4;
        IG5 = IG_5;
    end
    
    IG_out_div0 = IG_out0 / 3;
    IG_out_div1 = IG_out1 / 3;
    IG_out_div2 = IG_out2 / 3;

    if (mode[0] == 0) begin
        op0 = IG_out_div0;
        op1 = IG_out_div1;
        op2 = IG_out_div2;
    end
    else begin        
        op0 = 2 * IG_out_div0 + IG_out_div0;
        op1 = 4 * IG_out_div1;
        op2 = 4 * IG_out_div2 + IG_out_div2;
    end
    
    out_n = op0 + op1 + op2;
end

endmodule
//================================================================
//   SUB MODULE
//================================================================

module CALCULATE(W, V_GS, V_DS, I, G);
    input [2:0] W;
    input [2:0] V_GS;
    input [2:0] V_DS;
    output reg [7:0] I;
    output reg [7:0] G;

    reg [2:0] V_GS_;
    reg [7:0] I_op;
    reg [7:0] G_op;    

    always@(*) begin
        V_GS_ = V_GS - 1;
        if (V_GS_ > V_DS) begin
            I_op = 2 * V_GS_ * V_DS - V_DS * V_DS;            
            G_op = V_DS * 2; 
        end        
        else begin                  
            I_op = V_GS_ * V_GS_;            
            G_op = V_GS_ * 2;
        end                            
        I = W * I_op;
        G = W * G_op;        
    end
endmodule

module PICK(in0, in1, in2, in3, in4, in5, out0, out1, out2, mode);
    input [7:0] in0;
    input [7:0] in1;
    input [7:0] in2;
    input [7:0] in3;
    input [7:0] in4;
    input [7:0] in5;
    input mode;
    output reg [7:0] out0;
    output reg [7:0] out1;
    output reg [7:0] out2;        
    reg [7:0] res0, res1, res2;

    always@(*) begin
        res0 = in0;
        res1 = 0;
        res2 = 0;

        if (in1 > res0) begin
            res1 = res0;
            res0 = in1;
        end
        else begin
            res1 = in1;
        end

        if (in2 > res0) begin
            res2 = res1;
            res1 = res0;            
            res0 = in2;
        end
        else if (in2 > res1) begin
            res2 = res1;
            res1 = in2;
        end
        else begin
            res2 = in2;
        end

        if (in3 > res0) begin
            res2 = res1;
            res1 = res0;
            res0 = in3;
        end
        else if (in3 > res1) begin
            res2 = res1;
            res1 = in3;
        end
        else if (in3 > res2) begin
            res2 = in3;
        end

        if (in4 > res0) begin
            res2 = res1;
            res1 = res0;
            res0 = in4;
        end
        else if (in4 > res1) begin
            res2 = res1;
            res1 = in4;
        end
        else if (in4 > res2) begin
            res2 = in4;
        end

        if (in5 > res0) begin
            res2 = res1;
            res1 = res0;
            res0 = in5;
        end
        else if (in5 > res1) begin
            res2 = res1;
            res1 = in5;
        end
        else if (in5 > res2) begin
            res2 = in5;
        end

        if (mode == 0) begin
            out0 = ~res2;
            out1 = ~res1;
            out2 = ~res0;
        end
        else begin
            out0 = res0;
            out1 = res1;
            out2 = res2;
        end

    end

endmodule

module SORTI(in0, in1, in2, in3, in4, in5, out0, out1, out2, out3, out4, out5);
    input [6:0] in0;
    input [6:0] in1;
    input [6:0] in2;
    input [6:0] in3;
    input [6:0] in4;
    input [6:0] in5;
    output reg [6:0] out0;
    output reg [6:0] out1;
    output reg [6:0] out2;
    output reg [6:0] out3;
    output reg [6:0] out4;
    output reg [6:0] out5;        
    
    always@(*) begin
        out0 = in0;
        out1 = in1;
        out2 = in2;
        out3 = in3;
        out4 = in4;
        out5 = in5;

        if (out0 < out1) begin            
            {out0, out1} = {out1, out0};
        end            
        if (out2 < out3) begin            
            {out2, out3} = {out3, out2};
        end            
        if (out4 < out5) begin            
            {out4, out5} = {out5, out4};
        end            
        
        if (out1 < out2) begin            
            {out1, out2} = {out2, out1};
        end            
        if (out3 < out4) begin            
            {out3, out4} = {out4, out3};
        end            
        
        if (out2 < out3) begin            
            {out2, out3} = {out3, out2};
        end            

        if (out1 < out2) begin            
            {out1, out2} = {out2, out1};
        end                    
        if (out3 < out4) begin            
            {out3, out4} = {out4, out3};
        end                    

        if (out0 < out1) begin            
            {out0, out1} = {out1, out0};
        end                    
        if (out2 < out3) begin            
            {out2, out3} = {out3, out2};
        end                    
        if (out4 < out5) begin            
            {out4, out5} = {out5, out4};
        end                    

        if (out1 < out2) begin            
            {out1, out2} = {out2, out1};
        end                    
        if (out3 < out4) begin            
            {out3, out4} = {out4, out3};
        end                    
        
        if (out2 < out3) begin            
            {out2, out3} = {out3, out2};
        end          

        if (out1 < out2) begin            
            {out1, out2} = {out2, out1};
        end          
        if (out3 < out4) begin            
            {out3, out4} = {out4, out3};
        end         
    end
endmodule

// module BBQ (meat,vagetable,water,cost);
// input XXX;
// output XXX;
// 
// endmodule

// --------------------------------------------------
// Example for using submodule 
// BBQ bbq0(.meat(meat_0), .vagetable(vagetable_0), .water(water_0),.cost(cost[0]));
// --------------------------------------------------
// Example for continuous assignment
// assign out_n = XXX;
// --------------------------------------------------
// Example for procedure assignment
// always@(*) begin 
// 	out_n = XXX; 
// end
// --------------------------------------------------
// Example for case statement
// always @(*) begin
// 	case(op)
// 		2'b00: output_reg = a + b;
// 		2'b10: output_reg = a - b;
// 		2'b01: output_reg = a * b;
// 		2'b11: output_reg = a / b;
// 		default: output_reg = 0;
// 	endcase
// end
// --------------------------------------------------