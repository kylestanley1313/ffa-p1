#!/bin/bash
#SBATCH --job-name=analysis-splitting
#SBATCH --mail-type=END,FAIL
#SBATCH -N 1
#SBATCH -n 20
#SBATCH --mem-per-cpu=20gb
#SBATCH --time=8:00:00
#SBATCH --output=analysis-splitting_%j.log

# Load modules
module purge
module load anaconda3/2021.05

# cd into project root
cd $1

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

echo "Splitting..."
Rscript data-analysis/split_samples.R $2 > data-analysis/results/$2/log-splitting
echo "DONE!"
echo " "
