#!/bin/bash
sbatch <<EOT
#!/bin/bash
#SBATCH --account=$1
#SBATCH --job-name=analysis-ica
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=$2
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
cd $3/ffa-p1

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

echo "Running MELODIC..."
Rscript data-analysis/melodic_ica.R $4 --slice --sigma 0 --no_migp --nonlinearity pow3 --num_comps 12 > data-analysis/results/$4/log-melodic-K12
Rscript data-analysis/melodic_ica.R $4 --slice --sigma 0 --no_migp --nonlinearity pow3 --num_comps 25 > data-analysis/results/$4/log-melodic-K25
Rscript data-analysis/melodic_ica.R $4 --slice --sigma 0 --no_migp --nonlinearity pow3 --num_comps 50 > data-analysis/results/$4/log-melodic-K50
echo "DONE!"
EOT

