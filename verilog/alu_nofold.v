// Benchmark "alu" written by ABC on Fri Apr 26 10:16:06 2024

module alu ( clock, 
    pi0, pi1, pi2, pi3,
    po0, po1  );
  input  clock;
  input  pi0, pi1, pi2, pi3;
  output po0, po1;
  reg lo0;
  wire new_n10, li0;
  assign new_n10 = pi2 & pi3;
  assign li0 = ~pi1 & new_n10;
  assign po0 = lo0;
  assign po1 = pi2;
  always @ (posedge clock) begin
    lo0 <= li0;
  end
  initial begin
    lo0 <= 1'b0;
  end
endmodule


