#!/bin/python3
import datetime
import os
import subprocess
from enum import Flag, auto

TIMEOUT = datetime.timedelta(hours=1).seconds


examples = {
    "multiplier": "multiplier_miter",
    # "secenclave": "SE_leakymul_miter",
    "sodor": "sodor5_miter_clean",
    "rocket": "rocket_clean"
}

base_flags = "farib"

technique_flags = {
    "orig": "",
    "sc": "m",
    "ept": "sp",
    "epi": "spd",
    "sc_ept": "msp",
    "sc_epi": "mspd"
}

eval_order = ["sc"]

# eval_order = ["sc", "ept", "epi", "sc_ept", "sc_epi", "orig"]


scripts_folder = os.path.relpath(os.path.dirname(__file__))
eval_script = os.path.join(scripts_folder, "fast_run_exp.sh")

cwd = os.path.join(scripts_folder, '..')
output_folder = os.path.relpath(os.path.join(cwd, 'output'))
log_filename = logfile = os.path.join(
    output_folder, datetime.datetime.now().strftime("eval_%Y%m%d_%H%M.log"))

with open(log_filename, "w") as log_file:

    def log(msg : str):
        log_file.write(msg)
        print(msg, end='', flush=True)


    for tech in eval_order:
        for name, ex in examples.items():
            log(f"#### Evaluating technique {tech} on example {name} #### \n")
            eval_args = f"-{base_flags}{technique_flags[tech]} -O {tech} {ex}"
            cmd = f"{eval_script} {eval_args}"
            log(f">> {cmd}   ===> ")
            try:
                subprocess.run(cmd,
                               shell=True, cwd=cwd, capture_output=True,
                               check=True, timeout=TIMEOUT)
                log("ok\n")
                result_file = os.path.join(
                    output_folder, f'{ex}_{tech}_exp', 'pdr_flatten_interpreted.log')
                cmd = f"grep -A20 'Verification .* successful' {result_file}"
                log(f">> {cmd}   ===> ")
                results = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True)
                log("ok\n")
                log(results.stdout.decode('utf-8'))
            except TimeoutError:
                log(f"TIMEOUT ({TIMEOUT}s)\n")
            except subprocess.CalledProcessError as err:
                log(f"ERROR!!!\n")
                log(err.stderr.decode('utf-8'))
            finally:
                log("\n\n")
