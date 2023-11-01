#!/bin/bash
#SBATCH --job-name=simulation-rank
#SBATCH --mail-type=END,FAIL
#SBATCH -N 1
#SBATCH -n 20
#SBATCH --mem-per-cpu=20gb
#SBATCH --time=01:00:00
#SBATCH --output=simulation-rank_%j.log

# Get started
echo " "
echo "Job started on $(hostname) at $(date)"
echo " "

# Load modules
module purge
module load matlab/R2023a
module load anaconda3/2021.05

# cd into project root
cd $1

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

echo "Tuning alpha..."
matlab -nodisplay -nosplash -r "add_paths; tune_alpha('$2', true); exit" > simulation/results/$2/log-tune-alpha-rank
echo "DONE!"
echo " "

echo "Selecting rank..."
matlab -nodisplay -nosplash -r "add_paths; select_rank('$2'); exit" > simulation/results/$2/log-rank-select