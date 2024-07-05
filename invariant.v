module inv(
    input lo0,
    input lo1,
    input lo2,
    input lo3,
    input lo4,
    output o
);

assign o = ~(~lo3 & lo4) & ~(lo3 & ~lo4) & ~(~lo0 & ~lo1 & lo3) & ~(~lo0 & lo1 & ~lo2);


endmodule