#!/bin/bash
#SBATCH --account=<ACCOUNT>
#SBATCH --job-name=analysis-preprocessing
#SBATCH --mail-type=END,FAIL                      
#SBATCH --mail-user=<EMAIL>               
#SBATCH -N 1                                      
#SBATCH -n 20                                      
#SBATCH --mem-per-cpu=5gb                         
#SBATCH --time=16:00:00                           
#SBATCH --output=analysis-preprocessing_%j.log

# Load modules
module purge
module load anaconda3/2021.05

# cd into project root
cd <ROOT_DIR>

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

# Set analysis ID
ANALYSIS_ID='aomic'

# Create directories
mkdir -p data-analysis/data/$ANALYSIS_ID
mkdir -p data-analysis/results/$ANALYSIS_ID
mkdir -p <SCRATCH_ROOT_DIR>/data-analysis/data/$ANALYSIS_ID

echo "Preprocessing..."
Rscript data-analysis/preprocess.R $ANALYSIS_ID > data-analysis/results/$ANALYSIS_ID/log-preprocessing
echo "DONE!"
echo " "

