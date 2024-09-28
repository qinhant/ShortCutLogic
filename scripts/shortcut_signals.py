import itertools
import re
import textwrap
from collections import defaultdict
from collections.abc import Callable
from dataclasses import dataclass, KW_ONLY


RegId = str
CopyId = str


@dataclass
class RegCopy:
    id: RegId
    _: KW_ONLY
    copy_id: CopyId
    full_name: str
    width: str = ""


@dataclass
class ShortcutSignalsConfig:
    """ Settings for shortcut signals. """
    _: KW_ONLY
    parse_reg : Callable[[str], RegCopy | None]
    original : CopyId
    shortcut_prefix : str



def add_shortcut_signals(filein, fileout, *, cfg: ShortcutSignalsConfig):

    commentp = re.compile(r"\(\*.*\*\)")
    comments = re.compile(r"/\*.*\*/")
    comment = re.compile(rf"({commentp.pattern}|{comments.pattern})")
    skip = re.compile(rf"(\s|{comment.pattern})*")
    skipline = re.compile(rf"^{skip.pattern}$")

    decl = re.compile(r"\s*(module|wire|reg|input|output|inout).*")
    decl_reg = re.compile(r"\s*reg .*")

    assign = re.compile(
        r"(?P<lhs>\s*(assign )?(?P<var>[\w\.\\]+)\s*(=|<=))"
        rf"\s*(?P<rhs>.+);(?P<comments>{skip.pattern})")
    endmodule = re.compile(r"\s*endmodule")

    with open(filein, 'r') as fin, open(fileout, 'w') as fout:
        fout.write("/* Added shortcut signals via shortcut_signals.py */\n")
        lines = iter(fin)

        orig_regs: dict[RegId, RegCopy] = {}
        copy_regs: dict[RegId, list[RegCopy]] = defaultdict(list)

        # track registers
        for l in lines:
            if skipline.match(l):
                fout.write(l)
                continue

            if not decl.match(l):
                lines = itertools.chain([l], lines)
                break

            if decl_reg.match(l) and (reg := cfg.parse_reg(l)):
                if reg.copy_id == cfg.original:
                    orig_regs[reg.id] = reg
                else:
                    copy_regs[reg.id].append(reg)

            fout.write(l)

        # create shortcuts
        eq_signals: dict[str, str] = {}  # copy name -> eq signal
        shortcuts: dict[str, str] = {}  # copy name -> shortcut
        shortcut_assigns = []

        for id, r in orig_regs.items():
            for rc in copy_regs[id]:
                copy_id = re.sub(r'(\\|\.)', '', rc.copy_id)
                signal = f"{cfg.shortcut_prefix}eq_{id}_{copy_id}"
                shortcut = f"{cfg.shortcut_prefix}{copy_id}.{id}"
                eq_signals[rc.full_name] = signal
                shortcuts[rc.full_name] = shortcut
                fout.write(f"  reg {signal} = 1;\n")
                width = f" {rc.width}" if rc.width else ""
                fout.write(f"  wire{width} {shortcut};\n")
                shortcut_assigns.append(
                    f"  assign {shortcut} = {signal} ? {r.full_name} : {rc.full_name};\n")

        fout.write(''.join(shortcut_assigns))

        # track assignments for setting equality signals
        assignments: dict[str, str] = {}
        for l in lines:
            if endmodule.match(l):
                lines = itertools.chain([l], lines)
                break
            if match := assign.match(l):
                lhs = match.group('lhs')
                var = match.group('var')
                rhs = match.group('rhs')
                comments = match.group('comments')
                for copy, shortcut in shortcuts.items():
                    rhs = rhs.replace(copy, shortcut)
                assert var not in assignments, "not implemented: handle repeated assignment"
                assignments[var] = rhs
                l = f"{lhs} {rhs};{comments}"
            fout.write(l)

        # set equality signals
        for id, r in orig_regs.items():
            for rc in copy_regs[id]:
                orig_assign = assignments[r.full_name]
                copy_assign = assignments[rc.full_name]
                eq_signal = eq_signals[rc.full_name]
                # FIXME, track each copy's clock
                fout.write(textwrap.indent(textwrap.dedent(f"""
                  always @(posedge clk)
                    {eq_signal} <= {orig_assign} == {copy_assign};
                """).removeprefix('\n'), "  "))

        for l in lines:
            fout.write(l)




if __name__ == "__main__":
    import argparse
    import sys

    parse = argparse.ArgumentParser()
    parse.add_argument(
        "--input", dest="input_path", required=True, help="input_log_path"
    )
    parse.add_argument(
        "--output",
        dest="output_path",
        required=True,
        help="output path",
    )
    parse.add_argument("--top", dest="top", required=True, help="top module")

    parse.add_argument(
        "--copy1_prefix", dest="prefix1", default="\\copy1.", help="prefix used to identify copy1"
    )

    parse.add_argument(
        "--copy2_prefix", dest="prefix2", default="\\copy2.", help="prefix used to identify copy2"
    )

    parse.add_argument(
        "--shortcut_prefix", dest="prefix_sc", default="\\shortcut.", help="prefix used for new shortcut signals"
    )

    args = parse.parse_args()
    if not args.input_path.endswith(".v") and not args.input_path.endswith(".sv"):
        print("Invalid input file, must be a .v or .sv file")
        sys.exit(1)
    if not args.output_path.endswith(".v") and not args.output_path.endswith(".sv"):
        print("Invalid input file, must be a .v or .sv file")
        sys.exit(1)

    prefix1 = re.escape(str(args.prefix1))
    prefix2 = re.escape(str(args.prefix2))

    copy_re = f"(?P<copy>({prefix1}|{prefix2}))"
    width_re = r"\s*(?P<width>(\[\d+:\d+\]|))\s*"
    name_re = r"(?P<name>[\w\.\\]+)"
    fullname_re = fr"(?P<fullname>{copy_re}{name_re})"
    reg_re = re.compile(fr"\s*reg{width_re} {fullname_re}")

    def parse_reg(reg: str) -> RegCopy | None:
        match = reg_re.match(reg)
        if match is None:
            return None
        try:
            return RegCopy(
                match.group('name'),
                copy_id=match.group('copy'),
                width=match.group('width'),
                full_name=match.group('fullname')
            )
        except KeyError:
            return None

    cfg = ShortcutSignalsConfig(
        parse_reg=parse_reg,
        original=args.prefix1,
        shortcut_prefix=str(args.prefix_sc)
    )

    add_shortcut_signals(args.input_path, args.output_path, cfg=cfg)
