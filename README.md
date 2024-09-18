
# Repo Hierarchy:
- /verilog/ : include all verilog and system verilog files
- /scripts/ : include all yosys and python scripts
- /yosys_output/ : include all yosys output files such as .aig and .map files
- /abc_output/ : include all abc output files such as .cex and .pla files


# Requirements: 
- [yosys](https://github.com/YosysHQ/yosys)
- [abc](https://github.com/berkeley-abc/abc) 


# Usage Example:
- flatten verilog: `python3 scripts/transform_verilog.py --input verilog/self_composition_multiplier.sv --output verilog/self_composition_multiplier_yosys.sv --option flatten --top top`
- convert verilog to aig (primary outputs only have assertions) and generate the map file `python3 scripts/transform_verilog.py --input verilog/self_composition_multiplier.sv --output yosys_output/self_composition_multiplier.aig --option verilog_to_aig --top top`
- run pdr in abc and output log, invariant, counterexample `abc -c "read yosys_output/self_composition_multiplier.aig; fold; pdr -v -w -d -I abc_output/self_composition_multiplier.pla; write_cex -n -m -f abc_output/multiplier_sc.cex;" > ./abc_output/multiplier_sc_pdr.log`
- interpret the abc output log using the variable names from verilog (use `--cex` to interpret the counterexample if there is any)`python3 scripts/pdr_interpreter.py --log abc_output/multiplier_sc_pdr.log --map yosys_output/self_composition_multiplier.map --inv abc_output/self_composition_multiplier.pla --output abc_output/multiplier_sc_pdr_interpreted.log`
