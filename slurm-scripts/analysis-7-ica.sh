#!/bin/bash
#SBATCH --account=<ACCOUNT>
#SBATCH --job-name=analysis-ica
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=<EMAIL>
#SBATCH -N 1
#SBATCH -n 11
#SBATCH --mem-per-cpu=50gb
#SBATCH --time=00:30:00
#SBATCH --output=analysis-ica_%j.log

# Get started
echo " "
echo "Job started on $(hostname) at $(date)"
echo " "

# Load modules
module purge
module load anaconda3/2021.05
module load fsl/6.0.6.5

# cd into project root
cd <ROOT_DIR> 

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

# Set analysis ID
ANALYSIS_ID='aomic'

echo "Running MELODIC..."
Rscript data-analysis/melodic_ica.R $ANALYSIS_ID --slice --sigma 0 --no_migp --nonlinearity pow3 --num_comps 12 > data-analysis/results/$ANALYSIS_ID/log-melodic-K12
Rscript data-analysis/melodic_ica.R $ANALYSIS_ID --slice --sigma 0 --no_migp --nonlinearity pow3 --num_comps 25 > data-analysis/results/$ANALYSIS_ID/log-melodic-K25
Rscript data-analysis/melodic_ica.R $ANALYSIS_ID --slice --sigma 0 --no_migp --nonlinearity pow3 --num_comps 50 > data-analysis/results/$ANALYSIS_ID/log-melodic-K50
echo "DONE!"

