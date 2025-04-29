#!/bin/python3
import argparse
import datetime
import os
import subprocess
import sys
import time
from typing import Callable

parse = argparse.ArgumentParser()
parse.add_argument(
    "--timeout", dest="timeout", default="60", help="timeout in minutes"
)
args = parse.parse_args()

USER_TIMEOUT = datetime.timedelta(minutes=float(args.timeout)).seconds
# add a small delay at boundary
TIMEOUT = USER_TIMEOUT + min(60, round(USER_TIMEOUT * 0.05))


scripts_folder = os.path.relpath(os.path.dirname(__file__))
eval_script = os.path.join(scripts_folder, "fast_run_exp.sh")

cwd = os.path.join(scripts_folder, '..')
output_folder = os.path.relpath(os.path.join(cwd, 'output'))
log_filename = logfile = os.path.join(
output_folder, datetime.datetime.now().strftime("eval_%Y%m%d_%H%M.log"))


def log_eval(
        *,
        example: str,
        flags: str,
        output_label: str,
        timeout: str,
        log: Callable[[str], None]):
    eval_args = f"-{flags} -O {output_label} {example}"
    cmd = f"{eval_script} {eval_args}"
    log(f">> {cmd}   ===> ")
    try:
        subprocess.run(cmd,
                        shell=True, cwd=cwd, capture_output=True,
                        check=True, timeout=timeout)
        log("ok\n")
        result_file = os.path.join(
            output_folder, f'{ex}_{tech}_exp', '*_interpreted.log')
        cmd = f"grep  -E -A 20 -m 1 '(Verification .* successful)|(Block =))' {result_file}"
        log(f">> {cmd}   ===> ")
        results = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True)
        log("ok\n")
        log(results.stdout.decode('utf-8'))
    except subprocess.TimeoutExpired:
        log(f"TIMEOUT ({USER_TIMEOUT}s)\n")
    except subprocess.CalledProcessError as err:
        log(f"ERROR!!!\n")
        log(err.stderr.decode('utf-8'))
    finally:
        log("\n\n")



examples = {
    "multiplier": "multiplier_miter"
    # "secenclave": "SE_leakymul_miter",
    # "sodor": "sodor5_miter_clean",
    # "rocket": "rocket_clean"
}

base_flags = "fa"
sanity_check_flags = "u"

technique_flags = {
    "abc_orig": "ri",
    "abc_shortcut": "ris",
    "sc": "rim",
    "ept": "risp",
    "epi": "rispd",
    "ps": "rispc",
    "sc_ept": "rimsp",
    "sc_epi": "rimspd",
    "sc_ps": "rimspc",
    "ric3_orig": "g",
    "ric3_shortcut": "sg",
    "ric3-inn": "sglw"
}

eval_order = ["abc_shortcut", "sc", "ept", "epi", "ps", "sc_ept", "sc_epi", "sc_ps", "ric3_shortcut", "ric3-inn", "abc_orig", "ric3_orig"]

with open(log_filename, "w") as log_file:

    def log(msg : str):
        log_file.write(msg)
        log_file.flush()
        print(msg, end='', flush=True)

    log(f"Performing evaluations with TIMEOUT {USER_TIMEOUT}s\n\n")

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
            log_eval(
                example=ex,
                flags=base_flags + technique_flags[tech],
                output_label=tech,
                timeout=TIMEOUT,
                log=log)
            time.sleep(1)

    for tech in eval_order:
        for name, ex in examples.items():
            log(f"#### Sanity checking technique {tech} on example {name} #### \n")
            log_eval(
                example=ex,
                flags=base_flags + sanity_check_flags + technique_flags[tech],
                output_label=f"{tech}_cex",
                timeout=TIMEOUT,
                log=log)
            time.sleep(1)
