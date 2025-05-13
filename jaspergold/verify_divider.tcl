set_elaborate_single_run_mode off

analyze -sva verilog/divider_miter.sv

elaborate -top top

clock clock
reset reset -non_resettable_regs 0

prove -all