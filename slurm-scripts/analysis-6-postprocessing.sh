#!/bin/bash
#SBATCH --account=<ACCOUNT>
#SBATCH --job-name=analysis-postprocessing
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=<EMAIL>
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
cd <ROOT_DIR>

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

# Set analysis ID
ANALYSIS_ID='aomic'
ALPHA='0'
DELTA='0.1'

echo "Tuning kappa..."
Rscript data-analysis/tune_kappa_analysis.R $ANALYSIS_ID --alpha $ALPHA --delta $DELTA --K 12 > data-analysis/results/$ANALYSIS_ID/log-tune-kappa-K12
Rscript data-analysis/tune_kappa_analysis.R $ANALYSIS_ID --alpha $ALPHA --delta $DELTA --K 25 > data-analysis/results/$ANALYSIS_ID/log-tune-kappa-K25
Rscript data-analysis/tune_kappa_analysis.R $ANALYSIS_ID --alpha $ALPHA --delta $DELTA --K 50 > data-analysis/results/$ANALYSIS_ID/log-tune-kappa-K50
echo "DONE!"
echo " "

echo "Postprocessing..."
Rscript data-analysis/postprocess_L_analysis.R $ANALYSIS_ID --alpha $ALPHA --delta $DELTA --K 12 > data-analysis/results/$ANALYSIS_ID/log-postprocess-L-K12
Rscript data-analysis/postprocess_L_analysis.R $ANALYSIS_ID --alpha $ALPHA --delta $DELTA --K 25 > data-analysis/results/$ANALYSIS_ID/log-postprocess-L-K25
Rscript data-analysis/postprocess_L_analysis.R $ANALYSIS_ID --alpha $ALPHA --delta $DELTA --K 50 > data-analysis/results/$ANALYSIS_ID/log-postprocess-L-K50
echo "DONE!"
echo " "
