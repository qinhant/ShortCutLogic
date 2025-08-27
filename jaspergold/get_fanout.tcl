set_elaborate_single_run_mode off

# Get fanout for secrets in multiplier_miter.sv
analyze -sva verilog/multiplier_miter.sv +define+ASSUME_ON=1
elaborate -top top
get_fanout -transitive in_b_1 -barrier {copy1.finish copy2.finish}
get_fanout -transitive in_b_2 -barrier {copy1.finish copy2.finish}
clear -all

# Get fanout for secrets in sodor5_miter_clean.sv
analyze -sva verilog/sodor5_miter_clean.sv +define+ASSUME_ON=1
elaborate -top top
get_fanout -transitive secret_1 -barrier {copy1.d.wb_reg_valid copy2.d.wb_reg_valid }
get_fanout -transitive secret_2 -barrier {copy1.d.wb_reg_valid copy2.d.wb_reg_valid }
clear -all

# Get fanout for secrets in rocket_clean.sv
analyze -sva verilog/rocket_clean.sv +define+ASSUME_ON=1
elaborate -top top
get_fanout -transitive secret_1 -barrier {copy1.csr_io_retire copy2.csr_io_retire}
get_fanout -transitive secret_2 -barrier {copy1.csr_io_retire copy2.csr_io_retire}
clear -all

# Get fanout for secrets in rsa_modexp_miter.sv
analyze -sva verilog/rsa_modexp_miter.sv +define+ASSUME_ON=1
elaborate -top top
get_fanout -transitive exponent1 -barrier {copy1.finish copy2.finish}
get_fanout -transitive exponent2 -barrier {copy1.finish copy2.finish}
clear -all

# Get fanout for secrets in SE_leakymul_miter.sv
analyze -sva verilog/SE_leakymul_miter.sv +define+ASSUME_ON=1
elaborate -top top
get_fanout -transitive in_io_in_op2_1 -barrier {copy1.output_valid copy2.output_valid}
get_fanout -transitive in_io_in_op2_2 -barrier {copy1.output_valid copy2.output_valid}
clear -all

# Get fanout for secrets in cache_miter.sv
analyze -sva verilog/cache_miter.sv +define+ASSUME_ON=1
elaborate -top top
get_fanout -transitive i_p_addr_1 -barrier {copy1.hit copy2.hit}
get_fanout -transitive i_p_addr_1 -barrier {copy1.hit copy2.hit}
clear -all

# Get fanout for secrets in gcd_miter.sv
analyze -sva verilog/gcd_miter.sv +define+ASSUME_ON=1
elaborate -top top
get_fanout -transitive B_in_1 -barrier {copy1.GCD_done copy2.GCD_done}
get_fanout -transitive B_in_2 -barrier {copy1.GCD_done copy2.GCD_done}
clear -all

# Get fanout for secrets in single_divider_ws_miter.sv
analyze -sva verilog/single_divider_ws_miter.sv +define+ASSUME_ON=1
elaborate -top top
get_fanout -transitive input_b_1 -barrier {copy1.s_output_z_stb copy2.s_output_z_stb}
get_fanout -transitive input_b_2 -barrier {copy1.s_output_z_stb copy2.s_output_z_stb}
clear -all

# Get fanout for secrets in single_multiplier_ws_miter.sv
analyze -sva verilog/single_multiplier_ws_miter.sv +define+ASSUME_ON=1
elaborate -top top
get_fanout -transitive input_b_1 -barrier {copy1.s_output_z_stb copy2.s_output_z_stb}
get_fanout -transitive input_b_2 -barrier {copy1.s_output_z_stb copy2.s_output_z_stb}
clear -all

# Get fanout for secrets in single_adder_ws_miter.sv
analyze -sva verilog/single_adder_ws_miter.sv +define+ASSUME_ON=1
elaborate -top top
get_fanout -transitive input_b_1 -barrier {copy1.s_output_z_stb copy2.s_output_z_stb}
get_fanout -transitive input_b_2 -barrier {copy1.s_output_z_stb copy2.s_output_z_stb}
clear -all