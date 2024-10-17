#!/usr/bin/bash

# STEP: Create the output directory
mkdir -p output/multiplier_sc_noshort
rm output/multiplier_sc_noshort_noshort/*

# STEP: Transform the Verilog to AIGER format
python3 scripts/transform_verilog.py \
    --input verilog/multiplier_sc.sv \
    --output output/multiplier_sc_noshort/no_shortcut.aig \
    --top top \
    --option verilog_to_aig

# STEP: Run ABC with PDR, output the log
abc -c "
    read output/multiplier_sc_noshort/no_shortcut.aig;
    fold;
    pdr -v -w -d -f -I output/multiplier_sc_noshort/no_shortcut.pla;
    write_cex -n -m -f output/multiplier_sc_noshort/no_shortcut.cex
" > ./output/multiplier_sc_noshort/pdr_no_shortcut.log

# STEP: Interpret the log, output the interpreted log and the interpreted cex
python3 scripts/pdr_interpreter.py \
    --log output/multiplier_sc_noshort/pdr_no_shortcut.log \
    --map output/multiplier_sc_noshort/no_shortcut.map \
    --inv output/multiplier_sc_noshort/no_shortcut.pla \
    --output output/multiplier_sc_noshort/pdr_no_shortcut_intepreted.log \
    --cex output/multiplier_sc_noshort/no_shortcut.cex
