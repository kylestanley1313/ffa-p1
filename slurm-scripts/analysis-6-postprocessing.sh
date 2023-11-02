#!/bin/bash
#SBATCH --job-name=analysis-postprocessing
#SBATCH --mail-type=END,FAIL
#SBATCH -N 1
#SBATCH -n 11
#SBATCH --mem-per-cpu=10gb
#SBATCH --time=00:30:00
#SBATCH --output=analysis-postprocessing_%j.log

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

# Set analysis ID
ALPHA='0'
DELTA='0.1'

echo "Tuning kappa..."
Rscript data-analysis/tune_kappa_analysis.R $2 --alpha $ALPHA --delta $DELTA --K 12 > data-analysis/results/$2/log-tune-kappa-K12
Rscript data-analysis/tune_kappa_analysis.R $2 --alpha $ALPHA --delta $DELTA --K 25 > data-analysis/results/$2/log-tune-kappa-K25
Rscript data-analysis/tune_kappa_analysis.R $2 --alpha $ALPHA --delta $DELTA --K 50 > data-analysis/results/$2/log-tune-kappa-K50
echo "DONE!"
echo " "

echo "Postprocessing..."
Rscript data-analysis/postprocess_L_analysis.R $2 --alpha $ALPHA --delta $DELTA --K 12 > data-analysis/results/$2/log-postprocess-L-K12
Rscript data-analysis/postprocess_L_analysis.R $2 --alpha $ALPHA --delta $DELTA --K 25 > data-analysis/results/$2/log-postprocess-L-K25
Rscript data-analysis/postprocess_L_analysis.R $2 --alpha $ALPHA --delta $DELTA --K 50 > data-analysis/results/$2/log-postprocess-L-K50
echo "DONE!"
echo " "
