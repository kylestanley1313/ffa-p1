#!/bin/bash
#SBATCH --account=<ACCOUNT>
#SBATCH --job-name=analysis-scree-plot
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=<EMAIL>
#SBATCH -N 1
#SBATCH -n 11
#SBATCH --mem-per-cpu=20gb
#SBATCH --time=3:00:00
#SBATCH --output=analysis-scree-plot_%j.log

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
KMAX='100'
ALPHA='0'
DELTA='0.1'

echo "Creating scree plot..."
matlab -nodisplay -nosplash -r "add_paths; create_scree_plot('$ANALYSIS_ID', $KMAX, $ALPHA, $DELTA); exit" > data-analysis/results/$ANALYSIS_ID/log-scree-plot
echo "DONE!"
echo " "
