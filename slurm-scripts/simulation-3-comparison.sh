#!/bin/bash
#SBATCH --job-name=simulation-comparison
#SBATCH --mail-type=END,FAIL
#SBATCH -N 1
#SBATCH -n 11
#SBATCH --mem-per-cpu=20gb
#SBATCH --time=12:00:00
#SBATCH --output=simulation-comparison_%j.log

# Get started
echo " "
echo "Job started on $(hostname) at $(date)"
echo " "

# Load modules
module purge
module load matlab/R2023a
module load anaconda3/2021.05

# cd into project root
cd $1

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

echo "Estimating L via KL..."
Rscript simulation/estimate_L_via_KL.R $2 > simulation/results/$2/log-estimate-L-kl
echo "DONE!"
echo " "

echo "Tuning sigma..."
Rscript simulation/tune_sigma.R $2 > simulation/results/$2/log-tune-sigma
echo "DONE!"
echo " "

echo "Estimating L via MELODIC..."
Rscript simulation/estimate_L_via_MELODIC.R $2 > simulation/results/$2/log-estimate-L-melodic
echo "DONE!"
echo " "

echo "Estimating L via MVFA..."
matlab -nodisplay -nosplash -r "add_paths; estimate_L('$2', false, false); exit" > simulation/results/$2/log-estimate-L-mvfa
echo "DONE!"
echo " "

echo "Estimating L via DP..."
matlab -nodisplay -nosplash -r "add_paths; estimate_L('$2', true, false, NaN); exit" > simulation/results/$2/log-estimate-L-dp
echo "DONE!"
echo " "

echo "Tuning alpha..."
matlab -nodisplay -nosplash -r "add_paths; tune_alpha('$2', false); exit" > simulation/results/$2/log-tune-alpha-comparison
echo "DONE!"
echo " "

echo "Estimating L via DPS..."
matlab -nodisplay -nosplash -r "add_paths; estimate_L('$2', true, true, NaN); exit" > simulation/results/$2/log-estimate-L-dps
echo "DONE!"
echo " "

echo "Tuning kappa..."
Rscript simulation/tune_kappa.R $2 > simulation/results/$2/log-tune-kappa
echo "DONE!"
echo " "

echo "Postprocess L..."
Rscript simulation/postprocess_L.R $2 > simulation/results/$2/log-postprocess-L
echo "DONE!"
echo " "