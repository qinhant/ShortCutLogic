`define WIDTH_LOG 3
`define WIDTH (1 << `WIDTH_LOG)
`define OUT_WIDTH (`WIDTH << 1)
`define CT_TIME 0
`define SHORTCUT 0
`define SYNC 0
// `define FOUR_TRACE_PROP

module multiplier_sc(
    input clk,
    input [`WIDTH-1:0] a1,
    input [`WIDTH-1:0] a2,
    input [`WIDTH-1:0] b,
    input in_valid
);

wire [`OUT_WIDTH-1:0] o1, o1_next, o2, o2_next;
wire out_valid1, out_valid2;
wire busy1, busy1_next, busy2, busy2_next, finish1, finish1_next, finish2, finish2_next;
wire [`WIDTH-1:0] a_reg1, a_reg1_next, a_reg2, a_reg2_next, b_reg1, b_reg1_next, b_reg2, b_reg2_next;
wire [`WIDTH_LOG:0] counter1, counter1_next, counter2, counter2_next;

// Predicate variables
// Compare the fan-in registers of every register in the two copies.
// Also need to add the relation between predicate variables to make them inductive
reg a_reg_diff, b_reg_diff, o_reg_diff, counter_diff, busy_diff, finish_diff;

// wire a_reg_next_same = assume_1_in || (!busy_diff && !a_reg_diff && a1==a2);
// wire b_reg_next_same = assume_1_in || (!busy_diff && !b_reg_diff);
// wire o_reg_next_same = assume_1_in || (!busy_diff && !o_reg_diff && !a_reg_diff && !b_reg_diff && !counter_diff);
// wire counter_next_same = assume_1_in || (!busy_diff && !counter_diff);
// wire busy_next_same = assume_1_in || (!busy_diff && !finish_diff && !(`CT_TIME ? 0 : a_reg_diff) && !b_reg_diff);
// wire finish_next_same = assume_1_in || (!busy_diff && !(`CT_TIME ? 0 : a_reg_diff) && !b_reg_diff);

// always @(posedge clk) begin
//     a_reg_diff <= (pause_1 || pause_2) || !(busy1==busy2 && a_reg1==a_reg2 && a1==a2) && !a_reg_next_same;
//     b_reg_diff <= (pause_1 || pause_2) || !(busy1==busy2 && b_reg1==b_reg2) && !b_reg_next_same;
//     o_reg_diff <= (pause_1 || pause_2) || !(busy1==busy2 && o1==o2 && a_reg1==a_reg2 && b_reg1==b_reg2 && counter1==counter2) && !o_reg_next_same;
//     counter_diff <= (pause_1 || pause_2) || !(busy1==busy2 && counter1==counter2) && !counter_next_same;
//     busy_diff <= (pause_1 || pause_2) || !(busy1==busy2 && finish1==finish2 && (`CT_TIME ? 1 : a_reg1==a_reg2) && b_reg1==b_reg2) && !busy_next_same;
//     finish_diff <= (pause_1 || pause_2) || !(busy1==busy2 && (`CT_TIME ? 1 : a_reg1==a_reg2) && b_reg1==b_reg2) && !finish_next_same;
// end

wire a_reg_next_same = assume_1_in || (!busy_diff && !a_reg_diff && a1==a2);
wire b_reg_next_same = assume_1_in || (!busy_diff && !b_reg_diff);
wire o_reg_next_same = assume_1_in || (!busy_diff && !o_reg_diff && !a_reg_diff && !b_reg_diff && !counter_diff);
wire counter_next_same = assume_1_in || (!busy_diff && !counter_diff);
wire busy_next_same = assume_1_in || (!busy_diff && !finish_diff && !(`CT_TIME ? 0 : a_reg_diff) && !b_reg_diff);
wire finish_next_same = assume_1_in || (!busy_diff && !(`CT_TIME ? 0 : a_reg_diff) && !b_reg_diff);

always @(posedge clk) begin
    a_reg_diff <= a_reg1_next != a_reg2_next && !a_reg_next_same;
    b_reg_diff <= b_reg1_next != b_reg2_next && !b_reg_next_same;
    o_reg_diff <= o1_next != o2_next && !o_reg_next_same;
    counter_diff <= counter1_next != counter2_next && !counter_next_same;
    busy_diff <= busy1_next != busy2_next && !busy_next_same;
    finish_diff <= finish1_next != finish2_next && !finish_next_same;
end

// always @(posedge clk) begin
//     a_reg_diff <= (pause_1 || pause_2) || !a_reg_next_same;
//     b_reg_diff <= (pause_1 || pause_2) || !b_reg_next_same;
//     o_reg_diff <= (pause_1 || pause_2) || !o_reg_next_same;
//     counter_diff <= (pause_1 || pause_2) || !counter_next_same;
//     busy_diff <= (pause_1 || pause_2) || !busy_next_same;
//     finish_diff <= (pause_1 || pause_2) || !finish_next_same;
// end

// always @(posedge clk) begin
//     a_reg_diff <= (pause_1 || pause_2) || !(busy1==busy2 && a_reg1==a_reg2 && a1==a2);
//     b_reg_diff <= (pause_1 || pause_2) || !(busy1==busy2 && b_reg1==b_reg2);
//     o_reg_diff <= (pause_1 || pause_2) || !(busy1==busy2 && o1==o2 && a_reg1==a_reg2 && b_reg1==b_reg2 && counter1==counter2);
//     counter_diff <= (pause_1 || pause_2) || !(busy1==busy2 && counter1==counter2);
//     busy_diff <= (pause_1 || pause_2) || !(busy1==busy2 && finish1==finish2 && (`CT_TIME ? 1 : a_reg1==a_reg2) && b_reg1==b_reg2);
//     finish_diff <= (pause_1 || pause_2) || !(busy1==busy2 && (`CT_TIME ? 1 : a_reg1==a_reg2) && b_reg1==b_reg2);
// end



MUL copy1(
    .clk(clk),
    .in_valid(in_valid),
    .a(a1),
    .b(b),
    .o(o1),
    .out_valid(out_valid1),
    .a_reg(a_reg1),
    .b_reg(b_reg1),
    .counter(counter1),
    .busy(busy1),
    .finish(finish1),
    .a_reg_next(a_reg1_next),
    .b_reg_next(b_reg1_next),
    .o_reg_next(o1_next),
    .counter_next(counter1_next),
    .busy_next(busy1_next),
    .finish_next(finish1_next),
    .a_reg_same(0),
    .b_reg_same(0),
    .o_reg_same(0),
    .counter_same(0),
    .busy_same(0),
    .finish_same(0),
    .pause(pause_1)
);

MUL copy2(
    .clk(clk),
    .in_valid(in_valid),
    .a(a2),
    .b(b),
    .o(o2),
    .out_valid(out_valid2),
    .a_reg(a_reg2),
    .b_reg(b_reg2),
    .counter(counter2),
    .busy(busy2),
    .finish(finish2),
    .a_reg_next(a_reg2_next),
    .b_reg_next(b_reg2_next),
    .o_reg_next(o2_next),
    .counter_next(counter2_next),
    .busy_next(busy2_next),
    .finish_next(finish2_next),
    .a_reg_same(`SHORTCUT ? a_reg_next_same : 0),
    .b_reg_same(`SHORTCUT ? b_reg_next_same : 0),
    .o_reg_same(`SHORTCUT ? o_reg_next_same : 0),
    .counter_same(`SHORTCUT ? counter_next_same : 0),
    .busy_same(`SHORTCUT ? busy_next_same : 0),
    .finish_same(`SHORTCUT ? finish_next_same : 0),
    .a_reg_sc(a_reg1_next),
    .b_reg_sc(b_reg1_next),
    .o_reg_sc(o1_next),
    .counter_sc(counter1_next),
    .busy_sc(busy1_next),
    .finish_sc(finish1_next),
    .pause(pause_2)
);

// Pausing Logic
wire pause_1, pause_2;
reg pause_1_reg, pause_2_reg;
reg drained;
always @(posedge clk) begin
    pause_1_reg <= out_valid1 && !out_valid2;
    pause_2_reg <= out_valid2 && !out_valid1;
    drained <= pause_1_reg && out_valid2 || pause_2_reg && out_valid1;
end
assign pause_1 = `SYNC && out_valid1 && !out_valid2;
assign pause_2 = `SYNC && out_valid2 && !out_valid1;

// Assumption
reg o_ever_diff = 0;
wire o_ever_diff_in = !(o1==o2) && out_valid1 && out_valid2 || o_ever_diff;
always @(posedge clk) begin
    o_ever_diff <= o_ever_diff_in;
end


// Assertion

reg out_valid_ever_diff = 0;
wire out_valid_ever_diff_in = out_valid1 != out_valid2 || out_valid_ever_diff;
always @(posedge clk) begin
    out_valid_ever_diff <= out_valid_ever_diff_in;
end

`ifdef FOUR_TRACE_PROP
assert property (!(out_valid_ever_diff_in && !o_ever_diff && drained));
`else
assert property (finish1 == finish2 || assume_1_in);
`endif

reg assume_1 = 0;
wire assume_1_in = (a1!=a2 && b!=0) || assume_1;
always @(posedge clk) begin
    assume_1 <= assume_1_in;
end


endmodule


// Shift-and-Add multiplier
module MUL(
    input clk,
    input in_valid,
    input [`WIDTH-1:0] a,
    input [`WIDTH-1:0] b,
    output [`OUT_WIDTH-1:0] o,
    output out_valid,
    output in_ready,
    output busy,
    output finish,
    output [`WIDTH-1:0] a_reg,
    output [`WIDTH-1:0] b_reg,
    output [`WIDTH_LOG:0] counter,
    output busy_next,
    output finish_next,
    output [`WIDTH-1:0] a_reg_next,
    output [`WIDTH-1:0] b_reg_next,
    output [`OUT_WIDTH-1:0] o_reg_next,
    output [`WIDTH_LOG:0] counter_next,
    // shortcut logic
    input a_reg_same,
    input b_reg_same,
    input o_reg_same,
    input counter_same,
    input busy_same,
    input finish_same,
    input [`WIDTH-1:0] a_reg_sc,
    input [`WIDTH-1:0] b_reg_sc,
    input [`OUT_WIDTH-1:0] o_reg_sc,
    input [`WIDTH_LOG:0] counter_sc,
    input busy_sc,
    input finish_sc,
    input pause
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
    end

    wire busy_next = pause ? busy : in_valid && !busy || !finish_next && busy;
    wire finish_next = pause ? finish : ((a_reg == 0 && !`CT_TIME)||(b_reg == 0)) && busy;
    wire [`WIDTH-1:0] a_reg_next = pause ? a_reg : !busy ? a : a_reg;
    wire [`WIDTH-1:0] b_reg_next = pause ? b_reg : !busy ? b : b_reg >> 1;
    wire [`WIDTH_LOG:0] counter_next = pause ? counter : !busy ? 0 : counter + 1;
    wire [`OUT_WIDTH-1:0] o_reg_next = pause ? o_reg : !busy ? 0 : o_reg + (b_reg[0] ? a_reg << counter : 0);


// Shortcutiing logic
    always @(posedge clk) begin
        finish <= finish_same ? finish_sc : finish_next;
        busy <= busy_same ? busy_sc : busy_next;
        a_reg <= a_reg_same ? a_reg_sc : a_reg_next;
        b_reg <= b_reg_same ? b_reg_sc : b_reg_next;
        counter <= counter_same ? counter_sc : counter_next;
        o_reg <= o_reg_same ? o_reg_sc : o_reg_next;
    end
    
    assign o = o_reg;
    assign out_valid = finish;
    assign in_ready = !busy;
endmodule