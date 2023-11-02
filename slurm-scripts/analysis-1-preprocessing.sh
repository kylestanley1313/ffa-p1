#!/bin/bash
#SBATCH --job-name=analysis-preprocessing
#SBATCH --mail-type=END,FAIL                      
#SBATCH -N 1                                      
#SBATCH -n 20                                      
#SBATCH --mem-per-cpu=5gb                         
#SBATCH --time=16:00:00                           
#SBATCH --output=analysis-preprocessing_%j.log

# Load modules
module purge
module load anaconda3/2021.05

# cd into project root
cd $1

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

# Create directories
mkdir -p data-analysis/data/$2
mkdir -p data-analysis/results/$2
mkdir -p $3/data-analysis/data/$2

echo "Preprocessing..."
Rscript data-analysis/preprocess.R $2 > data-analysis/results/$2/log-preprocessing
echo "DONE!"
echo " "

