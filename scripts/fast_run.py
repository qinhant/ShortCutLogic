import os

if __name__ == "__main__":
    os.system("mkdir -p output/multiplier_sc")
    # STEP: Flatten the verilog, get rid of the modular hierarchy
    os.system(
        "python3 scripts/transform_verilog.py --input verilog/multiplier_sc.sv"
        " --output output/multiplier_sc/flatten.sv --top top --option flatten"
    )
    # STEP: Add shortcut logic to the flattened verilog
    os.system(
        "python3 scripts/shortcut_signals.py --input output/multiplier_sc/flatten.sv"
        " --output output/multiplier_sc/shortcut.sv --top top"
    )
    # STEP: Transform the verilog to AIGER format
    os.system(
        "python3 scripts/transform_verilog.py --input output/multiplier_sc/shortcut.sv"
        " --output output/multiplier_sc/shortcut.aig --top top --option verilog_to_aig"
    )
    # STEP: Run ABC with PDR, output the log
    abc_command = """
        read output/multiplier_sc/shortcut.aig;
        fold;
        pdr -v -w -d -I -r output/multiplier_sc/shortcut.pla;
        write_cex -n -m -f output/multiplier_sc/shortcut.cex
    """
    abc_command = abc_command.replace("\n", " ")

    os.system(
        f"bash -c \"abc -c '{abc_command}' > ./output/multiplier_sc/pdr_shortcut.log\""
    )
    # STEP: Interpret the log, output the interpreted log and the interpreted cex
    os.system(
        "python3 scripts/pdr_interpreter.py --log output/multiplier_sc/pdr_shortcut.log"
        " --map output/multiplier_sc/shortcut.map"
        " --inv output/multiplier_sc/shortcut.pla"
        " --output output/multiplier_sc/pdr_shortcut_intepreted.log"
        " --cex output/multiplier_sc/shortcut.cex"
    )
