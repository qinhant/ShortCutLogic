import sys
import argparse
import os


def flatten_verilog(input_path, output_path, top):
    # create a temporary yosys script using the input arguments
    file = open("scripts/flatten_verilog.ys", "r")
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


if __name__ == "__main__":
    parse = argparse.ArgumentParser()
    parse.add_argument("--input", dest="input_path", required=True, help="input_path")
    parse.add_argument(
        "--output",
        dest="output_path",
        required=True,
        help="output path",
    )
    parse.add_argument("--top", dest="top", required=True, help="top module")
    parse.add_argument(
        "--option", dest="option", required=True, help="available options: flatten"
    )
    args = parse.parse_args()

    if args.option == "flatten":
        flatten_verilog(args.input_path, args.output_path, args.top)
