#!/bin/bash
#SBATCH --account=<ACCOUNT>
#SBATCH --job-name=analysis-alpha-testing
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=<EMAIL>
#SBATCH -N 1
#SBATCH -n 11
#SBATCH --mem-per-cpu=20gb
#SBATCH --time=01:00:00
#SBATCH --output=analysis-alpha-testing_%j.log

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
ALPHAS='[0 1 2 3 4 5]'
K='10'
LNAME='Lhat'

echo "Testing different alphas..."
matlab -nodisplay -nosplash -r "add_paths; estimate_L_analysis('$ANALYSIS_ID', '$LNAME', $ALPHAS, 0.1, $K); exit" > data-analysis/results/$ANALYSIS_ID/log-alpha-testing
echo "DONE!"
echo " "

echo "Plotting smoothed loadings..."
Rscript data-analysis/plot_smoothed_loadings.R $ANALYSIS_ID --alphas "$ALPHAS" --K $K
echo "DONE!"
echo " "
