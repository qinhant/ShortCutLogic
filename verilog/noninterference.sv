module noninterference(
    input clk,
    input rst,
    input a1,
    input a2,
    input b
);

wire o1, o2;



alu alu1(
    .clk(clk),
    .rst(rst),
    .a(a1),
    .b(b),
    .o(o1),
    .same_o(0),
    .other_o(o2)
);

alu alu2(
    .clk(clk),
    .rst(rst),
    .a(a2),
    .b(b),
    .o(o2),
    .same_o(0),
    .other_o(o1)
);

// (* keep *)
reg a_diff = 0;

always @(posedge clk) begin
    if (rst) begin
        a_diff <= 0;
    end
    else begin
        a_diff <= a1 != a2;
    end
end
// assume property (b==0);
// Use a monitor to represent this assumption
// reg assume_b = 0;
// always @(posedge clk) begin
//     if (rst) begin
//         assume_b <= 0;
//     end
//     else begin
//         assume_b <= b || assume_b;
//     end
// end

// assume property (a1 == a2);
reg assume_a = 0;
always @(posedge clk) begin
    if (rst) begin
        assume_a <= 0;
    end
    else begin
        assume_a <= (a1 != a2) || assume_a;
    end
end

assert property (o1==o2 || (a1!=a2 || assume_a));

endmodule

module alu(
    input clk,
    input rst,
    input a,
    input b,
    output o,
    input same_o,
    input other_o
);

reg a_reg = 0;
reg b_reg = 0;
wire a_in = !rst && a;
wire b_in = !rst && b;

assign o = same_o ? other_o : a_reg & b_reg;

always @(posedge clk) begin
    a_reg <= a_in;
    b_reg <= b_in;
end

endmodule