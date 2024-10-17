#!/usr/bin/bash
# set -e # Exit when any command fails

# STEP: Create the output directory
mkdir -p output/multiplier_sc
rm output/multiplier_sc/*

# STEP: Flatten the Verilog, get rid of the modular hierarchy
python3 scripts/transform_verilog.py \
    --input verilog/multiplier_sc.sv \
    --output output/multiplier_sc/flatten.sv \
    --top top \
    --option flatten

# STEP: Add shortcut logic to the flattened Verilog
python3 scripts/shortcut_signals.py \
    --input output/multiplier_sc/flatten.sv \
    --output output/multiplier_sc/shortcut.sv \
    --top top \
    --implication --shortcut

# STEP: Transform the Verilog to AIGER format
python3 scripts/transform_verilog.py \
    --input output/multiplier_sc/shortcut.sv \
    --output output/multiplier_sc/shortcut.aig \
    --top top \
    --option verilog_to_aig

#STEP: Run ABC with PDR, output the log
abc -c "
    read output/multiplier_sc/shortcut.aig;
    fold;
    pdr -v -w -d -I output/multiplier_sc/shortcut.pla;
    write_cex -n -m -f output/multiplier_sc/shortcut.cex
" > ./output/multiplier_sc/pdr_shortcut.log

# STEP: Interpret the log, output the interpreted log and the interpreted cex
python3 scripts/pdr_interpreter.py \
    --log output/multiplier_sc/pdr_shortcut.log \
    --map output/multiplier_sc/shortcut.map \
    --inv output/multiplier_sc/shortcut.pla \
    --output output/multiplier_sc/pdr_shortcut_intepreted.log \
    --cex output/multiplier_sc/shortcut.cex
