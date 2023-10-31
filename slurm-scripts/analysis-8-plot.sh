#!/bin/bash
#SBATCH --account=<ACCOUNT>
#SBATCH --job-name=analysis-plot
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=<EMAIL>
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --mem-per-cpu=10gb
#SBATCH --time=0:10:00
#SBATCH --output=analysis-plot_%j.log

# Get started
echo " "
echo "Job started on $(hostname) at $(date)"
echo " "

# Load modules
module purge
module load anaconda3/2021.05

# cd into project root
cd <ROOD_DIR>

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

# Set analysis ID
ANALYSIS_ID='aomic'

echo "Plotting ffa results..."
Rscript data-analysis/plot_results.R $ANALYSIS_ID --analysis_type ffa --smooth 0 --ncomps 12 --scree_plot > data-analysis/results/$ANALYSIS_ID/log-plot-ffa-K12
Rscript data-analysis/plot_results.R $ANALYSIS_ID --analysis_type ffa --smooth 0 --ncomps 25  > data-analysis/results/$ANALYSIS_ID/log-plot-ffa-K25
Rscript data-analysis/plot_results.R $ANALYSIS_ID --analysis_type ffa --smooth 0 --ncomps 50  > data-analysis/results/$ANALYSIS_ID/log-plot-ffa-K50
echo "DONE!"

echo "Plotting ica  results..."
Rscript data-analysis/plot_results.R $ANALYSIS_ID --analysis_type ica --smooth 0 --ncomps 12 --no_migp > data-analysis/results/$ANALYSIS_ID/log-plot-ica-K12
Rscript data-analysis/plot_results.R $ANALYSIS_ID --analysis_type ica --smooth 0 --ncomps 25 --no_migp > data-analysis/results/$ANALYSIS_ID/log-plot-ica-K25
Rscript data-analysis/plot_results.R $ANALYSIS_ID --analysis_type ica --smooth 0 --ncomps 50 --no_migp  > data-analysis/results/$ANALYSIS_ID/log-plot-ica-K50
echo "DONE!"
