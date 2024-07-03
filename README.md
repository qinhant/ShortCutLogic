Command:
1. `yosys generate_avg.ys`
2. `../abc -c "read multiplier_sc.aig; fold; pdr -v -w -d; write_cex -n -m -f multiplier_sc.cex; write_verilog multiplier_sc_abc.v" > multiplier_sc_pdr.log`
3. `python3 pdr_interpreter.py --design multiplier_sc`
