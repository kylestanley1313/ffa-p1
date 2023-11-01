#!/bin/bash
sbatch <<EOT
#!/bin/bash
#SBATCH --account=$1
#SBATCH --job-name=analysis-preprocessing
#SBATCH --mail-type=END,FAIL                      
#SBATCH --mail-user=$2               
#SBATCH -N 1                                      
#SBATCH -n 20                                      
#SBATCH --mem-per-cpu=5gb                         
#SBATCH --time=16:00:00                           
#SBATCH --output=analysis-preprocessing_%j.log

# Load modules
module purge
module load python/3.6.8
module load anaconda3/2021.05

# cd into project root
cd $3

# Activate conda environment
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate ffa-p1

# Create directories
mkdir -p data-analysis/data/$5
mkdir -p data-analysis/results/$5
mkdir -p $4/data-analysis/data/$5

echo "Preprocessing..."
Rscript data-analysis/preprocess.R $5 > data-analysis/results/$5/log-preprocessing
echo "DONE!"
echo " "
EOT

