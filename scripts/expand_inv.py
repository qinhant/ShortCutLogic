import argparse
import re
import itertools

def analyze_map_file(map_file_path):
    """
    Analyzes the map file to extract:
    - Latch mappings (e.g., copy1.counter[0])
    - Predicate variables and their relationships to whole words
    Returns a dictionary with latch mappings and predicate relationships.
    """
    latch_map = {}
    predicate_map = {}

    with open(map_file_path, "r") as file:
        for line in file:
            if line.find("Invariant Clauses") >= 0:
                continue
            if len(line.strip()) == 0:
                break
            parts = line.strip().split()
            if len(parts) >= 4:
                signal_type = parts[0]
                latch_number = int(parts[1])
                bit_index = int(parts[2])
                signal_name = parts[3]

                # Process latch and invlatch entries
                if signal_type in {"latch", "invlatch"}:
                    # Represent as `signal_name[bit_index]`
                    signal_with_bit = f"{signal_name}[{bit_index}]"
                    latch_map.setdefault(signal_name, []).append(bit_index)

                    # Check for predicate variables
                    if signal_name.startswith("shortcut.neq"):
                        predicate_map.setdefault(signal_name, set())
                    elif signal_name.startswith(("copy1", "copy2")):
                        # Find corresponding predicate variable
                        signal_name_split = signal_name.split(".")
                        if len(signal_name_split) == 1:
                            continue
                        word_name = signal_name.split(".")[1]
                        predicate_key = f"shortcut.neq_{word_name}_copy2"
                        predicate_map.setdefault(predicate_key, set()).add(signal_name)

    # Expand predicate variables to include all associated signals and bits
    expanded_predicates = {}
    for predicate, signals in predicate_map.items():
        expanded_predicates[predicate] = []
        for signal in signals:
            if signal in latch_map:
                for bit in sorted(latch_map[signal]):
                    expanded_predicates[predicate].append(f"{signal}[{bit}]")

    return latch_map, expanded_predicates


