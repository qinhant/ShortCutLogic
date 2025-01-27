`define WIDTH_LOG 1
`define WIDTH (1 << `WIDTH_LOG)
`define OUT_WIDTH (`WIDTH << 1)

// Shift-and-Add multiplier
module MUL(
    input clk,
    input in_valid,
    input stall,
    input [`WIDTH-1:0] a,
    input [`WIDTH-1:0] b,
    output [`WIDTH-1:0] a_reg,
    output [`WIDTH-1:0] b_reg,
    output [`OUT_WIDTH-1:0] o,
    output out_valid,
    output [`WIDTH-1:0] a_reg_next,
    output [`WIDTH-1:0] b_reg_next,
    output [`OUT_WIDTH-1:0] o_reg_next,
    output finish_next
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

module top(in_a, in_in_valid, in_b_1, in_b_2, in_clk, trigger, cmp_out_valid, cmp_o);
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
  input [`WIDTH-1:0] in_b_1;
  wire [`WIDTH-1:0] in_b_1;
  input [`WIDTH-1:0] in_b_2;
  wire [`WIDTH-1:0] in_b_2;
  input [`WIDTH-1:0] in_a;
  wire [`WIDTH-1:0] in_a;
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

  // Additional predicate
  reg shortcut_nonzero_a1 = 0;
  reg shortcut_nonzero_b1 = 0;
  reg shortcut_nonzero_o1 = 0;
  reg shortcut_nonzero_a2 = 0;
  reg shortcut_nonzero_b2 = 0;
  reg shortcut_nonzero_o2 = 0;
  reg shortcut_finish_imply1 = 0;

  always @(posedge in_clk) begin
    shortcut_nonzero_a1 <= a_reg1_next != 0;
    shortcut_nonzero_b1 <= b_reg1_next != 0;
    shortcut_nonzero_o1 <= o_reg1_next != 0;
    shortcut_nonzero_a2 <= a_reg2_next != 0;
    shortcut_nonzero_b2 <= b_reg2_next != 0;
    shortcut_nonzero_o2 <= o_reg2_next != 0;
    shortcut_finish_imply1 <= finish_1_next && (a_reg1_next != 0 || b_reg1_next != 0);
    shortcut_finish_imply2 <= finish_2_next && (a_reg2_next != 0 || b_reg2_next != 0);
  end

  reg nonzero_predicate_violate;
  wire assume_nonzero_violate;

  assign assume_nonzero_violate = (!shortcut_nonzero_a1 && (a_reg1 != 0)) || (!shortcut_nonzero_b1 && (b_reg1 != 0))
                         || (!shortcut_nonzero_o1 && (o_reg1 != 0)) || (!shortcut_nonzero_a2 && (a_reg2 != 0))
                         || (!shortcut_nonzero_b2 && (b_reg2 != 0)) || (!shortcut_nonzero_o2 && (o_reg2 != 0))
                         || (!shortcut_finish_imply1 && (finish_1 && (a_reg1 != 0 || b_reg1 != 0))) 
                         || (!shortcut_finish_imply2 && (finish_2 && (a_reg2 != 0 || b_reg2 != 0))) 
                         || nonzero_predicate_violate;

  always @(posedge in_clk) begin
    nonzero_predicate_violate <= assume_nonzero_violate;
  end

  wire [`WIDTH-1: 0] a_reg1, a_reg2, b_reg1, b_reg2, a_reg1_next, a_reg2_next, b_reg1_next, b_reg2_next;
  wire [`OUT_WIDTH-1: 0] o_reg1, o_reg2, o_reg1_next, o_reg2_next;
  wire finish_1, finish_2, finish_1_next, finish_2_next;

  assign o_reg1 = copy1_o;
  assign o_reg2 = copy2_o;
  assign finish_1 = copy1_out_valid;
  assign finish_2 = copy2_out_valid;

  MUL copy1 (
    .a(in_a),
    .b(in_b_1),
    .stall(stall_1),
    .clk(in_clk),
    .in_valid(in_in_valid),
    .o(copy1_o),
    .out_valid(copy1_out_valid),
    .a_reg(a_reg1),
    .b_reg(b_reg1),
    .a_reg_next(a_reg1_next),
    .b_reg_next(b_reg1_next),
    .o_reg_next(o_reg1_next),
    .finish_next(finish_1_next)
  );
  MUL copy2 (
    .a(in_a),
    .b(in_b_2),
    .stall(stall_2),
    .clk(in_clk),
    .in_valid(in_in_valid),
    .o(copy2_o),
    .out_valid(copy2_out_valid),
    .a_reg(a_reg2),
    .b_reg(b_reg2),
    .a_reg_next(a_reg2_next),
    .b_reg_next(b_reg2_next),
    .o_reg_next(o_reg2_next),
    .finish_next(finish_2_next)
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
