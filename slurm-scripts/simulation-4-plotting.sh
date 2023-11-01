#!/bin/bash
#SBATCH --job-name=simulation-plotting
#SBATCH --mail-type=END,FAIL
#SBATCH -N 1
#SBATCH -n 11
#SBATCH --mem-per-cpu=5gb
#SBATCH --time=00:20:00
#SBATCH --output=simulation-plotting_%j.log

# Get started
echo " "
echo "Job started on $(hostname) at $(date)"
echo " "

# Load modules
module purge
module load anaconda3/2021.05

# cd into project root
cd $1

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

echo "Plotting simulation results..."
Rscript simulation/plot_results.R $2 > simulation/results/$2/log-plot-results
echo "DONE!"
echo " "