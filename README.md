
# Repo Hierarchy:
- /verilog/ : include all verilog and system verilog files
- /scripts/ : include all yosys and python scripts
- /yosys_output/ : include all yosys output files such as .aig and .map files
- /abc_output/ : include all abc output files such as .cex and .pla files


# Requirements:
- [yosys](https://github.com/YosysHQ/yosys)
- [abc](https://github.com/berkeley-abc/abc)


# Usage Example:

- Run an example
```
bash scripts/fast_run_exp.sh -fasrimpb smallboom_miter_clean
```

- If the example hasn't been cleaned yet
```
python3 scripts/transform_verilog.py --input verilog/smallboom_miter.sv --output verilog/smallboom_miter_clean.sv --top top --option remove_f_blocks
```

# Docker:

To build the docker image run
```bash
docker build -t "shortcutlogic" docker/
```

For VSCode devcontainer support, it's important that the docker image is called "shortcutlogic".
