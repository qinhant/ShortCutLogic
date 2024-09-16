// Benchmark "invariant" written by ABC on Wed Jul  3 19:30:16 2024

module invariant ( 
    
    po0  );
  reg  pi0, pi1, pi2, pi3, pi4;
  output po0;
  assign po0 = (pi0 | (pi1 ? pi2 : ~pi4)) & (pi3 | ~pi4) & (~pi3 | pi4);
endmodule


