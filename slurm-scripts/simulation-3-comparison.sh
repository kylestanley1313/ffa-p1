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

# Parse positional arguments
ROOT=$1
DESIGN=$2
shift 2

# Parse optional arguments
DIFF_KAPPAS=false
K_OVERRIDE=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --diff_kappas)
      DIFF_KAPPAS=true
      shift
      ;;
    --k_override=*)
      K_OVERRIDE="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      ;;
  esac
done

# cd into project root
cd $ROOT

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

if [ -n "$K_OVERRIDE" ]; then
  Rscript simulation/edit_configs.R $DESIGN --num_facs $K_OVERRIDE --archive
fi

echo "Estimating L via KL..."
Rscript simulation/estimate_L_via_KL.R $DESIGN > simulation/results/$DESIGN/log-estimate-L-kl
echo "DONE!"
echo " "

echo "Estimating L via MELODIC..."
Rscript simulation/tune_sigma.R $DESIGN > simulation/results/$DESIGN/log-tune-sigma
echo "DONE!"
echo " "

echo "Estimating L via MELODIC..."
Rscript simulation/estimate_L_via_MELODIC.R $DESIGN > simulation/results/$DESIGN/log-estimate-L-melodic
echo "DONE!"
echo " "

echo "Estimating L via DP..."
matlab -nodisplay -nosplash -r "add_paths; estimate_L('$DESIGN', true, false, NaN); exit" > simulation/results/$DESIGN/log-estimate-L-dp
echo "DONE!"
echo " "

echo "Tuning alpha..."
matlab -nodisplay -nosplash -r "add_paths; tune_alpha('$DESIGN', false); exit" > simulation/results/$DESIGN/log-tune-alpha-comparison
echo "DONE!"
echo " "

echo "Estimating L via DPS..."
matlab -nodisplay -nosplash -r "add_paths; estimate_L('$DESIGN', true, true, NaN); exit" > simulation/results/$DESIGN/log-estimate-L-dps
echo "DONE!"
echo " "

echo "Tuning kappa..."
if [ "$DIFF_KAPPAS" == "true" ]; then
  Rscript simulation/tune_kappa.R $DESIGN --diff_kappas > simulation/results/$DESIGN/log-tune-kappa
else
  Rscript simulation/tune_kappa.R $DESIGN > simulation/results/$DESIGN/log-tune-kappa
fi
echo "DONE!"
echo " "

echo "Postprocess L..."
Rscript simulation/postprocess_L.R $DESIGN > simulation/results/$DESIGN/log-postprocess-L
echo "DONE!"
echo " "