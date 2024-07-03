`define WIDTH_LOG 3
`define WIDTH (1 << `WIDTH_LOG)
`define OUT_WIDTH (`WIDTH << 1)
`define CT_TIME 0
`define SHORTCUT 1
`define ASSUME_1 0
`define FOUR_TRACE_PROP

`ifdef FOUR_TRACE_PROP
`define SYNC 1
`else
`define SYNC 0
`endif

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


// wire a_reg_next_same = assume_1_violate_in || (!pause_1 && !pause_2) && (!busy_diff && !a_reg_diff && a1==a2);
// wire b_reg_next_same = assume_1_violate_in || (!pause_1 && !pause_2) && (!busy_diff && !b_reg_diff);
// wire o_reg_next_same = assume_1_violate_in || (!pause_1 && !pause_2) && (!busy_diff && !o_reg_diff && !a_reg_diff && !b_reg_diff && !counter_diff);
// wire counter_next_same = assume_1_violate_in || (!pause_1 && !pause_2) && (!busy_diff && !counter_diff);
// wire busy_next_same = assume_1_violate_in || (!pause_1 && !pause_2) && (!busy_diff && !finish_diff && !(`CT_TIME ? 0 : a_reg_diff) && !b_reg_diff);
// wire finish_next_same = assume_1_violate_in || (!pause_1 && !pause_2) && (!busy_diff && !(`CT_TIME ? 0 : a_reg_diff) && !b_reg_diff);

// wire a_reg_next_same = assume_1_violate_in || assume_2_violate_in;
// wire b_reg_next_same = assume_1_violate_in || assume_2_violate_in;
// wire o_reg_next_same = assume_1_violate_in || assume_2_violate_in;
// wire counter_next_same = assume_1_violate_in || assume_2_violate_in;
// wire busy_next_same = assume_1_violate_in || assume_2_violate_in;
// wire finish_next_same = assume_1_violate_in || assume_2_violate_in;

wire a_reg_next_same = 0;
wire b_reg_next_same = 0;
wire o_reg_next_same = 0;
wire counter_next_same = 0;
wire busy_next_same = 0;
wire finish_next_same = 0;


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
    .a_reg_next_same(0),
    .b_reg_next_same(0),
    .o_reg_next_same(0),
    .counter_next_same(0),
    .busy_next_same(0),
    .finish_next_same(0),
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
    .a_reg_same(`SHORTCUT ? !a_reg_diff : 0),
    .b_reg_same(`SHORTCUT ? !b_reg_diff : 0),
    .o_reg_same(`SHORTCUT ? !o_reg_diff : 0),
    .counter_same(`SHORTCUT ? !counter_diff : 0),
    .busy_same(`SHORTCUT ? !busy_diff : 0),
    .finish_same(`SHORTCUT ? !finish_diff : 0),
    .a_reg_other(a_reg1),
    .b_reg_other(b_reg1),
    .o_reg_other(o1),
    .counter_other(counter1),
    .busy_other(busy1),
    .finish_other(finish1),
    .a_reg_next_same(`SHORTCUT ? a_reg_next_same : 0),
    .b_reg_next_same(`SHORTCUT ? b_reg_next_same : 0),
    .o_reg_next_same(`SHORTCUT ? o_reg_next_same : 0),
    .counter_next_same(`SHORTCUT ? counter_next_same : 0),
    .busy_next_same(`SHORTCUT ? busy_next_same : 0),
    .finish_next_same(`SHORTCUT ? finish_next_same : 0),
    .a_reg_other_next(a_reg1_next),
    .b_reg_other_next(b_reg1_next),
    .o_reg_other_next(o1_next),
    .counter_other_next(counter1_next),
    .busy_other_next(busy1_next),
    .finish_other_next(finish1_next),
    .pause(pause_2)
);

// Pausing Logic
wire pause_1, pause_2;
reg pause_1_reg, pause_2_reg;
reg drained;
always @(posedge clk) begin
    pause_1_reg <= pause_1;
    pause_2_reg <= pause_2;
    drained <= (pause_1_reg && out_valid2 || pause_2_reg && out_valid1);
end
assign pause_1 = `SYNC && out_valid1 && !out_valid2;
assign pause_2 = `SYNC && out_valid2 && !out_valid1;
// assign pause_1 = `SYNC && out_valid1 && !out_valid2 || assume_2_violate_in;
// assign pause_2 = `SYNC && out_valid2 && !out_valid1 || assume_2_violate_in;
// Assumption
reg o_ever_diff = 0;
wire o_ever_diff_in = !(o1==o2) && out_valid1 && out_valid2 || o_ever_diff;
always @(posedge clk) begin
    o_ever_diff <= o_ever_diff_in;
end

reg assume_2_violate = 0;
always @(posedge clk) begin
    assume_2_violate <= assume_2_violate_in;
end
wire assume_2_violate_in = ((res1 != res2)) || assume_2_violate;
wire [`OUT_WIDTH-1:0] res1 = a_reg1 * b_reg1;
wire [`OUT_WIDTH-1:0] res2 = a_reg2 * b_reg2;
// wire assume_2_violate_in = (a_reg1 * b_reg1 != a_reg2 * b_reg2) || assume_2_violate;
// wire assume_2_violate_in = (in_valid && (a1*b != a2*b)) || o_ever_diff_in;


// Assertion

reg out_valid_ever_diff = 0;
wire out_valid_ever_diff_in = out_valid1 != out_valid2 || out_valid_ever_diff;
always @(posedge clk) begin
    out_valid_ever_diff <= out_valid_ever_diff_in;
end



`ifdef FOUR_TRACE_PROP

reg assert_violate = 0;
always @(posedge clk) begin
    assert_violate <= drained && out_valid_ever_diff;
end

assert property (finish1 == finish2 || assume_2_violate_in);

// assert property (!assert_violate || assume_2_violate_in);
`else
assert property (finish1 == finish2 || assume_1_violate_in);
`endif

reg assume_1_violate = 0;
wire assume_1_violate_in = `ASSUME_1 ? (a1!=a2 && b!=0) || assume_1_violate : 0;
always @(posedge clk) begin
    assume_1_violate <= assume_1_violate_in;
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
    input a_reg_next_same,
    input b_reg_next_same,
    input o_reg_next_same,
    input counter_next_same,
    input busy_next_same,
    input finish_next_same,
    input [`WIDTH-1:0] a_reg_other,
    input [`WIDTH-1:0] b_reg_other,
    input [`OUT_WIDTH-1:0] o_reg_other,
    input [`WIDTH_LOG:0] counter_other,
    input busy_other,
    input finish_other,
    input [`WIDTH-1:0] a_reg_other_next,
    input [`WIDTH-1:0] b_reg_other_next,
    input [`OUT_WIDTH-1:0] o_reg_other_next,
    input [`WIDTH_LOG:0] counter_other_next,
    input busy_other_next,
    input finish_other_next,
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

    wire busy_this = busy_same ? busy_other : busy;
    wire finish_this = finish_same ? finish_other : finish;
    wire [`WIDTH-1:0] a_reg_this = a_reg_same ? a_reg_other : a_reg;
    wire [`WIDTH-1:0] b_reg_this = b_reg_same ? b_reg_other : b_reg;
    wire [`WIDTH_LOG:0] counter_this = counter_same ? counter_other : counter;
    wire [`OUT_WIDTH-1:0] o_reg_this = o_reg_same ? o_reg_other : o_reg;

    wire busy_next = pause ? busy_this : in_valid && !busy_this || !finish_next && busy_this;
    wire finish_next = pause ? finish_this : ((a_reg_this == 0 && !`CT_TIME)||(b_reg_this == 0)) && busy_this;
    wire [`WIDTH-1:0] a_reg_next = pause ? a_reg_this : !busy_this ? a : a_reg_this;
    wire [`WIDTH-1:0] b_reg_next = pause ? b_reg_this : !busy_this ? b : b_reg_this >> 1;
    wire [`WIDTH_LOG:0] counter_next = pause ? counter_this : !busy_this ? 0 : counter_this + 1;
    wire [`OUT_WIDTH-1:0] o_reg_next = pause ? o_reg_this : !busy_this ? 0 : o_reg_this + (b_reg_this[0] ? a_reg_this << counter_this : 0);


// Shortcutiing logic
    always @(posedge clk) begin
        finish <= finish_next_same ? finish_other_next : finish_next;
        busy <= busy_next_same ? busy_other_next : busy_next;
        a_reg <= a_reg_next_same ? a_reg_other_next : a_reg_next;
        b_reg <= b_reg_next_same ? b_reg_other_next : b_reg_next;
        counter <= counter_next_same ? counter_other_next : counter_next;
        o_reg <= o_reg_next_same ? o_reg_other_next : o_reg_next;
    end

    // always @(posedge clk) begin
    //     finish <= finish_next;
    //     busy <= busy_next;
    //     a_reg <= a_reg_next;
    //     b_reg <= b_reg_next;
    //     counter <= counter_next;
    //     o_reg <= o_reg_next;
    // end
    
    assign o = o_reg_this;
    assign out_valid = finish_this;
    assign in_ready = !busy_this;
endmodule