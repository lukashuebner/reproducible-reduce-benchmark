#!/usr/bin/env sh

module purge --silent || true
module load spack/23.1.0
module load lrztools
module restore gcc-intelmpi
module load slurm_setup
module list
