#!/usr/bin/bash

# Exit when any command fails
# set -e
OPTIND=1
# Function to display usage message
usage() {
  echo "Usage: $0 [-faserimpdbnu] [-O suffix] <design>"
  echo "Options:"
  echo "  -f   Flatten the netlist"
  echo "  -a   Transform the netlist into AIGER format"
  echo "  -s   Add shortcut signals"
  echo "  -w   Use wires as shortcut signals rather than registers"
  echo "  -e   Add implication signals"
  echo "  -r   Run ABC with PDR"
  echo "  -i   Interpret the log"
  echo "  -m   Use Symmetry"
  echo "  -p   Use predicate replacement"
  echo "  -d   Use iterative predicate replacement"
  echo "  -c   Silence all predicates at the beginning and incrementally release them"
  echo "  -q   Keep processing past first error"
  echo "  -n   Use existing aig, relation and map files"
  echo "  -u   Disable all input assumptions and let the input be unconstrained"
  echo "  -k   Run shortcut_signals.py with semantic enforce option"
  echo "  -t   Run shortcut_signals.py with eq_init option"
  echo "  -v   Verbose output"
  echo "  -g   Run rIC3"
  echo "  -l   Run rIC3 with ic3-inn"
  echo "  -y"  Verify the generate inductive invariant
  echo "  -O suffix  Specify a suffix for the output directory"
  echo "If no options are provided, all steps will run."
  exit 1
}

# Initialize flags as false
flatten=false
aig=false
shortcut=false
wireonly=false
pdr=false
interpret=false
implication=false
symmetry=false
predicate=false
iterative=false
reuse=false
suffix=""
unconstrained=""
incremental=false
senmantic_enforce=false
eqinit_predicate=false
rIC3=false
rIC3inn=false
verbose=false
verify=false

set -e

# Parse command-line options
while getopts "faswerimpdcqnubgktlvyO:" opt; do
  case $opt in
    f) flatten=true ;;
    a) aig=true ;;
    s) shortcut=true ;;
    w) wireonly=true ;;
    e) implication=true ;;
    r) pdr=true ;;
    i) interpret=true ;;
    m) symmetry=true ;;
    p) predicate=true ;;
    d) iterative=true ;;
    c) incremental=true ;;
    n) reuse=true ;;
    u) unconstrained="--no_assumption" ;;
    v) verbose=true ;;
    g) rIC3=true ;;
    l) rIC3inn=true ;;
    k) senmantic_enforce=true ;;
    t) eqinit_predicate=true ;;
    y) verify=true ;;
    O) suffix="_$OPTARG" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

