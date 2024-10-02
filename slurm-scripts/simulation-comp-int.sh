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
DESIGN_ID_K8='<DESIGN_ID_K8>'
DESIGN_ID_K25='<DESIGN_ID_K25>'

cd $WORK_ROOT/slurm-scripts

## K = 8
JOB_ID=$(sbatch --parsable --account=$ACCOUNT --mail-user=$EMAIL simulation-1-data.sh $WORK_ROOT $DESIGN_ID_K8 $SCRATCH_ROOT)
JOB_ID=$(sbatch --parsable --account=$ACCOUNT --mail-user=$EMAIL --dependency=afterok:$JOB_ID simulation-3-comparison.sh $WORK_ROOT $DESIGN_ID_K8 --diff_kappas)
sbatch --account=$ACCOUNT --mail-user=$EMAIL --dependency=afterok:$JOB_ID simulation-4-plotting.sh $WORK_ROOT $DESIGN_ID_K8 --int_comp

## K = 25
JOB_ID=$(sbatch --parsable --account=$ACCOUNT --mail-user=$EMAIL simulation-1-data.sh $WORK_ROOT $DESIGN_ID_K25 $SCRATCH_ROOT)
JOB_ID=$(sbatch --parsable --account=$ACCOUNT --mail-user=$EMAIL --dependency=afterok:$JOB_ID simulation-3-comparison.sh $WORK_ROOT $DESIGN_ID_K25 --diff_kappas --k_override=25)
sbatch --account=$ACCOUNT --mail-user=$EMAIL --dependency=afterok:$JOB_ID simulation-4-plotting.sh $WORK_ROOT $DESIGN_ID_K25 --int_comp

