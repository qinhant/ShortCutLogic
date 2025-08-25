`define NUM_WIDTH 8
`define LOGIC_LOW 0
`define LOGIC_HIGH 1
`define ENABLE 1
`define DISABLE 0

module gcd_controller (

  input clk,
  input rst,
  /*input signals to controller*/
  input start,
  input [1:0] compare_st,
  /*output signals from controller*/
  output ld_A,
  output ld_B,
  output MUXA,
  output MUXB,
  output res_en,
  /*GCD finished operation signals*/
  output GCD_done
);

parameter state_reg_width = 3;
parameter [state_reg_width - 1 :0] start_polling_state = 0,
                                   load_input_state = 1,
                                   Is_A_equal_B_state = 2,
                                   A_gt_B_state = 3,
                                   A_lt_B_state = 4,
                                   A_eq_B_state = 5;
    
reg [state_reg_width - 1 :0] curr_state;
reg [state_reg_width - 1 :0] next_state;

/*compare states*/
parameter [1:0] greater = 0,
                smaller = 1,
                equal = 2,
                notequal = 3;

/*State register*/
always @(posedge clk) begin
  if(rst) begin
        curr_state <= start_polling_state;
    end
    else begin
        curr_state <= next_state; 
    end
end

assign MUXA = (curr_state==load_input_state) ? `LOGIC_HIGH: (curr_state==A_gt_B_state) ? `LOGIC_LOW: `LOGIC_HIGH;
assign MUXB = (curr_state==load_input_state) ? `LOGIC_HIGH: (curr_state==A_lt_B_state) ? `LOGIC_LOW: `LOGIC_HIGH;
assign ld_A = (curr_state==load_input_state) ? `LOGIC_HIGH: (curr_state==A_gt_B_state) ? `LOGIC_HIGH: `LOGIC_LOW;
assign ld_B = (curr_state==load_input_state) ? `LOGIC_HIGH: (curr_state==A_lt_B_state) ? `LOGIC_HIGH: `LOGIC_LOW;
assign res_en = (curr_state==A_eq_B_state) ? `ENABLE: `DISABLE;
assign GCD_done = (curr_state==A_eq_B_state) ? `ENABLE: `DISABLE;
assign next_state = (curr_state==start_polling_state) ? ((start == `LOGIC_HIGH) ? load_input_state: start_polling_state):
                    (curr_state==load_input_state) ? Is_A_equal_B_state:
                    (curr_state==Is_A_equal_B_state) ? ((compare_st == equal) ? A_eq_B_state: (compare_st == greater) ? A_gt_B_state: A_lt_B_state):
                    (curr_state==A_eq_B_state) ? start_polling_state:
                    (curr_state==A_gt_B_state) ? Is_A_equal_B_state:
                    (curr_state==A_lt_B_state) ? Is_A_equal_B_state: 
                    curr_state;


endmodule

module gcd_dp #( 
    parameter number_width = 16
)(
   input clk, rst,
  /*Input values*/  
  input [number_width - 1 : 0 ] A,
  input [number_width - 1 : 0 ] B,
  /*Input signals from controller*/
  input ld_A,
  input ld_B,
  input MUXA,
  input MUXB,
  input res_en, 
  /* Outputs of datapath */
  output [1:0] compare_state,
  output [number_width - 1 : 0 ] res
);

/*Internal connections and regesters*/
reg [number_width - 1 : 0 ] REG_A, REG_B, REG_res;
wire [number_width - 1 : 0 ] MUX_A_out, MUX_B_out;
wire [number_width - 1 : 0 ] Subtractor_A_out, Subtractor_B_out, GCD_result;

always @(posedge clk) begin
    if(rst) begin
        REG_A <=0;
        REG_B <=0;
        REG_res <=0;
    end
    else begin
        if(ld_A == 1)begin
            REG_A <= MUX_A_out;
        end
        if(ld_B == 1)begin
            REG_B <= MUX_B_out;
        end
        if(res_en == 1) begin
            REG_res <= GCD_result;
        end
    end
end

assign res = REG_res;
/*compare states*/
localparam [1:0] greater = 0,
                smaller = 1,
                equal = 2,
                notequal = 3;

/*REG_A and REG_B MUXS */
assign MUX_A_out = (MUXA == 1)? A : Subtractor_A_out;
assign MUX_B_out = (MUXB == 1)? B : Subtractor_B_out;

