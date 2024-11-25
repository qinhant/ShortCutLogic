#!/usr/bin/bash

# Exit when any command fails
# set -e 
OPTIND=1
# Function to display usage message
usage() {
  echo "Usage: $0 [-faseri] [-O suffix] <design>"
  echo "Options:"
  echo "  -f   Flatten the netlist"
  echo "  -a   Transform the netlist into AIGER format"
  echo "  -s   Add shortcut signals"
  echo "  -e   Add implication signals"
  echo "  -r   Run ABC with PDR"
  echo "  -i   Interpret the log"
  echo "  -O suffix  Specify a suffix for the output directory"
  echo "If no options are provided, all steps will run."
  exit 1
}

# Initialize flags as false
flatten=false
aig=false
shortcut=false
pdr=false
interpret=false
implication=false
suffix=""

# Parse command-line options
while getopts "faseriO:" opt; do
  case $opt in
    f) flatten=true ;;
    a) aig=true ;;
    s) shortcut=true ;;
    e) implication=true ;;
    r) pdr=true ;;
    i) interpret=true ;;
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
output_dir="output/${design}${suffix}"
top="top"

# If no specific options are provided, run all steps
if ! $flatten && ! $aig && ! $shortcut && ! $pdr && ! $interpret && ! $implication; then
  flatten=true
  aig=true
  shortcut=true
  pdr=true
  interpret=true
  implication=true
fi



# Create the output directory
mkdir -p "${output_dir}"
rm -f "${output_dir}"/*

file="${design}"
# Step 1: Flatten the Verilog netlist
if $flatten; then
  echo "Flattening the netlist for ${design}..."
  python3 scripts/transform_verilog.py \
    --input "verilog/${file}.sv" \
    --output "${output_dir}/flatten.sv" \
    --top "${top}" \
    --option flatten
  file="flatten"
fi

# Step 2: Add shortcut signals and 
if $shortcut || $implication; then
  echo "Adding shortcut signals to ${design}..."
  option="-"
  if $shortcut; then
    option="${option}s"
  fi
  if $implication; then
    option="${option}i"
  fi
  python3 scripts/shortcut_signals.py \
    --input "${output_dir}/${file}.sv" \
    --output "${output_dir}/shortcut.sv" \
    --top "${top}" \
    "${option}"
  file="shortcut"
fi

# Step 3: Transform the Verilog to AIGER format
if $aig; then
  echo "Transforming Verilog to AIGER format for ${design}..."
  python3 scripts/transform_verilog.py \
    --input "${output_dir}/${file}.sv" \
    --output "${output_dir}/${file}.aig" \
    --top "${top}" \
    --option verilog_to_aig
fi

# Step 4: Run ABC with PDR
if $pdr; then
  echo "Running ABC with PDR for ${design}..."
  abc_exp -c "
    read ${output_dir}/${file}.aig;
    fold;
    pdr -v -w -d -I ${output_dir}/${file}.pla;
    write_cex -n -m -f ${output_dir}/${file}.cex
  " > "${output_dir}/pdr_${file}.log"
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

echo "${option}"

echo "Script completed."