def expand_expressions(expression_file, latch_map, predicate_map):
    #   Parameters:
    #     - expression_file: path to the file containing expressions.
    #     - latch_map: dict mapping signal name to a list of bit indices, e.g.:
    #         {
    #           "copy1.a_reg": [0, 1],
    #           "copy2.a_reg": [0, 1],
    #           ...
    #         }
    #     - predicate_map: dict mapping a predicate variable name (e.g. "shortcut.neq_a_reg_copy2")
    #       to the set of signals, e.g. {"copy1.a_reg", "copy2.a_reg"}.

    #     Returns:
    #     - A list of expanded expressions (possibly many lines if multiple predicates exist).
    #
    start_marker = "---------------Invariant Clauses--------------------"
    end_marker   = "---------------PDR Log--------------------"

    within_section = False
    all_expanded = []

    with open(expression_file, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue  # skip empty lines

            if line == start_marker:
                within_section = True
                continue
            if line == end_marker:
                within_section = False
                break

            if not within_section:
                continue

            # We'll expand this expression step by step
            current_expressions = [line]

            # Find all occurrences of predicate variables in the line
            # Example match: "shortcut.neq_b_reg_copy2[0]"
            pattern = r"shortcut\.neq_[A-Za-z0-9_]+_copy2\[\d+\]"
            predicate_vars = re.findall(pattern, line)

            # Process each predicate variable sequentially
            for pv in predicate_vars:
                # e.g. pv = "shortcut.neq_b_reg_copy2[0]"
                # Extract the base name: "shortcut.neq_b_reg_copy2"
                # (We don't actually need the [bit_index] part from the string here,
                #  because the user wants to expand all bits, not just the specified one.)
                base_name = pv.split("[")[0]  # "shortcut.neq_b_reg_copy2"

                if base_name not in predicate_map:
                    # Not in our dictionary => no expansions
                    # We'll just skip it; or you can keep it as is.
                    continue

                # The signals associated with this predicate (e.g. {"copy1.b_reg", "copy2.b_reg"})
                signals = predicate_map[base_name]
                print(f"Expanding {pv} using signals: {signals}")

                # Typically you have exactly one copy1.* and one copy2.* signal in there.
                # Let's get them explicitly:
                copy1_signal = None
                copy2_signal = None
                for sig in signals:
                    if sig.startswith("copy1."):
                        copy1_signal = sig.split('[')[0]
                    elif sig.startswith("copy2."):
                        copy2_signal = sig.split("[")[0]
                print(f"  Copy1: {copy1_signal}, Copy2: {copy2_signal}")

                # If we lack one of them, we can't produce a difference
                if not copy1_signal or not copy2_signal:
                    # skip or keep as is
                    continue

                # Now see how many bits each signal has. They should match
                # if they are the same register, but let's just fetch them individually.
                if copy1_signal not in latch_map or copy2_signal not in latch_map:
                    continue  # can't expand

                copy1_bits = latch_map[copy1_signal]  # e.g. [0,1]
                copy2_bits = latch_map[copy2_signal]  # e.g. [0,1]

                # For simplicity, assume they have the same number of bits, n.
                # If not, you can handle it differently. Let's take min just in case:
                n = min(len(copy1_bits), len(copy2_bits))

                # We'll produce 2n expansions. For bit i in range(n):
                #   1) copy1_signal[i] && !copy2_signal[i]
                #   2) !copy1_signal[i] && copy2_signal[i]
                # We'll then replace the original predicate variable pv in each existing expression.

                new_expressions = []
                for expr in current_expressions:
                    # For each expression we currently have, produce 2n expansions
                    for i in range(n):
                        b1 = copy1_bits[i]
                        b2 = copy2_bits[i]
                        # form A: copy1 is 1, copy2 is 0
                        diff_a = f"{copy1_signal}[{b1}] && !{copy2_signal}[{b2}]"
                        # form B: copy1 is 0, copy2 is 1
                        diff_b = f"!{copy1_signal}[{b1}] && {copy2_signal}[{b2}]"

                        # We combine them with OR, or just pick one? The user said "2n expressions",
                        # meaning one line for diff_a, one line for diff_b, so let's produce them separately:

                        # Expression #1
                        expr_a = expr.replace(pv, diff_a, 1)
                        new_expressions.append(expr_a)

                        # Expression #2
                        expr_b = expr.replace(pv, diff_b, 1)
                        new_expressions.append(expr_b)

                # Update our list of expressions with the newly expanded ones
                current_expressions = new_expressions

            # After handling all predicate variables in the line, append the results
            all_expanded.extend(current_expressions)
        # Optional: deduplicate while preserving order
    seen = set()
    deduped_expanded = []
    for e in all_expanded:
        if e not in seen:
            seen.add(e)
            deduped_expanded.append(e)

    return deduped_expanded

if __name__ == "__main__":
    parse = argparse.ArgumentParser()
    parse.add_argument("--log", dest="log_path", required=True, help="input .log path")
    parse.add_argument("--map", dest="map_path", required=True, help="input .map path")
    parse.add_argument(
        "--output",
        dest="output_path",
        required=True,
        help="output inv path",
    )
    args = parse.parse_args()

    latch_map, predicate_map = analyze_map_file(args.map_path)

    # Print latch mappings
    print("Latch Mappings:")
    for signal, bits in latch_map.items():
        print(f"  {signal}: {[f'{bit}' for bit in sorted(bits)]}")

    # Print expanded predicate relationships
    print("\nExpanded Predicate Relationships:")
    for predicate, signals in predicate_map.items():
        print(f"  {predicate} -> {', '.join(signals)}")

    # Example Usage
    # latch_map = {
    #     "copy1.b_reg": [0, 1],
    #     "copy2.b_reg": [0, 1],
    #     "copy2.a_reg": [0, 1],
    #     "copy1.a_reg": [0, 1],
    #     "copy1.finish": [0],
    #     "copy2.finish": [0],
    # }
    # predicate_map = {
    #     "shortcut.neq_b_reg_copy2": {"copy1.b_reg", "copy2.b_reg"},
    #     "shortcut.neq_a_reg_copy2": {"copy1.a_reg", "copy2.a_reg"},
    #     "shortcut.neq_finish_copy2": {"copy1.finish", "copy2.finish"},
    # }
    expanded = expand_expressions(args.log_path, latch_map, predicate_map)

    # Print expanded expressions
    for expr in expanded:
        print(expr)

    with open(args.output_path, "w") as file:
        for expr in expanded:
            file.write(expr + "\n")
