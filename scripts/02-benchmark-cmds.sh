#!/usr/bin/env bash

# Bash 'strict' mode
set -e # Exit if any command has a non-zero exit status.
set -o pipefail # If any command in a pipeline fails, use its return code as the pipeline's return code.
set -u # Fail on unset variables.
IFS=$'\n\t' # Split only on newlines and tabs, not spaces

source "${BASH_SOURCE%/*}/conf.sh"
source "${BASH_SOURCE%/*}/helper.sh"

if [[ $# != 2 ]]; then
  error_and_exit "usage: $0 <string-of-repetitions> <string-of-variants>"
fi

# Parse parameters
REPETITIONS_STR="$1"
VARIANTS_STR="$2"
declare -a REPETITIONS
declare -a VARIANTS
IFS=' ' read -ra REPETITIONS <<< "$REPETITIONS_STR"
IFS=' ' read -ra VARIANTS <<< "$VARIANTS_STR"
N_REPETITIONS="${#REPETITIONS[@]}"
N_VARIANTS="${#VARIANTS[@]}"

# Generate the sbatch commands
for dataset_dir in "$DATA_DIR"/*; do
  dataset="$(basename "$dataset_dir")"
  msa_file="$DATA_DIR/$dataset/msa.rba"
  model_file="$DATA_DIR/$dataset/model"
  time_file="$DATA_DIR/$dataset/time.s"
  pes_file="$DATA_DIR/$dataset/num_pe"

  # The time in time.s specifies the approximate time /per RAxML-NG run/
  # on this dataset. Therefore, multiply it by the number of runs.
  model="$(<"$model_file")"
  time_limit_s=$(( "$(<"$time_file")" * N_REPETITIONS * N_VARIANTS ))
  # Slurm also rounds up to full minutes
  time_limit_min=$(( (time_limit_s - 1 ) / 60 + 1 ))
  pes="$(<"$pes_file")"

  if (( pes < PES_PER_NODE )); then
    nodes=1
    ntasks_per_node="$pes"
  else
    # We are rounding down, thereby considering the parallelization level
    # suggested by RAxML-NG an upper estimate.
    nodes=$(( pes / PES_PER_NODE ))
    ntasks_per_node="$PES_PER_NODE"
  fi
  
  partition="micro"
  if [[ "$nodes" -gt 16 ]]; then
    partition="general"
  fi 

  echo "$SBATCH" \
    --ntasks-per-node="$ntasks_per_node" \
    --nodes="$nodes" \
    --time="$time_limit_min" \
    --partition="$partition" \
    --job-name="$dataset" \
    --export=\'"NAME=${dataset},MSA=${msa_file},MODEL=${model},REPETITIONS=$REPETITIONS_STR,VARIANTS=$VARIANTS_STR"\' \
    benchmark.sbatch
done
