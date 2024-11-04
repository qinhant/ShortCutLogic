import sys
import argparse
import os
import re


def flatten_verilog(input_path, output_path, top):
    # create a temporary yosys script using the input arguments
    with open("scripts/flatten_verilog.ys", "r") as file:
        content = file.read()
        file.close()
    content = content.replace("input_path", input_path)
    content = content.replace("output_path", output_path)
    content = content.replace("top_module", top)
    file = open("scripts/flatten_verilog_temp.ys", "w")
    file.write(content)
    file.close()

    # run yosys with the temporary script and remove the temporary script
    os.system("yosys -s scripts/flatten_verilog_temp.ys")
    os.system("rm scripts/flatten_verilog_temp.ys")


def verilog_to_aig(input_path, output_path, top):
    # create a temporary yosys script using the input arguments
    with open("scripts/verilog_to_aig.ys", "r") as file:
        content = file.read()
        file.close()
    content = content.replace("input_path", input_path)
    content = content.replace("output_path", output_path)
    content = content.replace("top_module", top)
    content = content.replace("map_path", output_path.replace(".aig", ".map"))
    with open("scripts/verilog_to_aig_temp.ys", "w") as file:
        file.write(content)
        file.close()

    # run yosys with the temporary script and remove the temporary script
    os.system("yosys -s scripts/verilog_to_aig_temp.ys")
    os.system("rm scripts/verilog_to_aig_temp.ys")

    # Collect all the predicate variables and write to a file
    map_path = output_path.replace(".aig", ".map")
    with open(map_path, "r") as file:
        content = file.read()
        file.close()
        content = content.split("\n")
        predicates = set()
        for line in content:
            if line.startswith("latch") and line.find("shortcut.neq_") >= 0:
                predicates.add(line.split(" ")[1])
        predicates = list(predicates)
        predicates.sort()
        with open(map_path.replace(".map", ".priority"), "w") as file:
            for pred in predicates:
                file.write(pred + "\n")

    # Collect the relation between variables and write to a file
    with open(map_path, "r") as file:
        content = file.read()
        file.close()
        content = content.split("\n")
        var_to_latch = dict()
        latch_symmetry = dict()
        latch_to_predicate = dict()
        latch_to_var = dict()
        all_latch = set()
        for line in content:
            if line.startswith("latch"):
                latch_num = line.split(" ")[1]
                var_name = line.split(" ")[3] + "[" + line.split(" ")[2] + "]"
                var_to_latch[var_name] = latch_num
                latch_to_var[latch_num] = var_name
                all_latch.add(latch_num)

        for line in content:
            if line.startswith("latch"):
                latch_num = line.split(" ")[1]
                var_name = line.split(" ")[3] + "[" + line.split(" ")[2] + "]"
                var_name_word = line.split(" ")[3]
                if var_name.startswith("copy1."):
                    var_symmetry = "copy2." + var_name[6:]
                    predicate_var = "shortcut.neq_" + var_name_word[6:] + "_copy2[0]"
                    if (
                        predicate_var not in var_to_latch.keys()
                        or var_symmetry not in var_to_latch.keys()
                    ):
                        continue
                    predicate_latch = var_to_latch[predicate_var]
                elif var_name.startswith("copy2."):
                    var_symmetry = "copy1." + var_name[6:]
                    predicate_var = "shortcut.neq_" + var_name_word[6:] + "_copy2[0]"
                    if (
                        predicate_var not in var_to_latch.keys()
                        or var_symmetry not in var_to_latch.keys()
                    ):
                        continue
                    predicate_latch = var_to_latch[predicate_var]
                # special case for predicate variables
                elif var_name.find("shortcut.neq_") >= 0:
                    predicate_latch = -1
                    var_symmetry = var_name
                # special case for assume variables
                elif re.match(r"assume_.+_violate", var_name):
                    predicate_latch = -2
                    var_symmetry = var_name
                else:
                    continue
                latch_symmetry[latch_num] = var_to_latch[var_symmetry]
                latch_to_predicate[latch_num] = predicate_latch
        with open(map_path.replace(".map", ".relation"), "w") as file:
            file.write("latch symmetry predicate var_name symmetry_name\n")
            for latch in all_latch:
                try:
                    file.write(
                        f"{latch} {latch_symmetry[latch]} {latch_to_predicate[latch]} {latch_to_var[latch]} {latch_to_var[latch_symmetry[latch]]} \n"
                    )
                except KeyError:
                    print(latch, latch_symmetry[latch], latch_to_predicate[latch])


def create_miter(input_path, output_path, top):
    # create a miter circuit, i.e. creating two copies for equivalence checking
    with open("scripts/create_miter.ys", "r") as file:
        content = file.read()
        file.close()
    content = content.replace("input_path", input_path)
    content = content.replace("output_path", output_path)
    content = content.replace("top_module", top)
    content = content.replace("miter_top", f"{top}_miter")

    file = open("scripts/create_miter_temp.ys", "w")
    file.write(content)
    file.close()

    # run yosys with the temporary script and remove the temporary script
    os.system("yosys -s scripts/create_miter_temp.ys")
    os.system("rm scripts/create_miter_temp.ys")


if __name__ == "__main__":

    parse = argparse.ArgumentParser()
    parse.add_argument(
        "--input", dest="input_path", required=True, help="input file path"
    )
    parse.add_argument(
        "--output",
        dest="output_path",
        required=True,
        help="output path",
    )
    parse.add_argument("--top", dest="top", required=True, help="top module")
    parse.add_argument(
        "--option",
        dest="option",
        required=True,
        help="available options: flatten verilog_to_aig create_miter",
    )
    args = parse.parse_args()
    if not args.input_path.endswith(".v") and not args.input_path.endswith(".sv"):
        print("Invalid input file, must be a .v or .sv file")
        sys.exit(1)

    if args.option == "flatten":
        flatten_verilog(args.input_path, args.output_path, args.top)
    elif args.option == "verilog_to_aig":
        if not args.output_path.endswith(".aig"):
            print("Invalid output file, must be a .aig file")
            sys.exit(1)
        verilog_to_aig(args.input_path, args.output_path, args.top)
    elif args.option == "create_miter":
        create_miter(args.input_path, args.output_path, args.top)