/*Subtractors */
assign Subtractor_A_out = REG_A - REG_B;
assign Subtractor_B_out = REG_B - REG_A;

/*Comparator*/
gcd_dp_comparator #(number_width) comparator (
    .comp1(REG_A),
    .comp2(REG_B),
    .compare_result(compare_state),
    .res(GCD_result)
);

endmodule

module gcd_dp_comparator #( 
    parameter number_width = 16
)(
    input [number_width - 1 : 0 ] comp1,
    input [number_width - 1 : 0 ] comp2,
    output [1:0] compare_result,
    output [number_width - 1 : 0 ] res
);

/*compare states*/
parameter [1:0] greater = 0,
                smaller = 1,
                equal = 2,
                notequal = 3;

assign compare_result = (comp1 == comp2) ? equal: (comp1 < comp2) ? smaller: (comp1 > comp2) ? greater: notequal;
assign res = (comp1 == comp2) ? comp1: 0;

endmodule

module gcd_top #( 
    parameter number_width = 16
)(
  input clk,
  input rst,
  input gcd_start,
  input [number_width - 1 : 0 ] A_in,
  input [number_width - 1 : 0 ] B_in,
  output [number_width - 1 : 0 ] res,
  output GCD_done

);

/*Interconnection definitions*/
wire ld_A_top;
wire ld_B_top;
wire MUXA_top;
wire MUXB_top;
wire res_en_top;
wire [1:0] compare_signal;


/*Instantiation*/ 
gcd_controller fsm_controller (
    .clk(clk),
    .rst(rst),
  /*input signals to controller*/
  .start(gcd_start),
  .compare_st(compare_signal),
  /*output signals from controller*/
  .ld_A(ld_A_top),
  .ld_B(ld_B_top),
  .MUXA(MUXA_top),
  .MUXB(MUXB_top),
  .res_en(res_en_top),
  /*GCD finished operation signals*/
  .GCD_done(GCD_done)
);

  gcd_dp #(.number_width(number_width)) datapath (
    .clk(clk), 
    .rst(rst),
  /*Input values*/  
  .A(A_in),
  .B(B_in),
  /*Input signals from controller*/
  .ld_A(ld_A_top),
  .ld_B(ld_B_top),
  .MUXA(MUXA_top),
  .MUXB(MUXB_top),
  .res_en(res_en_top),
  /* Outputs of datapath */
  .compare_state(compare_signal),
  .res(res)
);
    
endmodule

module top(
    input clock,    
	input reset, 
    input gcd_start,
	input [`NUM_WIDTH - 1 : 0 ] A_in,
    input [`NUM_WIDTH - 1 : 0 ] B_in_1,
    input [`NUM_WIDTH - 1 : 0 ] B_in_2
);

wire finish_1, finish_2;
wire [`NUM_WIDTH-1: 0] res1, res2;

gcd_top #(.number_width(`NUM_WIDTH))  copy1(
    .clk(clock),
    .rst(reset),
    .gcd_start(gcd_start),
    .A_in(A_in),
    .B_in(B_in_1),
    .GCD_done(finish_1),
    .res(res1)
);

gcd_top #(.number_width(`NUM_WIDTH)) copy2(
    .clk(clock),
    .rst(reset),
    .gcd_start(gcd_start),
    .A_in(A_in),
    .B_in(B_in_2),
    .GCD_done(finish_2),
    .res(res2)
);

reg assume_1_violate;
wire assume_1_violate_in;
// assign assume_1_violate_in = assume_1_violate || !((A_in > B_in_1 && A_in == B_in_1 << 1) && (A_in < B_in_2 && B_in_2 == A_in << 1) ) ;
// assign assume_1_violate_in = assume_1_violate || (B_in_1 != B_in_2);
assign assume_1_violate_in = assume_1_violate || (!((A_in > B_in_1 && A_in == B_in_1 << 1) && (A_in < B_in_2 && B_in_2 == A_in << 1) ) && !((A_in > B_in_2 && A_in == B_in_2 << 1) && (A_in < B_in_1 && B_in_1 == A_in << 1) )) ;

always @(posedge clock) begin
  assume_1_violate <= assume_1_violate_in;
end

wire assume_violate;
assign assume_violate = `ASSUME_ON ? assume_1_violate_in : 0;

assert property (finish_1 == finish_2 || assume_violate);

endmodule