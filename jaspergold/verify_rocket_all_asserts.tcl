set_elaborate_single_run_mode off

analyze -sva verilog/rocket_miter_all_asserts.sv

elaborate -top top

clock clock
reset reset -non_resettable_regs 0

prove -all