#!/bin/bash
#SBATCH --account=<ACCOUNT>
#SBATCH --job-name=analysis-estimation
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=<EMAIL>
#SBATCH -N 1
#SBATCH -n 11
#SBATCH --mem-per-cpu=40gb
#SBATCH --time=00:30:00
#SBATCH --output=analysis-estimation_%j.log

# Get started
echo " "
echo "Job started on $(hostname) at $(date)"
echo " "

# Load modules
module purge
module load matlab/R2023a
module load anaconda3/2021.05

# cd into project root
cd <ROOT_DIR>

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

# Set analysis ID
ANALYSIS_ID='aomic'
LNAME='Lhat'
ALPHA='0'
DELTA='0.1'

echo "Estimating loadings for full data..."
matlab -nodisplay -nosplash -r "add_paths; estimate_L_analysis('$ANALYSIS_ID', '$LNAME', $ALPHA, $DELTA, 12); exit" > data-analysis/results/$ANALYSIS_ID/log-alpha-estimation-K12
matlab -nodisplay -nosplash -r "add_paths; estimate_L_analysis('$ANALYSIS_ID', '$LNAME', $ALPHA, $DELTA, 25); exit" > data-analysis/results/$ANALYSIS_ID/log-alpha-estimation-K25
matlab -nodisplay -nosplash -r "add_paths; estimate_L_analysis('$ANALYSIS_ID', '$LNAME', $ALPHA, $DELTA, 50); exit" > data-analysis/results/$ANALYSIS_ID/log-alpha-estimation-K50
echo "DONE!"
echo " "

echo "Estimating loadings for training data..."
matlab -nodisplay -nosplash -r "add_paths; estimate_L_analysis('$ANALYSIS_ID', '$LNAME', $ALPHA, $DELTA, 12, 1, 'train'); exit" > data-analysis/results/$ANALYSIS_ID/log-alpha-estimation-train-K12
matlab -nodisplay -nosplash -r "add_paths; estimate_L_analysis('$ANALYSIS_ID', '$LNAME', $ALPHA, $DELTA, 25, 1, 'train'); exit" > data-analysis/results/$ANALYSIS_ID/log-alpha-estimation-train-K25
matlab -nodisplay -nosplash -r "add_paths; estimate_L_analysis('$ANALYSIS_ID', '$LNAME', $ALPHA, $DELTA, 50, 1, 'train'); exit" > data-analysis/results/$ANALYSIS_ID/log-alpha-estimation-train-K50
echo "DONE!"
