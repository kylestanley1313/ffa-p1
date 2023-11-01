#SBATCH --account=<ACCOUNT>
#SBATCH --job-name=analysis-main
#SBATCH --mail-type=END,FAIL                      
#SBATCH --mail-user=<EMAIL>            
#SBATCH -N 1                                      
#SBATCH -n 1                                  
#SBATCH --mem-per-cpu=5gb                         
#SBATCH --time=36:00:00                           
#SBATCH --output=analysis-main_%j.log

# Set variables
ACCOUNT='<ACCOUNT>'
EMAIL='<EMAIL>'
WORK_ROOT='<WORK_ROOT>'
SCRATCH_ROOT='<SCRATCH_ROOT>'
ANALYSIS_ID='aomic'

cd $WORK_DIR/ffa-p1

JOB_ID=$(sbatch --parsable analysis-1-preprocessing.sh $ACCOUNT $EMAIL $WORK_ROOT $SCRATCH_ROOT $ANALYSIS_ID)
JOB_ID=$(sbatch --parsable --dependency=afterok:$JOB_ID analysis-2-splitting.sh $ACCOUNT $EMAIL $WORK_ROOT $ANALYSIS_ID)
JOB_ID=$(sbatch --parsable --dependency=afterok:$JOB_ID analysis-collab-3-alpha-testing.sh $ACCOUNT $EMAIL $WORK_ROOT $ANALYSIS_ID)
JOB_ID=$(sbatch --parsable --dependency=afterok:$JOB_ID analysis-collab-4-scree-plot.sh $ACCOUNT $EMAIL $WORK_ROOT $ANALYSIS_ID)
JOB_ID=$(sbatch --parsable --dependency=afterok:$JOB_ID analysis-collab-5-estimation.sh $ACCOUNT $EMAIL $WORK_ROOT $ANALYSIS_ID)
JOB_ID=$(sbatch --parsable --dependency=afterok:$JOB_ID analysis-collab-6-postprocessing.sh $ACCOUNT $EMAIL $WORK_ROOT $ANALYSIS_ID)
JOB_ID=$(sbatch --parsable --dependency=afterok:$JOB_ID analysis-collab-7-ica.sh $ACCOUNT $EMAIL $WORK_ROOT $ANALYSIS_ID)
sbatch --dependency=afterok:$JOB_ID analysis-collab-7-ica.sh $ACCOUNT $EMAIL $WORK_ROOT $ANALYSIS_ID

