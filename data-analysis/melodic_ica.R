library(argparser)
library(RNifti)
library(stringr)
library(yaml)


p <- arg_parser("Script running FSL's MELODIC ICA.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
args <- parse_args(p)

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)


## Set input/output paths
dir.create(file.path(analysis$scratch_root, analysis$dirs$data, 'ica'))
path.func <- file.path(analysis$scratch_root, analysis$dirs$data, 'X.nii.gz')
path.func.out <- file.path(analysis$scratch_root, analysis$dirs$data, 'ica', 'X_ica.nii.gz')
path.mask <- file.path(
  analysis$dirs$dataset, 'derivatives', 'fmriprep', 
  str_glue('sub-{analysis$settings$sub_label}'), 'func', 
  paste0(str_glue('sub-{analysis$settings$sub_label}_task-restingstate_'), 
         'acq-mb3_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz'))
dir.melodic.out <- file.path(analysis$dirs$results, 'ica')


## Smooth functional image
out <- system2(
  command = file.path(analysis$settings$ica$fsl_path, 'fslmaths'),
  args = str_glue('{path.func} -s {analysis$settings$ica$sigma_smoothing} {path.func.out}'),
  env = 'FSLOUTPUTTYPE=NIFTI_GZ'
)


## Run MELODIC ICA
out <- system2(
  command = file.path(analysis$settings$ica$fsl_path, 'melodic'),
  args = paste0(str_glue('-i {path.func.out} -o {dir.melodic.out} '), 
                str_glue('-m {path.mask} --nobet --tr=0.75 '), 
                str_glue('-d {analysis$settings$ica$num_comps}')),
  env = 'FSLOUTPUTTYPE=NIFTI_GZ'
)





