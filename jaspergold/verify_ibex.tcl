set_elaborate_single_run_mode off

analyze -sva verilog/ibex_miter.sv +define+ASSUME_ON=1

elaborate -top top

clock clock
reset reset -non_resettable_regs 0

prove -all