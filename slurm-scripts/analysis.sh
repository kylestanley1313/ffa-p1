#!/bin/bash
#SBATCH --account=<ACCOUNT>
#SBATCH --job-name=analysis-main
#SBATCH --mail-type=END,FAIL                      
#SBATCH --mail-user=<EMAIL>            
#SBATCH -N 1                                      
#SBATCH -n 1                                  
#SBATCH --mem-per-cpu=5gb                         
#SBATCH --time=00:10:00                           
#SBATCH --output=analysis-main_%j.log

# Set variables
ACCOUNT='<ACCOUNT>'
EMAIL='<EMAIL>'
WORK_ROOT='<WORK_ROOT>'
SCRATCH_ROOT='<SCRATCH_ROOT>'
ANALYSIS_ID='aomic'

cd $WORK_ROOT/slurm-scripts

JOB_ID=$(sbatch --parsable --account=$ACCOUNT --mail-user=$EMAIL analysis-1-preprocessing.sh $WORK_ROOT $ANALYSIS_ID $SCRATCH_ROOT)
JOB_ID=$(sbatch --parsable --account=$ACCOUNT --mail-user=$EMAIL --dependency=afterok:$JOB_ID analysis-2-splitting.sh $WORK_ROOT $ANALYSIS_ID)
JOB_ID=$(sbatch --parsable --account=$ACCOUNT --mail-user=$EMAIL --dependency=afterok:$JOB_ID analysis-3-alpha-testing.sh $WORK_ROOT $ANALYSIS_ID)
JOB_ID=$(sbatch --parsable --account=$ACCOUNT --mail-user=$EMAIL --dependency=afterok:$JOB_ID analysis-4-scree-plot.sh $WORK_ROOT $ANALYSIS_ID)
JOB_ID=$(sbatch --parsable --account=$ACCOUNT --mail-user=$EMAIL --dependency=afterok:$JOB_ID analysis-5-estimation.sh $WORK_ROOT $ANALYSIS_ID)
JOB_ID=$(sbatch --parsable --account=$ACCOUNT --mail-user=$EMAIL --dependency=afterok:$JOB_ID analysis-6-postprocessing.sh $WORK_ROOT $ANALYSIS_ID)
JOB_ID=$(sbatch --parsable --account=$ACCOUNT --mail-user=$EMAIL --dependency=afterok:$JOB_ID analysis-7-ica.sh $WORK_ROOT $ANALYSIS_ID)
sbatch --account=$ACCOUNT --mail-user=$EMAIL --dependency=afterok:$JOB_ID analysis-8-plot.sh $WORK_ROOT $ANALYSIS_ID

