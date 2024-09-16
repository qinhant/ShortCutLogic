
# Repo Hierarchy:
- /verilog/ : include all verilog and system verilog files
- /scripts/ : include all yosys and python scripts
- /yosys_output/ : include all yosys output files such as .aig and .map files
- /abc_output/ : include all abc output files such as .cex and .pla files


# Requirements: 
- [yosys](https://github.com/YosysHQ/yosys)
- [abc](https://github.com/berkeley-abc/abc) 


# Usage:
- flatten verilog: `python3 scripts/transform_verilog.py --input input_path --output ouptut_path --top top module --option flatten`
