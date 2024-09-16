// Benchmark "alu" written by ABC on Fri Apr 26 10:29:37 2024

module alu ( clock, 
    pi0, pi1, pi2, pi3,
    po0  );
  input  clock;
  input  pi0, pi1, pi2, pi3;
  output po0;
  reg lo0, lo1;
  wire new_n14, li0, li1;
  assign li1 = pi2 | lo1;
  assign po0 = ~lo0 & ~li1;
  assign new_n14 = pi2 & pi3;
  assign li0 = pi1 | ~new_n14;
  always @ (posedge clock) begin
    lo0 <= li0;
    lo1 <= li1;
  end
  initial begin
    lo0 <= 1'b0;
    lo1 <= 1'b0;
  end
endmodule


