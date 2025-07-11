`define WIDTH_LOG 6
`define WIDTH (1 << `WIDTH_LOG)
`define OUT_WIDTH (`WIDTH << 1)

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

module top(in_a, in_in_valid, in_b_1, in_b_2, in_clk, trigger, cmp_out_valid, cmp_o);
  wire _0_;
  wire _1_;
  wire _2_;
  output cmp_o;
  wire cmp_o;
  output cmp_out_valid;
  wire cmp_out_valid;
  wire [`WIDTH<<1-1:0] copy2_o;
  wire copy2_out_valid;
  wire [`WIDTH<<1-1:0] copy1_o;
  wire copy1_out_valid;
  input [`WIDTH-1:0] in_a;
  wire [`WIDTH-1:0] in_a;
  input [`WIDTH-1:0] in_b_1;
  input [`WIDTH-1:0] in_b_2;
  wire [`WIDTH-1:0] in_b_1;
  wire [`WIDTH-1:0] in_b_2;
  input in_clk;
  wire in_clk;
  input in_in_valid;
  wire in_in_valid;
  output trigger;
  wire trigger;
  assign _0_ = copy1_o === copy2_o;
  assign _1_ = copy1_out_valid === copy2_out_valid;
  assign _2_ = & { _1_, _0_ };
  assign trigger = ~ _2_;
  MUL copy1 (
    .a(in_a),
    .b(in_b_1),
    .clk(in_clk),
    .in_valid(in_in_valid),
    .o(copy1_o),
    .out_valid(copy1_out_valid)
  );
  MUL copy2 (
    .a(in_a),
    .b(in_b_2),
    .clk(in_clk),
    .in_valid(in_in_valid),
    .o(copy2_o),
    .out_valid(copy2_out_valid)
  );
  assign cmp_o = _0_;
  assign cmp_out_valid = _1_;

  
  reg assume_1_violate;
  wire assume_1_violate_in;
  assign assume_1_violate_in = assume_1_violate || (in_a != 0 && in_b_1 != in_b_2);
  always @(posedge in_clk) begin
    assume_1_violate <= assume_1_violate_in;
  end

  wire assume_violate;
  assign assume_violate = `ASSUME_ON ? assume_1_violate_in : 0;

  assert property (copy1_out_valid == copy2_out_valid || assume_violate);
  
endmodule
