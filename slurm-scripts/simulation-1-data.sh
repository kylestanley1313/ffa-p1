#!/bin/bash
#SBATCH --job-name=simulation-data
#SBATCH --mail-type=END,FAIL
#SBATCH -N 1
#SBATCH -n 20
#SBATCH --mem-per-cpu=20gb
#SBATCH --time=8:00:00
#SBATCH --output=simulation-data_%j.log

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

# Create directories
mkdir -p simulation/data/$2
mkdir -p simulation/results/$2
mkdir -p $3/simulation/data/$2

# Setup simulation
echo "Setting up simulation..."
Rscript simulation/setup_simulation.R $2 > simulation/results/$2/log-setup-simulation
echo "DONE!"
echo " "

# Simulate Data
echo "Simulating data..."
Rscript simulation/simulate_data.R $2 > simulation/results/$2/log-simulate-data
echo "DONE!"
echo " "

# Split Data
echo "Splitting data..."
Rscript simulation/split_data.R $2 > simulation/results/$2/log-split-data
echo "DONE!"
echo " "