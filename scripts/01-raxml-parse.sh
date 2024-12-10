#!/usr/bin/env bash

# Bash 'strict' mode
set -e # Exit if any command has a non-zero exit status.
set -o pipefail # If any command in a pipeline fails, use its return code as the pipeline's return code.
set -u # Fail on unset variables.
IFS=$'\n\t' # Split only on newlines and tabs, not spaces

source "${BASH_SOURCE%/*}/conf.sh"
source "${BASH_SOURCE%/*}/helper.sh"

# For each dataset
for dataset_dir in "$DATA_DIR"/*; do
  dataset="$(basename "$dataset_dir")"
  msa_file="$DATA_DIR/$dataset/msa.phy"
  model_file="$DATA_DIR/$dataset/model"
  log_file="${msa_file}.raxml.log"
  rba_file="${msa_file}.raxml.rba"

  "$RAXML_NG" --parse --msa "$msa_file" --model "$(<"$model_file")"

  mv "$rba_file" "$DATA_DIR/$dataset/raxml.rba"

  # Extract the number of PE recommended by RAxML-NG
  num_pe_file="$DATA_DIR/$dataset/num_pe"
  extract-substr \
    "$log_file" \
    "^\* Recommended number of threads \/ MPI processes: ([0-9][0-9]*)" \
    > "$num_pe_file"

  mv "$log_file" "$OUTPUT_DIR/raxml-parse/$dataset.log"
done

