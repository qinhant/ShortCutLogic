`define WIDTH_LOG 5
`define WIDTH (1 << `WIDTH_LOG)
`define OUT_WIDTH (`WIDTH << 1)

module top(
    input clk,
    input [`WIDTH-1:0] a1,
    input [`WIDTH-1:0] a2,
    input [`WIDTH-1:0] b,
    input in_valid,
    output [`OUT_WIDTH-1:0] o1,
    output [`OUT_WIDTH-1:0] o2,
    output out_valid1,
    output out_valid2
);

wire [`OUT_WIDTH-1:0] o1, o2;
wire out_valid1, out_valid2;

MUL copy1(
    .clk(clk),
    .in_valid(in_valid),
    .a(a1),
    .b(b),
    .o(o1),
    .out_valid(out_valid1)
);

MUL copy2(
    .clk(clk),
    .in_valid(in_valid),
    .a(a2),
    .b(b),
    .o(o2),
    .out_valid(out_valid2)
);

// assume property (a1 == a2 || b == 0);
// Do not use assume property because it will mess up with the mapping, do the following instead
reg assume_1_violate = 0;
wire assume_1_violate_in = !(a1 == a2 || b == 0) || assume_1_violate;
always @(posedge clk) begin
    assume_1_violate <= assume_1_violate_in;
end

assert property (out_valid1 == out_valid2 || assume_1_violate_in);

endmodule


// Shift-and-Add multiplier
module MUL(
    input clk,
    input in_valid,
    input [`WIDTH-1:0] a,
    input [`WIDTH-1:0] b,
    output [`OUT_WIDTH-1:0] o,
    output out_valid
);
    reg [`WIDTH-1:0] a_reg, b_reg;
    reg [`OUT_WIDTH-1:0] o_reg;
    reg busy;
    reg finish;
    reg [`WIDTH_LOG:0] counter;

    initial begin
        a_reg = 0;
        b_reg = 0;
        o_reg = 0;
        busy = 0;
        finish = 0;
        counter = 0;
    end

    wire busy_next = in_valid && !busy || busy && !finish;
    wire finish_next = (a_reg == 0 || b_reg == 0) && busy;
    wire [`WIDTH-1:0] a_reg_next = in_valid && !busy ? a : a_reg;
    wire [`WIDTH-1:0] b_reg_next = in_valid && !busy ? b : b_reg >> 1;
    wire [`WIDTH_LOG:0] counter_next = !busy ? 0 : counter + 1;
    wire [`OUT_WIDTH-1:0] o_reg_next = !busy ? 0 : o_reg + (b_reg[0] ? a_reg << counter : 0);

    always @(posedge clk) begin
        finish <= finish_next;
        busy <= busy_next;
        a_reg <= a_reg_next;
        b_reg <= b_reg_next;
        counter <= counter_next;
        o_reg <= o_reg_next;
    end

    assign o = o_reg;
    assign out_valid = finish;
endmodule