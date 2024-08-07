/* Generated by Yosys 0.40+50 (git sha1 0f9ee20ea, clang++ 15.0.0 -fPIC -Os) */

(* top =  1  *)
(* src = "invariant.v:1.1-13.10" *)
module inv(lo0, lo1, lo2, lo3, lo4, o);
  (* src = "invariant.v:2.11-2.14" *)
  wire _00_;
  (* src = "invariant.v:3.11-3.14" *)
  wire _01_;
  (* src = "invariant.v:4.11-4.14" *)
  wire _02_;
  (* src = "invariant.v:5.11-5.14" *)
  wire _03_;
  (* src = "invariant.v:6.11-6.14" *)
  wire _04_;
  wire _05_;
  wire _06_;
  wire _07_;
  wire _08_;
  wire _09_;
  wire _10_;
  wire _11_;
  wire _12_;
  wire _13_;
  wire _14_;
  wire _15_;
  wire _16_;
  wire _17_;
  wire _18_;
  wire _19_;
  wire _20_;
  wire _21_;
  (* src = "invariant.v:7.12-7.13" *)
  wire _22_;
  (* src = "invariant.v:10.46-10.57" *)
  wire _23_;
  (* src = "invariant.v:10.46-10.63" *)
  wire _24_;
  (* src = "invariant.v:10.12-10.64" *)
  wire _25_;
  (* src = "invariant.v:10.69-10.79" *)
  wire _26_;
  (* src = "invariant.v:10.69-10.86" *)
  wire _27_;
  (* src = "invariant.v:10.14-10.24" *)
  wire _28_;
  (* src = "invariant.v:10.30-10.40" *)
  wire _29_;
  (* src = "invariant.v:10.12-10.41" *)
  wire _30_;
  (* src = "invariant.v:10.44-10.64" *)
  wire _31_;
  (* src = "invariant.v:10.69-10.73" *)
  wire _32_;
  (* src = "invariant.v:10.82-10.86" *)
  wire _33_;
  (* src = "invariant.v:10.67-10.87" *)
  wire _34_;
  (* src = "invariant.v:10.14-10.18" *)
  wire _35_;
  (* src = "invariant.v:10.12-10.25" *)
  wire _36_;
  (* src = "invariant.v:10.36-10.40" *)
  wire _37_;
  (* src = "invariant.v:10.28-10.41" *)
  wire _38_;
  (* src = "invariant.v:10.53-10.57" *)
  wire _39_;
  (* src = "invariant.v:2.11-2.14" *)
  input lo0;
  wire lo0;
  (* src = "invariant.v:3.11-3.14" *)
  input lo1;
  wire lo1;
  (* src = "invariant.v:4.11-4.14" *)
  input lo2;
  wire lo2;
  (* src = "invariant.v:5.11-5.14" *)
  input lo3;
  wire lo3;
  (* src = "invariant.v:6.11-6.14" *)
  input lo4;
  wire lo4;
  (* src = "invariant.v:7.12-7.13" *)
  output o;
  wire o;
  assign _19_ = ~_03_;
  assign _20_ = _04_ & _19_;
  assign _21_ = ~_20_;
  assign _05_ = ~_04_;
  assign _06_ = _05_ & _03_;
  assign _07_ = ~_06_;
  assign _08_ = _07_ & _21_;
  assign _09_ = ~_01_;
  assign _10_ = ~_00_;
  assign _11_ = _10_ & _09_;
  assign _12_ = _11_ & _03_;
  assign _13_ = ~_12_;
  assign _14_ = _13_ & _08_;
  assign _15_ = ~_02_;
  assign _16_ = _10_ & _01_;
  assign _17_ = _16_ & _15_;
  assign _18_ = ~_17_;
  assign _22_ = _18_ & _14_;
  assign _03_ = lo3;
  assign _01_ = lo1;
  assign o = _22_;
  assign _04_ = lo4;
  assign _00_ = lo0;
  assign _02_ = lo2;
endmodule
