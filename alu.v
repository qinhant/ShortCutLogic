module alu(
    input clk,
    input rst,
    input a,
    input b
);

wire o = c;

reg c;

initial begin
    c <= 1;
end

always @(posedge clk) begin
    if (rst)
        c <= 0;
    else
        c <= a & b; 
end

assert property (o==0);
assume property (a==0);
endmodule