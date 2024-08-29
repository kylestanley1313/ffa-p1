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

# Parse arguments
RANK=false
ACC_COMP=false
ACC_COMP_OLD_DATA=false
ACC_COMP_NREPS=""
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
    --acc_comp_old_data)
      ACC_COMP_OLD_DATA=true
      shift
      ;;
    --acc_comp_nreps=*)
      ACC_COMP_NREPS="${1#*=}"
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

echo "Plotting results..."
if [ "$ACC_COMP" == "true" ]; then
  if [ "$ACC_COMP_OLD_DATA" == "true" ]; then
    if [ -n "$ACC_COMP_NREPS" ]; then
      Rscript simulation/plot_results.R $DESIGN --acc_comp --acc_comp_old_data --acc_comp_nreps $ACC_COMP_NREPS > simulation/results/$DESIGN/log-plot-results-acc_comp
    echo "DONE!"
    else
      Rscript simulation/plot_results.R $DESIGN --acc_comp --acc_comp_old_data > simulation/results/$DESIGN/log-plot-results-acc_comp
    fi
  else
    if [ -n "$ACC_COMP_NREPS" ]; then
      Rscript simulation/plot_results.R $DESIGN --acc_comp --acc_comp_nreps $ACC_COMP_NREPS > simulation/results/$DESIGN/log-plot-results-acc_comp
    echo "DONE!"
    else
      Rscript simulation/plot_results.R $DESIGN --acc_comp > simulation/results/$DESIGN/log-plot-results-acc_comp
    fi
  fi
fi
echo "DONE!"
echo " "

if [ "$INT_COMP" == "true" ]; then
  echo "Plotting results (interpretability comparison)..."
  Rscript simulation/plot_results.R $DESIGN --int_comp > simulation/results/$DESIGN/log-plot-results-int_comp
  echo "DONE!"
  echo " "
fi

echo " "