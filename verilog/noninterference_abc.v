// Benchmark "noninterference" written by ABC on Thu May 23 11:27:11 2024

module noninterference ( clock, 
    pi0, pi1, pi2, pi3, pi4,
    po0  );
  input  clock;
  input  pi0, pi1, pi2, pi3, pi4;
  output po0;
  reg lo0, lo1, lo2, lo3, lo4;
  wire new_n22, new_n23, new_n24, new_n25, new_n30, new_n31, new_n32,
    new_n33, new_n34, li0, li1, li2, li3, li4;
  assign new_n22 = pi2 & ~pi3;
  assign new_n23 = ~pi2 & pi3;
  assign new_n24 = ~new_n22 & ~new_n23;
  assign new_n25 = ~lo0 & new_n24;
  assign li0 = ~pi1 & ~new_n25;
  assign li1 = ~pi1 & pi2;
  assign li2 = ~pi1 & pi3;
  assign li3 = ~pi1 & pi4;
  assign new_n30 = lo2 & lo4;
  assign new_n31 = lo1 & lo3;
  assign new_n32 = ~new_n30 & new_n31;
  assign new_n33 = new_n30 & ~new_n31;
  assign new_n34 = ~new_n32 & ~new_n33;
  assign po0 = new_n25 & ~new_n34;
  assign li4 = li3;
  always @ (posedge clock) begin
    lo0 <= li0;
    lo1 <= li1;
    lo2 <= li2;
    lo3 <= li3;
    lo4 <= li4;
  end
  initial begin
    lo0 <= 1'b0;
    lo1 <= 1'b0;
    lo2 <= 1'b0;
    lo3 <= 1'b0;
    lo4 <= 1'b0;
  end
endmodule


