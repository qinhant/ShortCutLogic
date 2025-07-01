import sys
import argparse
import os
import re

# In the input file, every line of the invariants should look like !(a && !b && c) etc.
# The map file needs to be the one genereated along with the aig file
def inv_to_pla(input_path, map_path, output_path):
    with open(map_path, "r") as file:
        mapping = [line.strip() for line in file.readlines()]
        latch_map = dict()
        max_latch = 0
        for line in mapping:
            if line.find("latch") < 0 and line.find("input") < 0:
                continue
            elif line.find("latch") >= 0:
                split = line.split(" ")
                latch_num = int(split[1])
                if latch_num > max_latch:
                    max_latch = latch_num
                bit = split[2]
                signal_name = split[3]
                if f"{signal_name}[{bit}]" not in latch_map.keys():
                    latch_map[f"{signal_name}[{bit}]"] = latch_num

    with open(input_path, "r") as file:
        content = file.readlines()
        all_latches = set()
        latch_values = []
        for cube in content:
            cube = cube.strip()
            variables = cube.split("&&")
            cube_latch_map = dict()
            skip = False
            for var in variables:
                var = var.strip()
                var = var.replace("!(", "").replace(")", "")
                if len(var) == 0:
                    print("No invariants found!")
                    exit(0)
                negated = var[0] == "!"
                if negated:
                    var = var[1:]
                latch_num = latch_map[var]
                all_latches.add(latch_num)
                if latch_num in cube_latch_map.keys():
                    if not cube_latch_map[latch_num] !=  negated:
                        skip = True
                cube_latch_map[latch_num] = not negated
            if not skip:
                latch_values.append(cube_latch_map)
        all_latches = sorted(list(all_latches))
        inv_translated = []
        for line in latch_values:
            cube = ["-"] * len(all_latches)
            for latch in line.keys():
                cube[all_latches.index(latch)] = "1" if line[latch] else "0"
            inv_translated.append("".join(cube) + " 1")
        all_latches = [f"lo{i}" for i in all_latches]
    with open(output_path, "w") as file:
        write_content = f".i {len(all_latches)}\n"
        write_content += ".o 1\n"
        write_content += f".p {len(inv_translated)}\n"
        write_content += f".ilb {' '.join(all_latches)}\n"
        write_content += ".ob inv\n"
        write_content += "\n".join(inv_translated)
        write_content += "\n.e"
        file.write(write_content)

if __name__ == "__main__":
    parse = argparse.ArgumentParser()
    parse.add_argument(
        "--input", dest="input_path", required=True, help="input_inv_path"
    )
    parse.add_argument("--map", dest="map_path", required=True, help="input_map_path")
    parse.add_argument(
        "--output",
        dest="output_path",
        required=True,
        help="output pla path",
    )
    args = parse.parse_args()

    inv_to_pla(args.input_path, args.map_path, args.output_path)
