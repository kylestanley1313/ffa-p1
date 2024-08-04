#!/bin/bash
#SBATCH --job-name=simulation-melodic
#SBATCH --mail-type=END,FAIL
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --mem-per-cpu=5gb
#SBATCH --time=00:20:00
#SBATCH --output=simulation-melodic_%j.log

# Get started
echo " "
echo "Job started on $(hostname) at $(date)"
echo " "

# Load modules
module purge
module load matlab/R2023a
module load anaconda3/2021.05

# Set globals
ROOT='/Users/kylestanley/repos/ffa-p1'
FSL_PATH='/Users/kylestanley/fsl/share/fsl/bin'
DESIGN_ID='melodic-1'

# cd into project root
cd $ROOT

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1


echo "Plot true loadings..."
Rscript simulation/plot_results_melodic.R $DESIGN_ID true
echo "DONE!"
echo " "

echo "Tuning alpha..."
matlab -nodisplay -nosplash -r "add_paths; tune_alpha('$DESIGN_ID', false); exit" > simulation/results/$DESIGN_ID/log-tune-alpha-melodic
echo "DONE!"
echo " "


echo " "
echo "=========================================================================="
echo " "


echo "Estimating L via DPS (K = 8)..."
matlab -nodisplay -nosplash -r "add_paths; estimate_L('$DESIGN_ID', true, true, 8); exit" > simulation/results/$DESIGN_ID/log-melodic-estimate-L-dps-K8
echo "DONE!"
echo " "

echo "Tuning kappa (K = 8)..."
Rscript simulation/tune_kappa.R $DESIGN_ID > simulation/results/$DESIGN_ID/log-melodic-tune-kappa-K8
echo "DONE!"
echo " "

echo "Postprocess L (K = 8)..."
Rscript simulation/postprocess_L.R $DESIGN_ID > simulation/results/$DESIGN_ID/log-melodic-postprocess-L-K8
echo "DONE!"
echo " "

echo "Estimating L via MELODIC (K = 8)..."
Rscript simulation/estimate_L_via_MELODIC.R $DESIGN_ID $FSL_PATH --sigma 1.0 --no_migp --nonlinearity pow3 --num_comps 8 > data-analysis/results/$DESIGN_ID/simulation/results/$2/log-melodic-estimate-L-melodic-K8
echo "DONE!"
echo " "

echo "Plotting results (K = 8)..."
Rscript simulation/plot_results_melodic.R $DESIGN_ID ffa --ncomps 8 --archive
Rscript simulation/plot_results_melodic.R $DESIGN_ID ica --ncomps 8 --archive
echo "DONE!"
echo " "


echo " "
echo "=========================================================================="
echo " "


echo "Estimating L via DPS (K = 25)..."
matlab -nodisplay -nosplash -r "add_paths; estimate_L('$DESIGN_ID', true, true, 25); exit" > simulation/results/$DESIGN_ID/log-melodic-estimate-L-dps-K25
echo "DONE!"
echo " "

echo "Tuning kappa (K = 25)..."
Rscript simulation/tune_kappa.R $DESIGN_ID > simulation/results/$DESIGN_ID/log-melodic-tune-kappa-K25
echo "DONE!"
echo " "

echo "Postprocess L (K = 25)..."
Rscript simulation/postprocess_L.R $DESIGN_ID > simulation/results/$DESIGN_ID/log-melodic-postprocess-L-K25
echo "DONE!"
echo " "

echo "Estimating L via MELODIC (K = 25)..."
Rscript simulation/estimate_L_via_MELODIC.R $DESIGN_ID $FSL_PATH --sigma 1.0 --no_migp --nonlinearity pow3 --num_comps 25 > data-analysis/results/$DESIGN_ID/simulation/results/$2/log-melodic-estimate-L-melodic-K25
echo "DONE!"
echo " "

echo "Plotting results (K = 25)..."
Rscript simulation/plot_results_melodic.R $DESIGN_ID ffa --ncomps 25 --archive
Rscript simulation/plot_results_melodic.R $DESIGN_ID ica --ncomps 25 --archive
echo "DONE!"
echo " "


