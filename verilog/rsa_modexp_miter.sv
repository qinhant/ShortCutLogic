`timescale 1ns / 1ps
`define UPDATING 3'd1
`define CHECK 3'd2
`define HOLDING 3'd3
`define UPDATE 2'd1
`define HOLD 2'd2

module mod_exp(
    input [WIDTH*2-1:0] base,//base here represents (a) 
	input [WIDTH*2-1:0] modulo,//modulo here is modulus (n)
	input [WIDTH*2-1:0] exponent,//exponent here is the power of base (b)
	input clk,//system clk
	input reset,//resets module
	output finish,//sends finish signal on completion
    output [WIDTH*2-1:0] result
    );
    
    parameter WIDTH = 32;
        
    reg [WIDTH*2-1:0] base_reg,modulo_reg,exponent_reg,result_reg;
    reg [1:0] state;
    
    wire [WIDTH*2-1:0] result_mul_base = result_reg * base_reg;
    wire [WIDTH*2-1:0] result_next;
    wire [WIDTH*2-1:0] base_squared = base_reg * base_reg;
    wire [WIDTH*2-1:0] base_next;
    wire [WIDTH*2-1:0] exponent_next = exponent_reg >> 1;
    
    assign finish = (state == `HOLD) ? 1'b1:1'b0;
    assign result = result_reg;
    
    mod base_squared_mod(base_squared,modulo_reg,base_next,);                   //  implementation of 
    defparam base_squared_mod.WIDTH = WIDTH*2;                                  //  right to left 
                                                                                //  binary exponentiation  
    mod result_mul_base_mod (result_mul_base,modulo_reg,result_next,);          //  by.
    defparam result_mul_base_mod.WIDTH = WIDTH*2;                               //  BRUCE SCHIEMER
    
   
    always @(posedge clk) begin
        if(reset) begin                                                         //initialisation of values
            base_reg <= base;
            modulo_reg <= modulo;
            exponent_reg <= exponent;                
            result_reg <= 32'd1;
            state <= `UPDATE;
        end
        else case(state)
            `UPDATE: begin
                if (exponent_reg != 64'd0) begin
                    if (exponent_reg[0])
                        result_reg <= result_next;
                    base_reg <= base_next;
                    exponent_reg <= exponent_next;
                    state <= `UPDATE;
                end
                else state <= `HOLD;
            end
            
           `HOLD: begin
                end
       endcase
    end
endmodule

module mod(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] n,
    output [WIDTH-1:0] R,
    output [WIDTH-1:0] Q
    );
   parameter WIDTH = 19;
   reg [WIDTH-1:0] A,N;
   reg [WIDTH:0] p;   
   integer i;
  
   always@ (a or n) begin
       A = a;
       N = n;
       p = 0;
       for(i=0;i < WIDTH;i=i+1) begin 
           p = {p[WIDTH-2:0],A[WIDTH-1]};
           A[WIDTH-1:1] = A[WIDTH-2:0];
           p = p-N;
           if(p[WIDTH-1] == 1)begin
                A[0] = 1'b0;
                p = p + N;   
           end
           else
                A[0] =1'b1;
      end
         
   end    
   
   assign R = p,Q = A;
endmodule

module top(
    input [WIDTH*2-1:0] base,//base here represents (a) 
	input [WIDTH*2-1:0] modulo,//modulo here is modulus (n)
	input [WIDTH*2-1:0] exponent1,//exponent here is the power of base (b)
    input [WIDTH*2-1:0] exponent2,//exponent here is the power of base (b)
	input clk,//system clk
	input reset//resets module

);
parameter WIDTH = 32;

wire finish1, finish2;

mod_exp copy1(
    .base(base),
    .modulo(modulo),
    .exponent(exponent1),
    .clk(clk),
    .reset(reset),
    .finish(finish1),
    .result(result)
);

mod_exp copy2(
    .base(base),
    .modulo(modulo),
    .exponent(exponent2),
    .clk(clk),
    .reset(reset),
    .finish(finish2),
    .result(result)
);

reg assume_1_violate;
wire assume_1_violate_in;

// Assume that the MSB of two exponents are both 1
assign assume_1_violate_in = assume_1_violate || ~exponent1[WIDTH*2-1] || ~exponent2[WIDTH*2-1];

always @(posedge clk) begin
    assume_1_violate <= assume_1_violate_in;
end

wire assume_violate;
assign assume_violate = `ASSUME_ON ? assume_1_violate_in : 0;

assert property (assume_violate || (finish1 == finish2));
endmodule