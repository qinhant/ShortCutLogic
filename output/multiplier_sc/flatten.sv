/* Generated by Yosys 0.40+50 (git sha1 0f9ee20ea, clang++ 15.0.0 -fPIC -Os) */

(* keep =  1  *)
(* top =  1  *)
(* src = "verilog/multiplier_sc.sv:5.1-48.10" *)
module top(clk, a1, a2, b, in_valid, o1, o2, out_valid1, out_valid2);
  (* src = "verilog/multiplier_sc.sv:41.30-41.38" *)
  wire _00_;
  (* src = "verilog/multiplier_sc.sv:41.42-41.48" *)
  wire _01_;
  (* src = "verilog/multiplier_sc.sv:46.18-46.42" *)
  wire _02_;
  wire [2:0] _03_;
  wire [7:0] _04_;
  (* src = "verilog/multiplier_sc.sv:80.77-80.93" *)
  (* unused_bits = "8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31" *)
  wire [31:0] _05_;
  (* src = "verilog/multiplier_sc.sv:76.25-76.35" *)
  wire _06_;
  (* src = "verilog/multiplier_sc.sv:76.39-76.49" *)
  wire _07_;
  (* src = "verilog/multiplier_sc.sv:75.34-75.39" *)
  wire _08_;
  (* src = "verilog/multiplier_sc.sv:76.25-76.49" *)
  wire _09_;
  (* src = "verilog/multiplier_sc.sv:80.66-80.97" *)
  wire [31:0] _10_;
  wire [2:0] _11_;
  wire [7:0] _12_;
  (* src = "verilog/multiplier_sc.sv:80.77-80.93" *)
  (* unused_bits = "8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31" *)
  wire [31:0] _13_;
  (* src = "verilog/multiplier_sc.sv:76.25-76.35" *)
  wire _14_;
  (* src = "verilog/multiplier_sc.sv:76.39-76.49" *)
  wire _15_;
  (* src = "verilog/multiplier_sc.sv:75.34-75.39" *)
  wire _16_;
  (* src = "verilog/multiplier_sc.sv:76.25-76.49" *)
  wire _17_;
  (* src = "verilog/multiplier_sc.sv:80.66-80.97" *)
  wire [31:0] _18_;
  (* src = "verilog/multiplier_sc.sv:41.28-41.49" *)
  wire _19_;
  (* src = "verilog/multiplier_sc.sv:41.30-41.48" *)
  wire _20_;
  (* src = "verilog/multiplier_sc.sv:46.18-46.65" *)
  wire _21_;
  (* src = "verilog/multiplier_sc.sv:7.26-7.28" *)
  input [3:0] a1;
  wire [3:0] a1;
  (* src = "verilog/multiplier_sc.sv:8.26-8.28" *)
  input [3:0] a2;
  wire [3:0] a2;
  (* src = "verilog/multiplier_sc.sv:40.5-40.21" *)
  reg assume_1_violate = 1'h0;
  (* src = "verilog/multiplier_sc.sv:41.6-41.25" *)
  wire assume_1_violate_in;
  (* src = "verilog/multiplier_sc.sv:9.26-9.27" *)
  input [3:0] b;
  wire [3:0] b;
  (* src = "verilog/multiplier_sc.sv:6.11-6.14" *)
  input clk;
  wire clk;
  (* hdlname = "copy1 a" *)
  (* src = "verilog/multiplier_sc.sv:55.26-55.27" *)
  wire [3:0] \copy1.a ;
  (* hdlname = "copy1 a_reg" *)
  (* src = "verilog/multiplier_sc.sv:60.24-60.29" *)
  reg [3:0] \copy1.a_reg  = 4'h0;
  (* hdlname = "copy1 a_reg_next" *)
  (* src = "verilog/multiplier_sc.sv:77.25-77.35" *)
  wire [3:0] \copy1.a_reg_next ;
  (* hdlname = "copy1 b" *)
  (* src = "verilog/multiplier_sc.sv:56.26-56.27" *)
  wire [3:0] \copy1.b ;
  (* hdlname = "copy1 b_reg" *)
  (* src = "verilog/multiplier_sc.sv:60.31-60.36" *)
  reg [3:0] \copy1.b_reg  = 4'h0;
  (* hdlname = "copy1 b_reg_next" *)
  (* src = "verilog/multiplier_sc.sv:78.25-78.35" *)
  wire [3:0] \copy1.b_reg_next ;
  (* hdlname = "copy1 busy" *)
  (* src = "verilog/multiplier_sc.sv:62.9-62.13" *)
  reg \copy1.busy  = 1'h0;
  (* hdlname = "copy1 busy_next" *)
  (* src = "verilog/multiplier_sc.sv:75.10-75.19" *)
  wire \copy1.busy_next ;
  (* hdlname = "copy1 clk" *)
  (* src = "verilog/multiplier_sc.sv:53.11-53.14" *)
  wire \copy1.clk ;
  (* hdlname = "copy1 counter" *)
  (* src = "verilog/multiplier_sc.sv:64.15-64.22" *)
  reg [2:0] \copy1.counter ;
  (* hdlname = "copy1 counter_next" *)
  (* src = "verilog/multiplier_sc.sv:79.16-79.28" *)
  wire [2:0] \copy1.counter_next ;
  (* hdlname = "copy1 coutner" *)
  (* src = "verilog/multiplier_sc.sv:72.9-72.16" *)
  wire \copy1.coutner ;
  (* hdlname = "copy1 finish" *)
  (* src = "verilog/multiplier_sc.sv:63.9-63.15" *)
  reg \copy1.finish  = 1'h0;
  (* hdlname = "copy1 finish_next" *)
  (* src = "verilog/multiplier_sc.sv:76.10-76.21" *)
  wire \copy1.finish_next ;
  (* hdlname = "copy1 in_valid" *)
  (* src = "verilog/multiplier_sc.sv:54.11-54.19" *)
  wire \copy1.in_valid ;
  (* hdlname = "copy1 o" *)
  (* src = "verilog/multiplier_sc.sv:57.34-57.35" *)
  wire [7:0] \copy1.o ;
  (* hdlname = "copy1 o_reg" *)
  (* src = "verilog/multiplier_sc.sv:61.31-61.36" *)
  reg [7:0] \copy1.o_reg  = 8'h00;
  (* hdlname = "copy1 o_reg_next" *)
  (* src = "verilog/multiplier_sc.sv:80.32-80.42" *)
  wire [7:0] \copy1.o_reg_next ;
  (* hdlname = "copy1 out_valid" *)
  (* src = "verilog/multiplier_sc.sv:58.12-58.21" *)
  wire \copy1.out_valid ;
  (* hdlname = "copy2 a" *)
  (* src = "verilog/multiplier_sc.sv:55.26-55.27" *)
  wire [3:0] \copy2.a ;
  (* hdlname = "copy2 a_reg" *)
  (* src = "verilog/multiplier_sc.sv:60.24-60.29" *)
  reg [3:0] \copy2.a_reg  = 4'h0;
  (* hdlname = "copy2 a_reg_next" *)
  (* src = "verilog/multiplier_sc.sv:77.25-77.35" *)
  wire [3:0] \copy2.a_reg_next ;
  (* hdlname = "copy2 b" *)
  (* src = "verilog/multiplier_sc.sv:56.26-56.27" *)
  wire [3:0] \copy2.b ;
  (* hdlname = "copy2 b_reg" *)
  (* src = "verilog/multiplier_sc.sv:60.31-60.36" *)
  reg [3:0] \copy2.b_reg  = 4'h0;
  (* hdlname = "copy2 b_reg_next" *)
  (* src = "verilog/multiplier_sc.sv:78.25-78.35" *)
  wire [3:0] \copy2.b_reg_next ;
  (* hdlname = "copy2 busy" *)
  (* src = "verilog/multiplier_sc.sv:62.9-62.13" *)
  reg \copy2.busy  = 1'h0;
  (* hdlname = "copy2 busy_next" *)
  (* src = "verilog/multiplier_sc.sv:75.10-75.19" *)
  wire \copy2.busy_next ;
  (* hdlname = "copy2 clk" *)
  (* src = "verilog/multiplier_sc.sv:53.11-53.14" *)
  wire \copy2.clk ;
  (* hdlname = "copy2 counter" *)
  (* src = "verilog/multiplier_sc.sv:64.15-64.22" *)
  reg [2:0] \copy2.counter ;
  (* hdlname = "copy2 counter_next" *)
  (* src = "verilog/multiplier_sc.sv:79.16-79.28" *)
  wire [2:0] \copy2.counter_next ;
  (* hdlname = "copy2 coutner" *)
  (* src = "verilog/multiplier_sc.sv:72.9-72.16" *)
  wire \copy2.coutner ;
  (* hdlname = "copy2 finish" *)
  (* src = "verilog/multiplier_sc.sv:63.9-63.15" *)
  reg \copy2.finish  = 1'h0;
  (* hdlname = "copy2 finish_next" *)
  (* src = "verilog/multiplier_sc.sv:76.10-76.21" *)
  wire \copy2.finish_next ;
  (* hdlname = "copy2 in_valid" *)
  (* src = "verilog/multiplier_sc.sv:54.11-54.19" *)
  wire \copy2.in_valid ;
  (* hdlname = "copy2 o" *)
  (* src = "verilog/multiplier_sc.sv:57.34-57.35" *)
  wire [7:0] \copy2.o ;
  (* hdlname = "copy2 o_reg" *)
  (* src = "verilog/multiplier_sc.sv:61.31-61.36" *)
  reg [7:0] \copy2.o_reg  = 8'h00;
  (* hdlname = "copy2 o_reg_next" *)
  (* src = "verilog/multiplier_sc.sv:80.32-80.42" *)
  wire [7:0] \copy2.o_reg_next ;
  (* hdlname = "copy2 out_valid" *)
  (* src = "verilog/multiplier_sc.sv:58.12-58.21" *)
  wire \copy2.out_valid ;
  (* src = "verilog/multiplier_sc.sv:10.11-10.19" *)
  input in_valid;
  wire in_valid;
  (* src = "verilog/multiplier_sc.sv:11.34-11.36" *)
  output [7:0] o1;
  wire [7:0] o1;
  (* src = "verilog/multiplier_sc.sv:12.34-12.36" *)
  output [7:0] o2;
  wire [7:0] o2;
  (* src = "verilog/multiplier_sc.sv:13.12-13.22" *)
  output out_valid1;
  wire out_valid1;
  (* src = "verilog/multiplier_sc.sv:14.12-14.22" *)
  output out_valid2;
  wire out_valid2;
  always @* if (1'h1) assert(_21_);
  assign _00_ = a1 == (* src = "verilog/multiplier_sc.sv:41.30-41.38" *) a2;
  assign _01_ = ! (* src = "verilog/multiplier_sc.sv:41.42-41.48" *) b;
  assign _02_ = out_valid1 == (* src = "verilog/multiplier_sc.sv:46.18-46.42" *) out_valid2;
  assign _03_ = \copy1.counter  + (* src = "verilog/multiplier_sc.sv:79.43-79.54" *) 1'h1;
  assign _04_ = \copy1.o_reg  + (* src = "verilog/multiplier_sc.sv:80.57-80.98" *) _10_[7:0];
  assign _06_ = ! (* src = "verilog/multiplier_sc.sv:76.25-76.35" *) \copy1.a_reg ;
  assign _07_ = ! (* src = "verilog/multiplier_sc.sv:76.39-76.49" *) \copy1.b_reg ;
  assign \copy1.busy_next  = \copy1.in_valid  && (* src = "verilog/multiplier_sc.sv:75.22-75.39" *) _08_;
  assign \copy1.finish_next  = _09_ && (* src = "verilog/multiplier_sc.sv:76.24-76.58" *) \copy1.busy ;
  assign _08_ = ! (* src = "verilog/multiplier_sc.sv:75.34-75.39" *) \copy1.busy ;
  assign _09_ = _06_ || (* src = "verilog/multiplier_sc.sv:76.25-76.49" *) _07_;
  (* src = "verilog/multiplier_sc.sv:82.5-89.8" *)
  always @(posedge \copy1.clk )
    \copy1.a_reg  <= \copy1.a_reg_next ;
  (* src = "verilog/multiplier_sc.sv:82.5-89.8" *)
  always @(posedge \copy1.clk )
    \copy1.b_reg  <= \copy1.b_reg_next ;
  (* src = "verilog/multiplier_sc.sv:82.5-89.8" *)
  always @(posedge \copy1.clk )
    \copy1.o_reg  <= \copy1.o_reg_next ;
  (* src = "verilog/multiplier_sc.sv:82.5-89.8" *)
  always @(posedge \copy1.clk )
    \copy1.busy  <= \copy1.busy_next ;
  (* src = "verilog/multiplier_sc.sv:82.5-89.8" *)
  always @(posedge \copy1.clk )
    \copy1.finish  <= \copy1.finish_next ;
  (* src = "verilog/multiplier_sc.sv:82.5-89.8" *)
  always @(posedge \copy1.clk )
    \copy1.counter  <= \copy1.counter_next ;
  assign _05_[7:0] = \copy1.a_reg  << (* src = "verilog/multiplier_sc.sv:80.77-80.93" *) \copy1.counter ;
  assign \copy1.a_reg_next  = \copy1.busy_next  ? (* src = "verilog/multiplier_sc.sv:77.38-77.67" *) \copy1.a  : \copy1.a_reg ;
  assign \copy1.b_reg_next  = \copy1.busy_next  ? (* src = "verilog/multiplier_sc.sv:78.38-78.72" *) \copy1.b  : { 1'h0, \copy1.b_reg [3:1] };
  assign \copy1.counter_next  = \copy1.busy  ? (* src = "verilog/multiplier_sc.sv:79.31-79.54" *) _03_ : 3'h0;
  assign _10_[7:0] = \copy1.b_reg [0] ? (* src = "verilog/multiplier_sc.sv:80.66-80.97" *) _05_[7:0] : 8'h00;
  assign \copy1.o_reg_next  = \copy1.busy  ? (* src = "verilog/multiplier_sc.sv:80.45-80.98" *) _04_ : 8'h00;
  assign _11_ = \copy2.counter  + (* src = "verilog/multiplier_sc.sv:79.43-79.54" *) 1'h1;
  assign _12_ = \copy2.o_reg  + (* src = "verilog/multiplier_sc.sv:80.57-80.98" *) _18_[7:0];
  assign _14_ = ! (* src = "verilog/multiplier_sc.sv:76.25-76.35" *) \copy2.a_reg ;
  assign _15_ = ! (* src = "verilog/multiplier_sc.sv:76.39-76.49" *) \copy2.b_reg ;
  assign \copy2.busy_next  = \copy2.in_valid  && (* src = "verilog/multiplier_sc.sv:75.22-75.39" *) _16_;
  assign \copy2.finish_next  = _17_ && (* src = "verilog/multiplier_sc.sv:76.24-76.58" *) \copy2.busy ;
  assign _16_ = ! (* src = "verilog/multiplier_sc.sv:75.34-75.39" *) \copy2.busy ;
  assign _17_ = _14_ || (* src = "verilog/multiplier_sc.sv:76.25-76.49" *) _15_;
  (* src = "verilog/multiplier_sc.sv:82.5-89.8" *)
  always @(posedge \copy2.clk )
    \copy2.a_reg  <= \copy2.a_reg_next ;
  (* src = "verilog/multiplier_sc.sv:82.5-89.8" *)
  always @(posedge \copy2.clk )
    \copy2.b_reg  <= \copy2.b_reg_next ;
  (* src = "verilog/multiplier_sc.sv:82.5-89.8" *)
  always @(posedge \copy2.clk )
    \copy2.o_reg  <= \copy2.o_reg_next ;
  (* src = "verilog/multiplier_sc.sv:82.5-89.8" *)
  always @(posedge \copy2.clk )
    \copy2.busy  <= \copy2.busy_next ;
  (* src = "verilog/multiplier_sc.sv:82.5-89.8" *)
  always @(posedge \copy2.clk )
    \copy2.finish  <= \copy2.finish_next ;
  (* src = "verilog/multiplier_sc.sv:82.5-89.8" *)
  always @(posedge \copy2.clk )
    \copy2.counter  <= \copy2.counter_next ;
  assign _13_[7:0] = \copy2.a_reg  << (* src = "verilog/multiplier_sc.sv:80.77-80.93" *) \copy2.counter ;
  assign \copy2.a_reg_next  = \copy2.busy_next  ? (* src = "verilog/multiplier_sc.sv:77.38-77.67" *) \copy2.a  : \copy2.a_reg ;
  assign \copy2.b_reg_next  = \copy2.busy_next  ? (* src = "verilog/multiplier_sc.sv:78.38-78.72" *) \copy2.b  : { 1'h0, \copy2.b_reg [3:1] };
  assign \copy2.counter_next  = \copy2.busy  ? (* src = "verilog/multiplier_sc.sv:79.31-79.54" *) _11_ : 3'h0;
  assign _18_[7:0] = \copy2.b_reg [0] ? (* src = "verilog/multiplier_sc.sv:80.66-80.97" *) _13_[7:0] : 8'h00;
  assign \copy2.o_reg_next  = \copy2.busy  ? (* src = "verilog/multiplier_sc.sv:80.45-80.98" *) _12_ : 8'h00;
  assign _19_ = ! (* src = "verilog/multiplier_sc.sv:41.28-41.49" *) _20_;
  assign _20_ = _00_ || (* src = "verilog/multiplier_sc.sv:41.30-41.48" *) _01_;
  assign assume_1_violate_in = _19_ || (* src = "verilog/multiplier_sc.sv:41.28-41.69" *) assume_1_violate;
  assign _21_ = _02_ || (* src = "verilog/multiplier_sc.sv:46.18-46.65" *) assume_1_violate_in;
  (* src = "verilog/multiplier_sc.sv:42.1-44.4" *)
  always @(posedge clk)
    assume_1_violate <= assume_1_violate_in;
  assign _18_[31:8] = 24'hxxxxxx;
  assign \copy2.coutner  = 1'h0;
  assign \copy2.o  = \copy2.o_reg ;
  assign \copy2.out_valid  = \copy2.finish ;
  assign \copy2.a  = a2;
  assign \copy2.b  = b;
  assign \copy2.clk  = clk;
  assign \copy2.in_valid  = in_valid;
  assign o2 = \copy2.o ;
  assign out_valid2 = \copy2.out_valid ;
  assign _10_[31:8] = 24'hxxxxxx;
  assign \copy1.coutner  = 1'h0;
  assign \copy1.o  = \copy1.o_reg ;
  assign \copy1.out_valid  = \copy1.finish ;
  assign \copy1.a  = a1;
  assign \copy1.b  = b;
  assign \copy1.clk  = clk;
  assign \copy1.in_valid  = in_valid;
  assign o1 = \copy1.o ;
  assign out_valid1 = \copy1.out_valid ;
endmodule