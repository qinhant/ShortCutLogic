// Benchmark "noninterference" written by ABC on Mon May  6 16:13:22 2024

module noninterference ( clock, 
    pi0, pi1, pi2, pi3, pi4,
    po0  );
  input  clock;
  input  pi0, pi1, pi2, pi3, pi4;
  output po0;
  reg lo0, lo1, lo2, lo3, lo4;
  wire new_n22, new_n23, new_n24, new_n25, new_n26, li0, li1, li2, li3, li4;
  assign new_n22 = lo0 & lo2;
  assign new_n23 = lo1 & lo3;
  assign new_n24 = ~new_n22 & new_n23;
  assign new_n25 = new_n22 & ~new_n23;
  assign new_n26 = ~new_n24 & ~new_n25;
  assign li4 = pi4 | lo4;
  assign po0 = ~new_n26 & ~li4;
  assign li0 = ~pi1 & pi4;
  assign li2 = ~pi1 & pi3;
  assign li3 = ~pi1 & pi2;
  assign li1 = li0;
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


