from vcdvcd import VCDVCD
import argparse
import sys

def sim_parse(input_path, output_path):
    vcd = VCDVCD(input_path)
    inequiv_signals = []
    all_signals = []
    output = ""
    for key in vcd.references_to_ids.keys():
        signal = vcd[key]
        output += f"{key} {signal.tv}\n"
        # print(key, signal.tv)
        # if signal.var_type != "reg":
        #     continue
        if key.find('copy1') >= 0:
            all_signals.append(key)
            values = signal.tv
            sym_values = vcd[key.replace('copy1', 'copy2')].tv
            if values != sym_values:
                inequiv_signals.append((key.replace('copy1.', ''), signal.var_type))
    output += f"\nNumer of inequivalent signals: {len(inequiv_signals)}\n"
    # print(f"\nNumer of inequivalent signals: {len(inequiv_signals)}\n")
    for signal in inequiv_signals:
        output += f"{signal[0]} {signal[1]}\n"  
    
    with open(output_path, "w") as f:
        f.write(output)

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
