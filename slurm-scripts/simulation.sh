#!/bin/bash
#SBATCH --account=<ACCOUNT>
#SBATCH --job-name=simulation-main
#SBATCH --mail-type=END,FAIL                      
#SBATCH --mail-user=<EMAIL>            
#SBATCH -N 1                                      
#SBATCH -n 1                                  
#SBATCH --mem-per-cpu=5gb                         
#SBATCH --time=00:10:00                           
#SBATCH --output=simulation-main_%j.log

# Set variables
ACCOUNT='<ACCOUNT>'
EMAIL='<EMAIL>'
WORK_ROOT='<WORK_ROOT>'
SCRATCH_ROOT='<SCRATCH_ROOT>'
DESIGN_ID='<DESIGN_ID>'

cd $WORK_ROOT/slurm-scripts

JOB_ID=$(sbatch --parsable --account=$ACCOUNT --mail-user=$EMAIL simulation-1-data.sh $WORK_ROOT $DESIGN_ID $SCRATCH_ROOT)
JOB_ID=$(sbatch --parsable --account=$ACCOUNT --mail-user=$EMAIL --dependency=afterok:$JOB_ID simulation-2-rank.sh $WORK_ROOT $DESIGN_ID)
JOB_ID=$(sbatch --parsable --account=$ACCOUNT --mail-user=$EMAIL --dependency=afterok:$JOB_ID simulation-3-comparison.sh $WORK_ROOT $DESIGN_ID --rank --acc_comp)
sbatch --account=$ACCOUNT --mail-user=$EMAIL --dependency=afterok:$JOB_ID simulation-4-plotting.sh $WORK_ROOT $DESIGN_ID