#!/usr/bin/env bash
#SBATCH --mem=80000mb
#SBATCH --output output/slurm-logs/%A.out
##SBATCH --error output/slurm-logs/%A.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=christoph.stelz@student.kit.edu
#SBATCH --account=pn72pu
#SBATCH --get-user-env
#SBATCH --ear=off
#SBATCH --switches=1
#SBATCH --constraint='work'
#SBATCH --chdir=/hppfs/work/pn72pu/di82yas/reprored

# Expected from the caller:
# --ntasks-per-node=...
# --nodes=...
# --time=...
# --partition=...
# $NAME
# $MODEL
# $MSA
# REPETITIONS=() space separated string
# VARIANTS=() space separated string

# Bash 'strict' mode
set -e # Exit if any command has a non-zero exit status.
set -o pipefail # If any command in a pipeline fails, use its return code as the pipeline return code.
set -u # Fail on unset variables.
IFS=$'\n\t' # Split only on newlines and tabs, not spaces

# Set up environment
source "scripts/conf.sh"
module purge --silent || true
module load spack/23.1.0
module restore gcc-intelmpi
module load slurm_setup
module list

# RAxML-NG settings
SIMD="avx2"
PRECISION="10"
RANDOM_SEED="42"
PATTERN_COMPRESSION="off"
SITE_REPEATS="off"
TIP_INNER="off"
STARTING_TREE="rand{1}"

declare -a REPETITIONS_ARR
declare -a VARIANTS_ARR
IFS=' ' read -ra REPETITIONS_ARR <<< $REPETITIONS
IFS=' ' read -ra VARIANTS_ARR <<< $VARIANTS
>&2 echo "-- ${#VARIANTS_ARR[@]} variants x ${#REPETITIONS_ARR[@]} repetitions"

# Check, if the caller provided us with all necessary information.
if [[ "$NAME" == "" ]]; then
  # shellcheck disable=SC2016
  >&2 echo '$NAME not set'
  exit 1
elif [[ "$MODEL" == "" ]]; then
  # shellcheck disable=SC2016
  >&2 echo '$MODEL not set'
  exit 1
elif [[ "$MSA" == "" ]]; then
  # shellcheck disable=SC2016
  >&2 echo '$MSA not set'
  exit 1
 elif [ ${#REPETITIONS_ARR[@]} -eq 0 ]; then
   # shellcheck disable=SC2016
   >&2 echo '$REPETITIONS is not an array or contains no elements'
   exit 1
 elif [ ${#VARIANTS_ARR[@]} -eq 0 ]; then
   # shellcheck disable=SC2016
   >&2 echo '$VARIANTS is not an array or contains no elements'
   exit 1
fi

declare -A EXECUTABLES
EXECUTABLES["reference"]="$REFERENCE_RAXML_NG"
EXECUTABLES["r2d2"]="$R2D2_RAXML_NG"
EXECUTABLES["reproblas"]="$REPROBLAS_RAXML_NG"
EXECUTABLES["reprogather"]="$REPROGATHER_RAXML_NG"
EXECUTABLES["reducebcast"]="$REDUCEBCAST_RAXML_NG"

for repetition in "${REPETITIONS_ARR[@]}"; do
  for variant in "${VARIANTS_ARR[@]}"; do
    >&2 echo "-- Running variant=$variant, repetition=$repetition"
    EXECUTABLE="${EXECUTABLES[$variant]}"
    PREFIX="$OUTPUT_DIR/${variant}_${SIMD}_msa-${NAME}_job-${SLURM_JOBID}_rep-${repetition}"

    mpiexec -n $SLURM_NTASKS \
      "$EXECUTABLE" \
      --prefix "$PREFIX" \
      --precision "$PRECISION" \
      --seed "$RANDOM_SEED" \
      --msa "$MSA" \
      --pat-comp "$PATTERN_COMPRESSION" \
      --site-repeats "$SITE_REPEATS" \
      --tip-inner "$TIP_INNER" \
      --simd "$SIMD" \
      --workers 1 \
      --threads 1 \
      --model "$MODEL" \
      --tree "$STARTING_TREE"
  done
done
