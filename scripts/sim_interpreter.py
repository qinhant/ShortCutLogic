from vcdvcd import VCDVCD
import argparse
import sys

def sim_parse(input_path, output_path):
    vcd = VCDVCD(input_path)
    inequiv_regs = []
    all_regs = []
    for key in vcd.references_to_ids.keys():
        signal = vcd[key]
        if signal.var_type != "reg":
            continue
        print(key, signal.tv)
        if key.find('copy1') >= 0:
            all_regs.append(key)
            values = signal.tv
            sym_values = vcd[key.replace('copy1', 'copy2')].tv
            if values != sym_values:
                inequiv_regs.append(key)
    # print(len(inequiv_regs))
    # print(inequiv_regs)
    # print(len(all_regs))
    # print(all_regs)

if __name__ == "__main__":
    parse = argparse.ArgumentParser()
    parse.add_argument(
        "--input", dest="input_path", required=True, help="input vcd file path"
    )
    parse.add_argument(
        "--output",
        dest="output_path",
        required=True,
        help="output path",
    )
    args = parse.parse_args()
    if not args.input_path.endswith(".vcd"):
        print("Invalid input file, must be a .vcd file")
        sys.exit(1)

    sim_parse(args.input_path, args.output_path)
