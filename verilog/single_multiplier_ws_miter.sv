// IEEE‑754 single‑precision floating‑point multiplier – slice‑free
module multiplier(
    input_a, input_b,
    input_a_stb, input_b_stb,
    output_z_ack,
    clk, rst,
    output_z, output_z_stb,
    input_a_ack, input_b_ack
);

  /* ───────── ports ───────── */
  input  clk, rst;
  input  [31:0] input_a, input_b;
  input  input_a_stb, input_b_stb, output_z_ack;
  output input_a_ack, input_b_ack;
  output [31:0] output_z;
  output output_z_stb;

  /* ─ hand‑shake regs ─ */
  reg s_input_a_ack, s_input_b_ack, s_output_z_stb;
  assign input_a_ack  = s_input_a_ack;
  assign input_b_ack  = s_input_b_ack;
  assign output_z_stb = s_output_z_stb;
  assign output_z     = {z_31_reg, z_30_23_reg, z_22_0_reg};

  /* ─ FSM states (unchanged) ─ */
  reg [3:0] state;
  localparam get_a=0,get_b=1,unpack=2,special_cases=3,
             normalise_a=4,normalise_b=5,
             multiply_0=6,multiply_1=7,
             normalise_1=8,normalise_2=9,
             round=10,pack=11,put_z=12;

  /* ─ untouched whole regs ─ */
  reg [31:0] a, b;
  reg [23:0] z_m;
  reg [9:0]  a_e, b_e, z_e;
  reg        a_s, b_s, z_s;
  reg        guard, round_bit, sticky;
  reg [47:0] product;

  /* ─ split regs ─ */
  /* mantissas */
  reg        a_m_23_reg;  reg [22:0] a_m_22_0_reg;
  reg        b_m_23_reg;  reg [22:0] b_m_22_0_reg;
  /* z */
  reg z_31_reg;  reg [7:0] z_30_23_reg;  reg [22:0] z_22_0_reg;

  /* helpers */
  wire [23:0] a_m_full = {a_m_23_reg, a_m_22_0_reg};
  wire [23:0] b_m_full = {b_m_23_reg, b_m_22_0_reg};

  /* ────────────────────── datapath ────────────────────── */
  always @(posedge clk) begin
    case (state)
      /* read A */
      get_a: begin
        s_input_a_ack <= 1;
        if (s_input_a_ack && input_a_stb) begin
          a <= input_a;
          s_input_a_ack <= 0;
          state <= get_b;
        end
      end
      /* read B */
      get_b: begin
        s_input_b_ack <= 1;
        if (s_input_b_ack && input_b_stb) begin
          b <= input_b;
          s_input_b_ack <= 0;
          state <= unpack;
        end
      end
      /* unpack */
      unpack: begin
        {a_m_23_reg, a_m_22_0_reg} <= a[22:0];
        {b_m_23_reg, b_m_22_0_reg} <= b[22:0];
        a_e <= a[30:23]-127; b_e <= b[30:23]-127;
        a_s <= a[31];        b_s <= b[31];
        state <= special_cases;
      end

      /* special cases (update z_* regs) */
      special_cases: begin
        if ((a_e==128 && a_m_full!=0) || (b_e==128 && b_m_full!=0)) begin
          z_31_reg<=1; z_30_23_reg<=8'hFF; z_22_0_reg<=23'h400000; state<=put_z;
        end
        else if (a_e==128) begin
          z_31_reg<=a_s^b_s; z_30_23_reg<=8'hFF; z_22_0_reg<=0;
          if (($signed(b_e)==-127)&&b_m_full==0) begin z_31_reg<=1; z_22_0_reg<=23'h400000; end
          state<=put_z;
        end
        else if (b_e==128) begin
          z_31_reg<=a_s^b_s; z_30_23_reg<=8'hFF; z_22_0_reg<=0;
          if (($signed(a_e)==-127)&&a_m_full==0) begin z_31_reg<=1; z_22_0_reg<=23'h400000; end
          state<=put_z;
        end
        else if (($signed(a_e)==-127)&&a_m_full==0) begin
          z_31_reg<=a_s^b_s; z_30_23_reg<=0; z_22_0_reg<=0; state<=put_z;
        end
        else if (($signed(b_e)==-127)&&b_m_full==0) begin
          z_31_reg<=a_s^b_s; z_30_23_reg<=0; z_22_0_reg<=0; state<=put_z;
        end
        else begin
          if ($signed(a_e)==-127) a_e<=-126; else a_m_23_reg<=1;
          if ($signed(b_e)==-127) b_e<=-126; else b_m_23_reg<=1;
          state<=normalise_a;
        end
      end

      /* normalise_a / _b */
      normalise_a: begin
        if (a_m_23_reg) state<=normalise_b;
        else begin
          {a_m_23_reg,a_m_22_0_reg} <= {a_m_full,1'b0};
          a_e<=a_e-1;
        end
      end
      normalise_b: begin
        if (b_m_23_reg) state<=multiply_0;
        else begin
          {b_m_23_reg,b_m_22_0_reg} <= {b_m_full,1'b0};
          b_e<=b_e-1;
        end
      end

      /* multiply */
      multiply_0: begin
        z_s <= a_s^b_s;
        z_e <= a_e + b_e + 1;
        product <= a_m_full * b_m_full;
        state <= multiply_1;
      end
      multiply_1: begin
        z_m <= product[47:24];
        guard <= product[23];
        round_bit <= product[22];
        sticky <= |product[21:0];
        state <= normalise_1;
      end

      /* normalise / round */
      normalise_1: begin
        if (!z_m[23]) begin
          z_e<=z_e-1; {z_m,guard}<={z_m,guard}<<1; round_bit<=0;
        end else state<=normalise_2;
      end
      normalise_2: begin
        if ($signed(z_e)<-126) begin
          z_e<=z_e+1; {guard,z_m}<={z_m[0],z_m>>1};
          round_bit<=guard; sticky<=sticky|round_bit;
        end else state<=round;
      end
      round: begin
        if (guard && (round_bit|sticky|z_m[0])) begin
          z_m<=z_m+1; if (z_m==24'hffffff) z_e<=z_e+1;
        end
        state<=pack;
      end

      /* pack */
      pack: begin
        z_22_0_reg  <= z_m[22:0];
        z_30_23_reg <= z_e[7:0]+127;
        z_31_reg    <= z_s;
        if (($signed(z_e)==-126)&&!z_m[23]) z_30_23_reg<=0;
        if ($signed(z_e)>127) begin z_22_0_reg<=0; z_30_23_reg<=8'hFF; end
        state<=put_z;
      end

      put_z: begin
        s_output_z_stb<=1;
        if (s_output_z_stb && output_z_ack) begin
          s_output_z_stb<=0; state<=get_a;
        end
      end
    endcase

    /* async reset */
    if (rst) begin
      state<=get_a;
      s_input_a_ack<=0; s_input_b_ack<=0; s_output_z_stb<=0;
    end
  end
endmodule



module top(
  input     clock,
  input     reset,

  input     [63:0] input_a,
  input     input_a_stb,

  input     [63:0] input_b_1,
  input     [63:0] input_b_2,
  input     input_b_stb,

  input     output_z_ack
);

wire copy1_out_valid, copy2_out_valid;
wire copy1_input_a_ack, copy1_input_b_ack, copy2_input_a_ack, copy2_input_b_ack;


multiplier copy1 (
  .input_a(input_a),
  .input_b(input_b_reg_1),
  .input_a_stb(input_a_stb),
  .input_b_stb(input_b_stb),
  .input_a_ack(copy1_input_a_ack),
  .input_b_ack(copy1_input_b_ack),
  .output_z_ack(output_z_ack),
  .clk(clock),
  .rst(reset),
  .output_z_stb(copy1_out_valid)
);

multiplier copy2 (
  .input_a(input_a),
  .input_b(input_b_reg_2),
  .input_a_stb(input_a_stb),
  .input_b_stb(input_b_stb),
  .input_a_ack(copy2_input_a_ack),
  .input_b_ack(copy2_input_b_ack),
  .output_z_ack(output_z_ack),
  .clk(clock),
  .rst(reset),
  .output_z_stb(copy2_out_valid)
);


  // Assume that if input_a_stb is high and input_a is non-zero, then in the next cycle input_b_stb is high and input_b_1 == input_b_2
  // reg input_a_nonzero_flag = 0;

  // always @(posedge clock) begin
  //     if (copy1_input_a_ack && copy2_input_a_ack && input_a != 0) begin
  //       input_a_nonzero_flag <= 1;
  //     end
  //     else if (copy1_input_b_ack && copy2_input_b_ack) begin
  //       input_a_nonzero_flag <= 0;
  // end
  // end

  reg [31:0] input_b_reg_1, input_b_reg_2;

  always @(posedge clock) begin
    if (input_a_stb && copy1_input_a_ack && copy2_input_a_ack) begin
      input_b_reg_1 <= input_b_1;
      input_b_reg_2 <= input_b_2;
    end
  end

  reg assume_1_violate;
  wire assume_1_violate_in;
  // assign assume_1_violate_in = assume_1_violate || (input_a_nonzero_flag && input_b_1 != input_b_2) || (input_a_nonzero_flag && !input_b_stb);  
  assign assume_1_violate_in = assume_1_violate || (input_a != 0 && input_b_1 != input_b_2);
  always @(posedge clock) begin
    assume_1_violate <= assume_1_violate_in;
  end

  wire assume_violate;
  assign assume_violate = `ASSUME_ON ? assume_1_violate_in : 0;

  assert property (copy1_out_valid == copy2_out_valid || assume_violate);
endmodule