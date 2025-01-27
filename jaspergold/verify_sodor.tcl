analyze -sva verilog/sodor2_miter.sv

elaborate -top top

clock clock
reset reset -non_resettable_regs 0

prove -all