# Ensure a design is provided
if [ $# -ne 1 ]; then
  usage
fi

design=$1
output_dir="output/${design}${suffix}_exp"
top="top"

# If no specific options are provided, run all steps
# if ! $flatten && ! $aig && ! $shortcut && ! $pdr && ! $interpret && ! $implication && ! $rIC3 && ! $rIC3inn; then
#   flatten=true
#   aig=true
#   shortcut=true
#   pdr=true
#   interpret=true
#   implication=true
# fi



# Create the output directory
if ! $reuse; then
  rm -f "${output_dir}"/*
  mkdir -p "${output_dir}"
fi

file="${design}"




# Step 1: Flatten the Verilog netlist
if $flatten; then
  echo "Flattening the netlist for ${design}..."
  if  ! $reuse; then
    python3 scripts/transform_verilog.py \
      --input "verilog/${file}.sv" \
      --output "${output_dir}/flatten.sv" \
      --top "${top}" \
      --option flatten \
      $unconstrained
  fi
  file="flatten"
fi

# Step 2: Add shortcut signals and
if $shortcut || $implication; then
  echo "Adding shortcut signals to ${design}..."
  option="-"
  if $shortcut; then
    option="${option}s"
  fi
  if $wireonly; then
    option="${option}w"
  fi
  if $implication; then
    option="${option}i"
  fi
  if $senmantic_enforce; then
    option="${option}k"
  fi
  if $eqinit_predicate; then
    option="${option}z"
  fi
  if  ! $reuse; then
    python3 scripts/shortcut_signals.py \
      --input "${output_dir}/${file}.sv" \
      --output "${output_dir}/shortcut.sv" \
      --top "${top}" \
      "${option}"
  fi
  file="shortcut"
fi

# Step 3: Transform the Verilog to AIGER format
if $aig && ! $reuse; then
  echo "Transforming Verilog to AIGER format for ${design}..."
  python3 scripts/transform_verilog.py \
    --input "${output_dir}/${file}.sv" \
    --output "${output_dir}/${file}.aig" \
    --top "${top}" \
    --option verilog_to_aig
fi

pdr_commands="read ${output_dir}/${file}.aig;
    fold;
    pdr -v -d -T 3600 -I ${output_dir}/${file}.pla -R ${output_dir}/${file}.relation"
if $verbose; then
  pdr_commands="${pdr_commands} -w"
fi
if $symmetry; then
  pdr_commands="${pdr_commands} -s"
fi
if $predicate; then
  pdr_commands="${pdr_commands} -l"
fi
if $iterative; then
  pdr_commands="${pdr_commands} -b"
fi
if $incremental; then
  pdr_commands="${pdr_commands} -E"
fi
pdr_commands="${pdr_commands}; write_cex -n -m -f ${output_dir}/${file}.cex;"


# If it is SE_leakymul_miter or smallboom_miter_clean, then directly copy existing files to save time
version="original"
if $shortcut; then
  version="shortcut"
fi
if $rIC3inn; then
  version="shortcut_inn"
fi  

# if $reuse; then
#   echo "Copying existing files for ${design}..."

#   cp -f "output/file_reused/${design}/${version}.aig" "${output_dir}/${file}.aig"
#   cp -f "output/file_reused/${design}/${version}.relation" "${output_dir}/${file}.relation"
#   cp -f "output/file_reused/${design}/${version}.map" "${output_dir}/${file}.map"

# fi

# Step 4: Run ABC with PDR
if $pdr; then
  echo "Running ABC with PDR for ${design}..."
  echo "PDR commands are: ${pdr_commands}"
  abc_exp -c "${pdr_commands}" > "${output_dir}/pdr_${file}.log"
fi

map_path="--model-map ${output_dir}/${file}.map"
relation_path="--relation-file ${output_dir}/${file}.relation"
if $verbose; then
export RUST_LOG=trace
fi

rIC3_options=""
if $symmetry; then
  rIC3_options="${rIC3_options} --symmetry"
fi
# Step 4: Run rIC3 or rIC3-inn
if $rIC3; then
  rIC3_command="rIC3_exp ${output_dir}/${file}.aig --engine ic3 ${map_path} ${relation_path} ${rIC3_options} ${output_dir}/${file}.aig"
  echo "Running rIC3 for ${design}..."
  echo $rIC3_command
  eval "$rIC3_command" > "${output_dir}/ric3_${file}.log" 2>&1
fi
if $rIC3inn; then
  rIC3_command="rIC3_exp ${output_dir}/${file}.aig --engine ic3 --ic3-inn ${map_path} ${relation_path} ${rIC3_options} ${output_dir}/${file}.aig"
  echo "Running rIC3 for ${design}..."
  echo $rIC3_command
  eval "$rIC3_command" > "${output_dir}/ric3_${file}.log" 2>&1
fi

# Step 5: Interpret the PDR log
if $interpret; then
  echo "Interpreting the PDR log for ${design}..."
  python3 scripts/pdr_interpreter.py \
    --log "${output_dir}/pdr_${file}.log" \
    --map "${output_dir}/${file}.map" \
    --inv "${output_dir}/${file}.pla" \
    --output "${output_dir}/pdr_${file}_interpreted.log" \
    --cex "${output_dir}/${file}.cex"
fi

# echo "${option}"


if $verify; then
# Verify the inductive invariant
echo "Verifying the inductive invariant for ${design}..."

sym_flag=""
if $symmetry; then
sym_flag="--symmetry"
fi

python3 scripts/expand_inv.py \
    --log "${output_dir}/pdr_${file}_interpreted.log" \
    --map "${output_dir}/${file}.map" \
    --output "${output_dir}/expand_inv.log" \
    $sym_flag \



# python3 scripts/transform_inv.py \
#     --input "${output_dir}/expand_inv.log" \
#     --map "output/original_circuit/${design}.map" \
#     --output "${output_dir}/expand_inv.pla" \

# verify_commands="&read output/original_circuit/${design}.aig;
#                 read ${output_dir}/expand_inv.pla;
#                 inv_put;
#                 inv_check -v"
python3 scripts/transform_inv.py \
    --input "${output_dir}/expand_inv.log" \
    --map "${output_dir}/${file}.map" \
    --output "${output_dir}/expand_inv.pla" \



verify_commands="&read ${output_dir}/${file}.aig;
                read ${output_dir}/expand_inv.pla;
                inv_put;
                inv_check" 

abc_exp -c "${verify_commands}" >> "${output_dir}/pdr_${file}_interpreted.log"

fi

grep  " : " "${output_dir}/pdr_${file}_interpreted.log"
grep  -E -A 200 -m 1 "(Verification .* successful)|(Block =)|(SolverStatistic.*)" "${output_dir}/pdr_${file}_interpreted.log"


echo "Script completed."
