#!/bin/python3
import datetime
import os
import subprocess
import sys
import time

TIMEOUT = 3600 # seconds


examples = {
    "multiplier": "multiplier_miter",
    "secenclave": "SE_leakymul_miter",
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

eval_order = ["sc", "ept", "epi", "sc_ept", "sc_epi", "orig"]


scripts_folder = os.path.relpath(os.path.dirname(__file__))
eval_script = os.path.join(scripts_folder, "fast_run_exp.sh")

cwd = os.path.relpath(os.path.join(scripts_folder, '..'))
output_folder = os.path.join(cwd, 'output')
log_filename = logfile = os.path.join(
    output_folder, datetime.datetime.now().strftime(f"eval_%Y%m%d_{TIMEOUT}s.log"))

with open(log_filename, "w") as log_file:

    def log(msg : str):
        log_file.write(msg)
        log_file.flush()
        print(msg, end='', flush=True)

    log(f"Performing evaluations with TIMEOUT {TIMEOUT}s\n\n")

    log("#### Ensuring `abc_exp` is available ####\n")
    cmd = "which abc_exp"
    log(f">> {cmd}   ===>   ")
    try:
        subprocess.run(cmd, shell=True, check=True, capture_output=True)
        log("ok\n")
    except subprocess.CalledProcessError:
        log("  ERROR: abc_exp is not in the path\n")
        
        solver_dir = os.path.join(cwd, 'solvers/abc_exp')
        solver = os.path.join(solver_dir, 'abc')
        cmd = f"realpath {solver}"
        log(f">> {cmd}   ===>   ")
        try:
            subprocess.run(cmd, shell=True, check=True, capture_output=True)
            log("ok\n")
        except subprocess.CalledProcessError:
            log("ERROR: abc_exp is not built \n")
            if input(f"Rebuild {solver} (via make)? [y/N] ").lower() in ['y', 'yes']:
                subprocess.run('make', shell=True, cwd='{solver_dir}', check=True)
                log("Built!\n\n")
            else:
                log("Quitting.\n")
                sys.exit(1)
        
        cmd = f"ln -s $(realpath {solver}) /bin/abc_exp"
        log("Can add `abc_exp` to $PATH via a symlink:\n")
        log(f">> {cmd}  # (proposed)\n")
        if input(f"Add `abc_exp` to $PATH? [y/N] ").lower() in ['y', 'yes']:
            log(f">> {cmd}   ===>   ")
            subprocess.run(cmd, shell=True, check=True)
            log("ok\n")
        else:
            log("Quitting.\n")
            sys.exit(1)

    log("\n\n")

    for tech in eval_order:
        for name, ex in examples.items():
            log(f"#### Evaluating technique {tech} on example {name} #### \n")
            eval_args = f"-{base_flags}{technique_flags[tech]} -O {tech} {ex}"
            cmd = f"{eval_script} {eval_args}"
            log(f">> {cmd}   ===>   ")
            try:
                subprocess.run(cmd,
                               shell=True, cwd=cwd, capture_output=True,
                               check=True, timeout=TIMEOUT)
                log("ok\n")
                time.sleep(1)
                result_file = os.path.join(output_folder, f'{ex}_{tech}_exp')
                cmd = f"grep -A50 'Verification .* successful' {result_file}/*_interpreted.log"
                log(f">> {cmd}   ===>   ")
                results = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True)
                log("ok\n")
                time.sleep(1)
                log(results.stdout.decode('utf-8'))
            except subprocess.TimeoutExpired:
                log(f"TIMEOUT ({TIMEOUT}s)\n")
            except subprocess.CalledProcessError as err:
                log(f"ERROR!!!\n")
                log(err.stderr.decode('utf-8'))
            finally:
                log("\n\n")
