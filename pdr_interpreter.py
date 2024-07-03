import sys
import argparse


def pdr_interpret(design, logfile):
    file = open(design + ".map", "r")
    mapping = [line.strip() for line in file.readlines()]
    file.close()
    latch_map = dict()
    input_map = dict()
    for line in mapping:
        if line.find("latch") < 0 and line.find("input") < 0:
            continue
        elif line.find("latch") >= 0:
            split = line.split(" ")
            latch_num = split[1]
            bit = split[2]
            signal_name = split[3]
            if latch_num not in latch_map.keys():
                latch_map[latch_num] = signal_name + "[" + bit + "]"
        elif line.find("input") >= 0:
            split = line.split(" ")
            input_num = split[1]
            bit = split[2]
            signal_name = split[3]
            if input_num not in input_map.keys():
                input_map[input_num] = signal_name + "[" + bit + "]"

    file = open(design + "_inv.pla", "r")
    content = file.read()
    file.close()
    latch_list = [
        latch_map[str(int(e[2:]))]
        for e in content[content.find(".ilb") + 4 : content.find(".ob")]
        .strip()
        .split(" ")
        if len(e) > 0
    ]
    # print(latch_list)

    log_output = "---------------Invariant Clauses-------------------- \n"
    invariant = content[content.find(".ob inv") + 7 : content.find(".e")].strip()
    for line in invariant.split("\n"):
        line = line[: line.find(" ")]
        literals = []
        for i in range(len(line)):
            if line[i] == "0":
                literals.append("!" + latch_list[i])
            elif line[i] == "1":
                literals.append(latch_list[i])
        clause = " && ".join(literals)
        log_output += "!(" + clause + ")\n"
    log_output += "\n\n\n"

    log_output += "---------------PDR Log--------------------\n"
    file = open(design + "_pdr.log", "r")
    log = [line.strip() for line in file.readlines()]
    file.close()
    for line in log:
        if line.find("cube") >= 0:
            if line.find("<prop=fail>") >= 0:
                log_output += line + "\n"
                continue
            cube = line[line.find("cube ") + 5 :].strip()
            cube = cube[: cube.find(" ")].strip()
            literals = []
            for i in range(len(cube)):
                if cube[i] == "0":
                    literals.append("!" + latch_map[str(i)])
                elif cube[i] == "1":
                    literals.append(latch_map[str(i)])
            line = line.replace(cube, "(" + " && ".join(literals) + ")")
            log_output += line + "\n"
        elif line.find(" =   ") >= 0:
            log_output += line + "\n"
        elif line.find(" sec") >= 0:
            log_output += line + "\n"

    if logfile == "./":
        logfile += design + "_pdr_interpreted.log"
    file = open(logfile, "w")
    file.write(log_output)
    file.close()

    cex_output = "---------------Counterexample-------------------- \n"
    file = open(design + ".cex", "r")
    cex = file.read().strip().split(" ")
    file.close()
    for line in cex:
        if line.find("pi") >= 0:
            input_num = line[line.find("pi") + 2 : line.find("@")].strip()
            line = line.replace(
                "pi" + input_num + "@", input_map[str(int(input_num))] + "@"
            )
            cex_output += line + "\n"
        elif line.find("lo") >= 0:
            latch_num = line[line.find("lo") + 2 : line.find("@")].strip()
            line = line.replace(
                "lo" + latch_num + "@", latch_map[str(int(latch_num))] + "@"
            )
            cex_output += line + "\n"
    cex_file = design + "_interpreted.cex"
    file = open(cex_file, "w")
    file.write(cex_output)
    file.close()


if __name__ == "__main__":
    parse = argparse.ArgumentParser()
    parse.add_argument("--design", dest="design", required=True, help="design name")
    parse.add_argument(
        "--output",
        dest="logfile",
        default="./",
        help="output file",
    )
    args = parse.parse_args()

    pdr_interpret(args.design, args.logfile)
