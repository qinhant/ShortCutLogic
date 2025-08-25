
import sys, json, re

DESIGN_PATTERNS = [
    re.compile(r"Get fanout.*\b([\w\-]+)\.sv", re.IGNORECASE),
    re.compile(r"Analyzing Verilog file '.*?/([\w\-]+)\.sv'", re.IGNORECASE),
]

def detect_design(line, current):
    s = line.strip()
    for pat in DESIGN_PATTERNS:
        m = pat.search(s)
        if m:
            return m.group(1)
    return current

def extract_blocks(text):
    lines = text.splitlines()
    results = []
    in_block = False
    collecting = False
    current_signals = []
    current_target = None
    current_design = None

    for raw in lines:
        s = raw.rstrip("\n")

        # Update design whenever a matching line appears
        current_design = detect_design(s, current_design)

        # Start of a block section
        if s.strip() == "=========================" and not in_block:
            in_block = True
            collecting = False
            current_signals = []
            current_target = None
            continue

        # End of the block section
        if in_block and s.strip().startswith("-------------------------"):
            if current_signals:
                # Deduplicate while preserving order
                seen = set()
                fanout = []
                for sig in current_signals:
                    if sig not in seen:
                        seen.add(sig)
                        fanout.append(sig)
                results.append((current_design, current_target, fanout))
            in_block = False
            collecting = False
            current_signals = []
            current_target = None
            continue

        if in_block:
            # capture Target line (appears before the signals header)
            if s.strip().startswith("Target:"):
                parts = s.split("Target:", 1)[1].strip().split()
                current_target = parts[0] if parts else None

            # Start collecting when we hit the first indented signal line
            if not collecting:
                if s.startswith((" ", "\t")) and s.strip():
                    collecting = True

            if collecting:
                if s.startswith((" ", "\t")) and s.strip():
                    token = s.strip().split()[0]
                    if token not in {"Task:", "Target:", "Result", "Type:", "signals"}:
                        current_signals.append(token)

    return results

def main():
    in_path = sys.argv[1] if len(sys.argv) > 1 else "input.txt"
    out_path = sys.argv[2] if len(sys.argv) > 2 else "fanout_all.json"

    with open(in_path, "r", encoding="utf-8") as f:
        text = f.read()

    blocks = extract_blocks(text)

    out = [
        {"design": design or "unknown", "target": tgt, "fanout": fanout}
        for (design, tgt, fanout) in blocks
    ]

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2)

if __name__ == "__main__":
    main()
