#!/bin/bash
#SBATCH --job-name=simulation-plotting
#SBATCH --mail-type=END,FAIL
#SBATCH -N 1
#SBATCH -n 11
#SBATCH --mem-per-cpu=5gb
#SBATCH --time=00:40:00
#SBATCH --output=simulation-plotting_%j.log

# Get started
echo " "
echo "Job started on $(hostname) at $(date)"
echo " "

# Load modules
module purge
module load anaconda3/2021.05

# Parse positional arguments
ROOT=$1
DESIGN=$2
shift 2

# Parse flags
RANK=false
ACC_COMP=false
INT_COMP=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --rank)
      RANK=true
      shift
      ;;
    --acc_comp)
      ACC_COMP=true
      shift
      ;;
    --int_comp)
      INT_COMP=true
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      ;;
  esac
done


# cd into project root
cd $ROOT

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

if [ "$RANK" == "true" ]; then
  echo "Plotting results (rank)..."
  Rscript simulation/plot_results.R $DESIGN --rank > simulation/results/$DESIGN/log-plot-results-rank
  echo "DONE!"
  echo " "
fi
if [ "$ACC_COMP" == "true" ]; then
  echo "Plotting results (accuracy comparison)..."
  Rscript simulation/plot_results.R $DESIGN --acc_comp > simulation/results/$DESIGN/log-plot-results-acc_comp
  echo "DONE!"
  echo " "
fi
if [ "$INT_COMP" == "true" ]; then
  echo "Plotting results (interpretability comparison)..."
  Rscript simulation/plot_results.R $DESIGN --int_comp > simulation/results/$DESIGN/log-plot-results-int_comp
  echo "DONE!"
  echo " "
fi

echo " "