set_elaborate_single_run_mode off

analyze -sva verilog/ibex_miter.sv +define+ASSUME_ON=1

elaborate -top ibex_core

clock clk_i
reset ~rst_ni -non_resettable_regs 0

prove -all