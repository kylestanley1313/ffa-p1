#!/bin/bash
#SBATCH --job-name=analysis-ica
#SBATCH --mail-type=END,FAIL
#SBATCH -N 1
#SBATCH -n 10 #21
#SBATCH --mem-per-cpu=20gb #40gb
#SBATCH --time=06:00:00 #24:00:00
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

N_SPLITS='5' #'25'
N_SUBS_PER_SPLIT='4' #'150'
SIGMA='0.5'
N_COMPS=('10' '20') #('10' '20' '30' '40' '50')
MAX_CORR='0.5'

echo "Splitting..."
Rscript data-analysis/iraji_1_half_splits.R $2 --n_splits $N_SPLITS --n_subs_per_split $N_SUBS_PER_SPLIT --sigma $SIGMA > data-analysis/results/$2/log-ica-iraj-splits
echo "DONE!"
echo ""

echo "Running ICA..."
for ncomp in "${N_COMPS[@]}"; do
    Rscript data-analysis/iraji_2_ica.R $2 --sigma $SIGMA --num_comps $ncomp --no_migp --no_varnorm --nonlinearity pow3 > data-analysis/results/$2/log-ica-iraji-ica-$ncomp
done
echo "DONE!"
echo ""

echo "Selecting stable components..."
Rscript data-analysis/iraji_3_select_stable_comps.R $2 --n_splits $N_SPLITS --n_comps_list ${N_COMPS[*]} > data-analysis/results/$2/log-ica-iraji-stable-comps
echo "DONE!"
echo ""

echo "Selecting distinct components..."
Rscript data-analysis/iraji_4_select_distinct_comps.R $2 --n_splits $N_SPLITS --n_comps_list ${N_COMPS[*]} --max_corr $MAX_CORR > data-analysis/results/$2/log-ica-iraji-distinct-comps
echo "DONE!"
echo ""

echo "Plotting results..."
Rscript data-analysis/iraji_5_plot_results.R $2 --n_splits $N_SPLITS --n_comps_list ${N_COMPS[*]} > data-analysis/results/$2/log-ica-iraji-plot-results
echo "DONE!"
echo ""

