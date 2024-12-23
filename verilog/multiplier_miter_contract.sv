`define WIDTH_LOG 2
`define WIDTH (1 << `WIDTH_LOG)
`define OUT_WIDTH (`WIDTH << 1)

// Shift-and-Add multiplier
module MUL(
    input clk,
    input in_valid,
    input stall,
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
        finish <= stall ? finish: finish_next;
        busy <= stall ? busy : busy_next;
        a_reg <= stall ? a_reg : a_reg_next;
        b_reg <= stall ? b_reg : b_reg_next;
        counter <= stall ? counter : counter_next;
        o_reg <= stall ? o_reg : o_reg_next;
    end

    assign o = o_reg;
    assign out_valid = finish;
endmodule

module top(in_a_1, in_a_2, in_in_valid, in_b, in_clk, trigger, cmp_out_valid, cmp_o);
  wire _0_;
  wire _1_;
  wire _2_;
  output cmp_o;
  wire cmp_o;
  output cmp_out_valid;
  wire cmp_out_valid;
  wire [`OUT_WIDTH-1:0] copy2_o;
  wire copy2_out_valid;
  wire [`OUT_WIDTH-1:0] copy1_o;
  wire copy1_out_valid;
  input [`WIDTH-1:0] in_b;
  wire [`WIDTH-1:0] in_b;
  input [`WIDTH-1:0] in_a_1;
  input [`WIDTH-1:0] in_a_2;
  wire [`WIDTH-1:0] in_a_1;
  wire [`WIDTH-1:0] in_a_2;
  input in_clk;
  wire in_clk;
  input in_in_valid;
  wire in_in_valid;
  output trigger;
  wire trigger;


  // Contract Shadow Logic
  wire stall_1, stall_2;
  reg drained;
  reg uarch_deviated;
  wire isa_deviated;

  assign stall_1 = copy1_out_valid && !copy2_out_valid;
  assign stall_2 = copy2_out_valid && !copy1_out_valid;
  assign isa_deviated = (copy1_out_valid && copy2_out_valid && (copy1_o != copy2_o)); 
  always @(posedge in_clk) begin
    if (uarch_deviated && copy1_out_valid && copy2_out_valid) begin
      drained <= 1;
    end
    if (copy1_out_valid != copy2_out_valid)
      uarch_deviated <= 1;
  end

  

  assign _0_ = copy1_o === copy2_o;
  assign _1_ = copy1_out_valid === copy2_out_valid;
  assign _2_ = & { _1_, _0_ };
  assign trigger = ~ _2_;
  MUL copy1 (
    .a(in_a_1),
    .b(in_b),
    .stall(stall_1),
    .clk(in_clk),
    .in_valid(in_in_valid),
    .o(copy1_o),
    .out_valid(copy1_out_valid)
  );
  MUL copy2 (
    .a(in_a_2),
    .b(in_b),
    .stall(stall_2),
    .clk(in_clk),
    .in_valid(in_in_valid),
    .o(copy2_o),
    .out_valid(copy2_out_valid)
  );
  assign cmp_o = _0_;
  assign cmp_out_valid = _1_;

  
  reg assume_1_violate;
  wire assume_1_violate_in;
  assign assume_1_violate_in = assume_1_violate || isa_deviated;
  always @(posedge in_clk) begin
    assume_1_violate <= assume_1_violate_in;
  end

  wire assume_violate;
  assign assume_violate = assume_1_violate_in;

  assert property (!(uarch_deviated && drained) || assume_violate);
endmodule
