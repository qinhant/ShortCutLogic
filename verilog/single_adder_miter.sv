module adder(
    input_a, input_b,
    input_a_stb, input_b_stb,
    output_z_ack,
    clk, rst,
    output_z, output_z_stb,
    input_a_ack, input_b_ack
);

  /* ────────── ports ────────── */
  input  clk, rst;
  input  [31:0] input_a, input_b;
  input  input_a_stb, input_b_stb, output_z_ack;
  output input_a_ack, input_b_ack;
  output [31:0] output_z;
  output output_z_stb;

  /* ───── hand‑shake regs ───── */
  reg s_input_a_ack, s_input_b_ack, s_output_z_stb;
  assign input_a_ack  = s_input_a_ack;
  assign input_b_ack  = s_input_b_ack;
  assign output_z_stb = s_output_z_stb;
  assign output_z     = {z_31_reg, z_30_23_reg, z_22_0_reg};

  /* ─── FSM states (unchanged) ─── */
  reg [3:0] state;
  localparam get_a=4'd0,get_b=4'd1,unpack=4'd2,special_cases=4'd3,
             align=4'd4,add_0=4'd5,add_1=4'd6,normalise_1=4'd7,
             normalise_2=4'd8,round=4'd9,pack=4'd10,put_z=4'd11;

  /* ───── untouched whole regs ──── */
  reg [31:0] a, b;
  reg [23:0] z_m;
  reg [9:0]  a_e, b_e, z_e;
  reg        a_s, b_s, z_s;
  reg        guard, round_bit, sticky;
  reg [27:0] sum;

  /* ───── split registers ───── */
  /* z */
  reg z_31_reg;
  reg [7:0]  z_30_23_reg;
  reg [22:0] z_22_0_reg;

  /* a_m and b_m */
  reg        a_m_26_reg, a_m_0_reg;
  reg [25:1] a_m_25_1_reg;
  reg        b_m_26_reg, b_m_0_reg;
  reg [25:1] b_m_25_1_reg;

  /* helpers: full mantissas */
  wire [26:0] a_m_full = {a_m_26_reg, a_m_25_1_reg, a_m_0_reg};
  wire [26:0] b_m_full = {b_m_26_reg, b_m_25_1_reg, b_m_0_reg};

  /* ───────── datapath ───────── */
  always @(posedge clk) begin
    case (state)
      /* get A */
      get_a: begin
        s_input_a_ack <= 1;
        if (s_input_a_ack && input_a_stb) begin
          a <= input_a;
          s_input_a_ack <= 0;
          state <= get_b;
        end
      end

      /* get B */
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
        /* build 27‑bit mantissas {orig[22:0], 3'b0} */
        {a_m_26_reg, a_m_25_1_reg, a_m_0_reg} <= {a[22:0], 3'd0};
        {b_m_26_reg, b_m_25_1_reg, b_m_0_reg} <= {b[22:0], 3'd0};
        a_e <= a[30:23] - 127;
        b_e <= b[30:23] - 127;
        a_s <= a[31];
        b_s <= b[31];
        state <= special_cases;
      end

      /* special cases (only lines that touched slices are changed) */
      special_cases: begin
        if ((a_e==128 && a_m_full!=0) || (b_e==128 && b_m_full!=0)) begin
          z_31_reg<=1; z_30_23_reg<=8'hFF; z_22_0_reg<=23'h400000;
          state<=put_z;
        end
        else if (a_e==128) begin
          z_31_reg<=a_s; z_30_23_reg<=8'hFF; z_22_0_reg<=0;
          if (b_e==128 && a_s!=b_s) z_31_reg<=b_s, z_22_0_reg<=23'h400000;
          state<=put_z;
        end
        else if (b_e==128) begin
          z_31_reg<=b_s; z_30_23_reg<=8'hFF; z_22_0_reg<=0; state<=put_z;
        end
        else if (($signed(a_e)==-127 && a_m_full==0) &&
                 ($signed(b_e)==-127 && b_m_full==0)) begin
          z_31_reg<=a_s&b_s; z_30_23_reg<=b_e[7:0]+127; z_22_0_reg<=b_m_full[26:3];
          state<=put_z;
        end
        else if ($signed(a_e)==-127 && a_m_full==0) begin
          z_31_reg<=b_s; z_30_23_reg<=b_e[7:0]+127; z_22_0_reg<=b_m_full[26:3];
          state<=put_z;
        end
        else if ($signed(b_e)==-127 && b_m_full==0) begin
          z_31_reg<=a_s; z_30_23_reg<=a_e[7:0]+127; z_22_0_reg<=a_m_full[26:3];
          state<=put_z;
        end
        else begin
          if ($signed(a_e)==-127) a_e <= -126; else a_m_26_reg <= 1;
          if ($signed(b_e)==-127) b_e <= -126; else b_m_26_reg <= 1;
          state <= align;
        end
      end

      /* align */
      align: begin
        if ($signed(a_e) > $signed(b_e)) begin
          b_e <= b_e + 1;
          {b_m_26_reg, b_m_25_1_reg, b_m_0_reg} <=
              {1'b0, b_m_full[26:1]};        // >>1
          b_m_0_reg <= b_m_0_reg | b_m_25_1_reg[1];
        end
        else if ($signed(a_e) < $signed(b_e)) begin
          a_e <= a_e + 1;
          {a_m_26_reg, a_m_25_1_reg, a_m_0_reg} <=
              {1'b0, a_m_full[26:1]};
          a_m_0_reg <= a_m_0_reg | a_m_25_1_reg[1];
        end
        else state <= add_0;
      end

      /* add_0 */
      add_0: begin
        z_e <= a_e;
        if (a_s==b_s) begin
          sum <= a_m_full + b_m_full; z_s <= a_s;
        end else if (a_m_full>=b_m_full) begin
          sum <= a_m_full - b_m_full; z_s <= a_s;
        end else begin
          sum <= b_m_full - a_m_full; z_s <= b_s;
        end
        state <= add_1;
      end

      /* add_1: unchanged except uses `sum[...]` (whole‑word) */
      add_1: begin
        if (sum[27]) begin
          z_m <= sum[27:4];
          guard <= sum[3]; round_bit <= sum[2]; sticky <= sum[1]|sum[0];
          z_e <= z_e + 1;
        end else begin
          z_m <= sum[26:3];
          guard <= sum[2]; round_bit <= sum[1]; sticky <= sum[0];
        end
        state <= normalise_1;
      end

      /* normalise_1, normalise_2, round – unchanged logic */

      normalise_1: begin
        if (!z_m[23] && $signed(z_e)>-126) begin
          z_e <= z_e-1;
          {z_m, guard} <= {z_m, guard} << 1;
          round_bit <= 0;
        end else state <= normalise_2;
      end

      normalise_2: begin
        if ($signed(z_e)<-126) begin
          z_e <= z_e+1;
          {guard, z_m} <= {z_m[0], z_m>>1};
          round_bit <= guard;
          sticky <= sticky|round_bit;
        end else state <= round;
      end

      round: begin
        if (guard && (round_bit|sticky|z_m[0])) begin
          z_m <= z_m + 1;
          if (z_m==24'hffffff) z_e <= z_e + 1;
        end
        state <= pack;
      end

      /* pack – writes to z_* regs */
      pack: begin
        z_22_0_reg  <= z_m[22:0];
        z_30_23_reg <= z_e[7:0] + 127;
        z_31_reg    <= z_s;
        if ($signed(z_e)==-126 && !z_m[23]) z_30_23_reg <= 0;
        if ($signed(z_e)==-126 && z_m==24'h0) z_31_reg <= 0;
        if ($signed(z_e)>127) begin
          z_22_0_reg<=0; z_30_23_reg<=8'hFF;
        end
        state <= put_z;
      end

      put_z: begin
        s_output_z_stb <= 1;
        if (s_output_z_stb && output_z_ack) begin
          s_output_z_stb <= 0;
          state <= get_a;
        end
      end
    endcase

    if (rst) begin
      state <= get_a;
      s_input_a_ack <= 0;
      s_input_b_ack <= 0;
      s_output_z_stb <= 0;
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


adder copy1 (
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

adder copy2 (
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