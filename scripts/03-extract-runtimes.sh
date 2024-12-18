#!/usr/bin/env bash

# Bash 'strict' mode
set -e # Exit if any command has a non-zero exit status.
set -o pipefail # If any command in a pipeline fails, use its return code as the pipeline's return code.
set -u # Fail on unset variables.
IFS=$'\n\t' # Split only on newlines and tabs, not spaces

source "${BASH_SOURCE%/*}/conf.sh"
source "${BASH_SOURCE%/*}/helper.sh"

usage() {
    >&2 echo "$(basename "$0") <log-dir>"
}

if [[ $# != 1 ]]; then
    usage
    exit "$EXIT_FAILURE"
fi

LOG_DIR="$1"

if [[ ! -d "$LOG_DIR" ]]; then
   echo "$LOG_DIR does not exist or is not a directory."
   exit "$EXIT_FAILURE"
fi

echo "dataset,variant,ncpu,time_s"
for logfile in "$LOG_DIR"/*.log; do
    dataset="$(extract-substr "$logfile" "^\[[0-9:]+] Loading binary alignment from file: data\/(.*)\/msa\.rba")"
    basename_logfile="$(basename "$logfile")"
    variant="${basename_logfile%%_*}"
    ncpu="$(extract-substr "$logfile" "^\s*parallelization: MPI \(([0-9]+) ranks\)$")"
    time="$(extract-substr "$logfile" "^Elapsed time: ([0-9]*\.[0-9]*) seconds")"
    echo "$dataset,$variant,$ncpu,$time"
done
