#!/bin/bash
#SBATCH --job-name=analysis-ica
#SBATCH --mail-type=END,FAIL
#SBATCH -N 1
#SBATCH -n 2
#SBATCH --mem-per-cpu=40gb
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
cd $1

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

echo "Running MELODIC..."
Rscript data-analysis/melodic_ica.R $2 --sigma 0.5 --num_comps 12 --no_migp --no_varnorm --nonlinearity pow3 > data-analysis/results/$2/log-ica-ica-K12
Rscript data-analysis/melodic_ica.R $2 --sigma 0.5 --num_comps 25 --no_migp --no_varnorm --nonlinearity pow3 > data-analysis/results/$2/log-ica-ica-K25
Rscript data-analysis/melodic_ica.R $2 --sigma 0.5 --num_comps 50 --no_migp --no_varnorm --nonlinearity pow3 > data-analysis/results/$2/log-ica-ica-K50
echo "DONE!"

