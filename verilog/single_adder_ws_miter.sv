module adder(
        input_a,
        input_b,
        input_a_stb,
        input_b_stb,
        output_z_ack,
        clk,
        rst,
        output_z,
        output_z_stb,
        input_a_ack,
        input_b_ack);

  input     clk;
  input     rst;

  input     [31:0] input_a;
  input     input_a_stb;
  output    input_a_ack;

  input     [31:0] input_b;
  input     input_b_stb;
  output    input_b_ack;

  output    [31:0] output_z;
  output    output_z_stb;
  input     output_z_ack;

  reg       s_output_z_stb;
  reg       [31:0] s_output_z;
  reg       s_input_a_ack;
  reg       s_input_b_ack;

  reg       [3:0] state;
  parameter get_a         = 4'd0,
            get_b         = 4'd1,
            unpack        = 4'd2,
            special_cases = 4'd3,
            align         = 4'd4,
            add_0         = 4'd5,
            add_1         = 4'd6,
            normalise_1   = 4'd7,
            normalise_2   = 4'd8,
            round         = 4'd9,
            pack          = 4'd10,
            put_z         = 4'd11;

  reg       [31:0] a, b;
  reg       [26:0] a_m, b_m;
  reg       [23:0] z_m;
  reg       [9:0] a_e, b_e, z_e;
  reg       a_s, b_s, z_s;
  reg       guard, round_bit, sticky;
  reg       [27:0] sum;

  // Registers for slices
  reg z_31_reg;
  reg [7:0] z_30_23_reg;
  reg [22:0] z_22_0_reg;

  always @(posedge clk)
  begin

    case(state)

      get_a:
      begin
        s_input_a_ack <= 1;
        if (s_input_a_ack && input_a_stb) begin
          a <= input_a;
          s_input_a_ack <= 0;
          state <= get_b;
        end
      end

      get_b:
      begin
        s_input_b_ack <= 1;
        if (s_input_b_ack && input_b_stb) begin
          b <= input_b;
          s_input_b_ack <= 0;
          state <= unpack;
        end
      end

      unpack:
      begin
        a_m <= {a[22 : 0], 3'd0};
        b_m <= {b[22 : 0], 3'd0};
        a_e <= a[30 : 23] - 127;
        b_e <= b[30 : 23] - 127;
        a_s <= a[31];
        b_s <= b[31];
        state <= special_cases;
      end

      special_cases:
      begin
        if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
          z_31_reg <= 1;
          z_30_23_reg <= 255;
          z_22_0_reg <= {1'b1, 22'd0};
          state <= put_z;
        end else if (a_e == 128) begin
          z_31_reg <= a_s;
          z_30_23_reg <= 255;
          z_22_0_reg <= 23'd0;
          if ((b_e == 128) && (a_s != b_s)) begin
              z_31_reg <= b_s;
              z_30_23_reg <= 255;
              z_22_0_reg <= {1'b1, 22'd0};
          end
          state <= put_z;
        end else if (b_e == 128) begin
          z_31_reg <= b_s;
          z_30_23_reg <= 255;
          z_22_0_reg <= 23'd0;
          state <= put_z;
        end else if ((($signed(a_e) == -127) && (a_m == 0)) && (($signed(b_e) == -127) && (b_m == 0))) begin
          z_31_reg <= a_s & b_s;
          z_30_23_reg <= b_e[7:0] + 127;
          z_22_0_reg <= b_m[26:3];
          state <= put_z;
        end else if (($signed(a_e) == -127) && (a_m == 0)) begin
          z_31_reg <= b_s;
          z_30_23_reg <= b_e[7:0] + 127;
          z_22_0_reg <= b_m[26:3];
          state <= put_z;
        end else if (($signed(b_e) == -127) && (b_m == 0)) begin
          z_31_reg <= a_s;
          z_30_23_reg <= a_e[7:0] + 127;
          z_22_0_reg <= a_m[26:3];
          state <= put_z;
        end else begin
          if ($signed(a_e) == -127) begin
            a_e <= -126;
          end else begin
            a_m[26] <= 1;
          end
          if ($signed(b_e) == -127) begin
            b_e <= -126;
          end else begin
            b_m[26] <= 1;
          end
          state <= align;
        end
      end

      align:
      begin
        if ($signed(a_e) > $signed(b_e)) begin
          b_e <= b_e + 1;
          b_m <= b_m >> 1;
          b_m[0] <= b_m[0] | b_m[1];
        end else if ($signed(a_e) < $signed(b_e)) begin
          a_e <= a_e + 1;
          a_m <= a_m >> 1;
          a_m[0] <= a_m[0] | a_m[1];
        end else begin
          state <= add_0;
        end
      end

      add_0:
      begin
        z_e <= a_e;
        if (a_s == b_s) begin
          sum <= a_m + b_m;
          z_s <= a_s;
        end else begin
          if (a_m >= b_m) begin
            sum <= a_m - b_m;
            z_s <= a_s;
          end else begin
            sum <= b_m - a_m;
            z_s <= b_s;
          end
        end
        state <= add_1;
      end

      add_1:
      begin
        if (sum[27]) begin
          z_m <= sum[27:4];
          guard <= sum[3];
          round_bit <= sum[2];
          sticky <= sum[1] | sum[0];
          z_e <= z_e + 1;
        end else begin
          z_m <= sum[26:3];
          guard <= sum[2];
          round_bit <= sum[1];
          sticky <= sum[0];
        end
        state <= normalise_1;
      end

      normalise_1:
      begin
        if (z_m[23] == 0 && $signed(z_e) > -126) begin
          z_e <= z_e - 1;
          z_m <= z_m << 1;
          z_m[0] <= guard;
          guard <= round_bit;
          round_bit <= 0;
        end else begin
          state <= normalise_2;
        end
      end

      normalise_2:
      begin
        if ($signed(z_e) < -126) begin
          z_e <= z_e + 1;
          z_m <= z_m >> 1;
          guard <= z_m[0];
          round_bit <= guard;
          sticky <= sticky | round_bit;
        end else begin
          state <= round;
        end
      end

      round:
      begin
        if (guard && (round_bit | sticky | z_m[0])) begin
          z_m <= z_m + 1;
          if (z_m == 24'hffffff) begin
            z_e <=z_e + 1;
          end
        end
        state <= pack;
      end

      pack:
      begin
        z_22_0_reg <= z_m[22:0];
        z_30_23_reg <= z_e[7:0] + 127;
        z_31_reg <= z_s;
        if ($signed(z_e) == -126 && z_m[23] == 0) begin
          z_30_23_reg <= 0;
        end
        if ($signed(z_e) == -126 && z_m[23:0] == 24'h0) begin
          z_31_reg <= 1'b0;
        end
        if ($signed(z_e) > 127) begin
          z_22_0_reg <= 0;
          z_30_23_reg <= 255;
          z_31_reg <= z_s;
        end
        state <= put_z;
      end

      put_z:
      begin
        s_output_z_stb <= 1;
        s_output_z <= {z_31_reg, z_30_23_reg, z_22_0_reg};
        if (s_output_z_stb && output_z_ack) begin
          s_output_z_stb <= 0;
          state <= get_a;
        end
      end

    endcase

    if (rst == 1) begin
      state <= get_a;
      s_input_a_ack <= 0;
      s_input_b_ack <= 0;
      s_output_z_stb <= 0;
    end

  end
  assign input_a_ack = s_input_a_ack;
  assign input_b_ack = s_input_b_ack;
  assign output_z_stb = s_output_z_stb;
  assign output_z = s_output_z;

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