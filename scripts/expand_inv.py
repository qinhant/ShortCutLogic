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
    equiv_predicate_map = {}
    eqinit_predicate_map = {}

    with open(map_file_path, "r") as file:
        for line in file:
            if line.find("Invariant Clauses") >= 0:
                continue
            if line.find("PDR Log") >= 0:
                break
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
                        equiv_predicate_map.setdefault(signal_name, set())
                    elif signal_name.startswith("shortcut.neqinit"):
                        eqinit_predicate_map.setdefault(signal_name, set())
                    elif signal_name.startswith(("copy1", "copy2")):
                        # Find corresponding predicate variable
                        word_name = signal_name[6: ]
                        equiv_predicate_key = f"shortcut.neq_{word_name}_copy2"
                        equiv_predicate_map.setdefault(equiv_predicate_key, set()).add(signal_name)
                        eqinit_predicate_key = f"shortcut.neqinit.{signal_name}"
                        eqinit_predicate_map.setdefault(eqinit_predicate_key, set()).add(signal_name)

    # Expand predicate variables to include all associated signals and bits
    expanded_predicates = {}
    for predicate, signals in equiv_predicate_map.items():
        expanded_predicates[predicate] = []
        for signal in signals:
            if signal in latch_map:
                for bit in sorted(latch_map[signal]):
                    expanded_predicates[predicate].append(f"{signal}[{bit}]")
    for predicate, signals in eqinit_predicate_map.items():
         expanded_predicates[predicate] = []
         for signal in signals:
             if signal in latch_map:
                 for bit in sorted(latch_map[signal]):
                     expanded_predicates[predicate].append(f"{signal}[{bit}]")

    # print(expanded_predicates)

    return latch_map, expanded_predicates

def expand_inv(latch_map, predicate_map, log_path, output_path, symmetry):
    with open(log_path, "r") as file_r:
        invariants = []
        final_invariants = []
        for line in file_r:
            if line.find("Invariant Clauses") >= 0:
                continue
            if line.find("PDR Log") >= 0:
                break
            line = line.strip()
            if len(line) == 0:
                break
            invariants.append(line)
        
        while len(invariants) > 0:
            # Pop one invariant from the queue
            inv = invariants[0]
            invariants = invariants[1: ]
            if inv.find('!assume_1_violate[0]') < 0:
                        inv = inv.replace('(', '(!assume_1_violate[0] && ')

            error_match = re.search(r'!shortcut\.neq_[^ )]*', inv)
            if error_match:
                raise ValueError(f"Invalid usage of predicate variable: {error_match.group()}")
            
            # if it does not contain predicate variables, add it to the final invariants
            match_equiv = re.search(r'shortcut\.neq_[^ )]+', inv)
            match_eqinit = re.search(r'shortcut\.neqinit\.[^ )]+', inv)
            if not match_equiv and not match_eqinit:
                final_invariants.append(inv)
            elif match_equiv:
                equiv_pred = match_equiv.group(0)
                for signal in predicate_map[equiv_pred.replace('[0]', '')]:
                    if not signal.startswith('copy1'):
                        continue
                    temp_inv = inv.replace(equiv_pred, f"{signal} && !{signal.replace('copy1', 'copy2')}")
                    invariants.append(temp_inv)
                    temp_inv = inv.replace(equiv_pred, f"!{signal} && {signal.replace('copy1', 'copy2')}")
                    invariants.append(temp_inv)
            elif match_eqinit:
                eqinit_pred = match_eqinit.group(0)
                for signal in predicate_map[eqinit_pred.replace('[0]', '')]:
                    temp_inv = inv.replace(eqinit_pred, f"{signal}")
                    invariants.append(temp_inv)
        if symmetry:
            symmetric_invariants = []
            for inv in final_invariants:
                sym_inv = inv.replace("copy1", "__TEMPTEMP__")
                sym_inv = sym_inv.replace("copy2", "copy1")
                sym_inv = sym_inv.replace("__TEMPTEMP__", "copy2")
                symmetric_invariants.append(sym_inv)
            final_invariants += symmetric_invariants
        with open(output_path, 'w') as file_w:
            file_w.write('\n'.join(final_invariants))



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
    parse.add_argument(
        "--symmetry",
        dest="symmetry",
        action="store_true",
        default=False,
        help="genearte symmetric clauses in addition to the original clauses"
    )


    args = parse.parse_args()
    latch_map, predicate_map = analyze_map_file(args.map_path)

    expand_inv(latch_map, predicate_map, args.log_path, args.output_path, args.symmetry)

    # Print latch mappings
    # print("Latch Mappings:")
    # for signal, bits in latch_map.items():
    #     print(f"  {signal}: {[f'{bit}' for bit in sorted(bits)]}")

    # Print expanded predicate relationships
    # print("\nExpanded Predicate Relationships:")
    # for predicate, signals in equiv_predicate_map.items():
    #     print(f"  {predicate} -> {', '.join(signals)}")




