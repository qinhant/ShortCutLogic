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
    "--timeout", dest="timeout", default="65", help="timeout in minutes"
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
        result_file: str,
        flags: str,
        output_label: str,
        timeout: str,
        valid_retcodes: dict[int, str] = {0: 'ok'},
        log: Callable[[str], None]):
    eval_args = f"-{flags} -O {output_label} {example}"
    cmd = f"{eval_script} {eval_args}"
    log(f">> {cmd}   ===> ")
    try:
        subprocess.run(cmd,
                        shell=True, cwd=cwd, capture_output=True,
                        check=True, timeout=timeout)
        # log(f"{valid_retcodes[0]}\n")
    except subprocess.TimeoutExpired:
        log(f"TIMEOUT ({USER_TIMEOUT}s)\n")
        return
    except subprocess.CalledProcessError as err:
        if err.returncode in valid_retcodes:
            log(f"{valid_retcodes[err.returncode]}\n")
        else:
            log(f"ERROR!!! (code {err.returncode})\n")
            log(repr(valid_retcodes))
            log(err.stderr.decode('utf-8'))
            return
    
    cmd = f"grep ' : ' {result_file}"
    log(f">> {cmd}   ===> ")
    try:
        results = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True)
        log("ok\n")
        log(results.stdout.decode('utf-8'))
    except subprocess.TimeoutExpired:
        log(f"TIMEOUT ({USER_TIMEOUT}s)\n")
    except subprocess.CalledProcessError as err:
        log(f"ERROR!!! (code {err.returncode})\n")
        log(err.stderr.decode('utf-8'))
    finally:
        log("\n\n")

    cmd = f"grep  -E -A 200 -m 1 '(Verification .* successful)|(Block =)|(SolverStatistic.*)' {result_file}"
    log(f">> {cmd}   ===> ")
    try:
        results = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True)
        log("ok\n")
        log(results.stdout.decode('utf-8'))
    except subprocess.TimeoutExpired:
        log(f"TIMEOUT ({USER_TIMEOUT}s)\n")
    except subprocess.CalledProcessError as err:
        log(f"ERROR!!! (code {err.returncode})\n")
        log(err.stderr.decode('utf-8'))
    finally:
        log("\n\n")
    
    



examples = {
    "multiplier": "multiplier_miter",
    "sodor": "sodor5_miter_clean",
    "rocket": "rocket_clean",
    "divider" : "divider_miter",
    "modexp" : "rsa_modexp_miter",
    "secenclave": "SE_leakymul_miter",
    "cache": "cache_miter",
    "gcd": "gcd_miter"
}

base_flags = "fa"
sanity_check_flags = "u"

technique_flags = {
    "abc_orig": "ri",
    "abc_shortcut": "risk",
    "sc": "rim",
    "ept": "rispk",
    "epi": "rispdk",
    "epi_init": "rispdkt",
    # "ps": "rispc",
    "sc_ept": "rimspk",
    "sc_epi": "rimspdk",
    "sc_epi_init": "rimstpdk",
    # "sc_ps": "rimspc",
    "ric3_orig": "g",
    "ric3_shortcut": "sgk",
    "ric3-inn": "slwk"
}

eval_order = technique_flags.keys()
# eval_order = ["abc_shortcut", "ept", "epi", "sc_ept", "sc_epi"]
eval_order = ["epi_init"]
# eval_order = ["ric3_orig", "ric3_shortcut", "ric3-inn"]

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


    log("#### Ensuring `rIC3` is available ####\n")
    cmd = "which rIC3"
    log(f">> {cmd}   ===>   ")
    try:
        subprocess.run(cmd, shell=True, check=True, capture_output=True)
        log("ok\n")
    except subprocess.CalledProcessError:
        log("  ERROR: rIC3 is not in the path\n")

    log("\n\n")


    for tech in eval_order:
        for name, ex in examples.items():
            log(f"#### Evaluating technique {tech} on example {name} #### \n")
            if "ric3" in tech:
                result_file = os.path.join(
                        output_folder, f'{ex}_{tech}_exp', '*.log')
                valid_retcodes = {0: 'unknown', 10: 'unsafe', 20: 'safe'}
            else:
                result_file = os.path.join(
                        output_folder, f'{ex}_{tech}_exp', '*_interpreted.log')
                valid_retcodes = {0: 'ok'}
            log_eval(
                example=ex,
                result_file=result_file,
                flags=base_flags + technique_flags[tech],
                output_label=tech,
                timeout=TIMEOUT,
                valid_retcodes=valid_retcodes,
                log=log)
            time.sleep(1)

    # for tech in eval_order:
    #     for name, ex in examples.items():
    #         log(f"#### Sanity checking technique {tech} on example {name} #### \n")
    #         if "ric3" in tech:
    #             result_file = os.path.join(
    #                     output_folder, f'{ex}_sc_{tech}_exp', '*.log')
    #             valid_retcodes = {0: 'unknown', 10: 'unsafe', 20: 'safe'}
    #         else:
    #             result_file = os.path.join(
    #                     output_folder, f'{ex}_sc_{tech}_exp', '*_interpreted.log')
    #             valid_retcodes = {0: 'ok'}
    #         log_eval(
    #             example=ex,
    #             result_file=result_file,
    #             flags=base_flags + sanity_check_flags + technique_flags[tech],
    #             output_label=f"{tech}_cex",
    #             timeout=TIMEOUT,
    #             valid_retcodes=valid_retcodes,
    #             log=log)
    #         time.sleep(1)
