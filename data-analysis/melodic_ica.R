library(argparser)
library(pbmcapply)
library(RNifti)
library(stringr)
library(yaml)

source(file.path('data-analysis', 'utils', 'utils.R'))



## Execution ===================================================================

p <- arg_parser("Script for running FSL's MELODIC ICA.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
p <- add_argument(p, "--sigma", help = "Sigma that was used to smooth data.")
p <- add_argument(p, "--num_comps", help = "Flag to manually set number of ICs. If not passed, used automatic selection.")
p <- add_argument(p, "--no_migp", flag = TRUE, help = "Flag to diable dimension reduction before ICA.")
p <- add_argument(p, "--no_varnorm", flag = TRUE, help = "Flag to disable variance normalization before ICA.")
p <- add_argument(p, "--nonlinearity", default = 'pow3', help = "Nonlinearity used during ICA unmixing.")
args <- parse_args(p)

analysis.id <- args$analysis.id
num.comps <- args$num_comps
sigma <- args$sigma
no.migp <- args$no_migp
no.varnorm <- args$no_varnorm
nl <- args$nonlinearity

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{analysis.id}.yml'))
)
z <- analysis$settings$z_


## Set paths and directories
dir.ica.out <- file.path(analysis$dirs$data, 'ica', str_glue('out-K{num.comps}'))
dir.pp <- file.path(analysis$scratch_root, analysis$dirs$data, 'preprocessed')
if (!is.na(sigma) & sigma > 0 ) {
  dir.ica.in <- file.path(dir.pp, str_glue('temp_z-{z}_sigma-{sigma}'))
} else {
  dir.ica.in <- file.path(dir.pp, str_glue('temp_z-{z}'))
}
path.mask <- file.path(
  'data-analysis', 'data', str_glue('common_mask_z-{z}.nii.gz')
)
dir.create(dir.ica.out, recursive = TRUE)


## Run MELODIC ICA
sub.paths <- list.files(dir.ica.in, full.names = TRUE)
flags <- paste(
  str_glue("-i {paste(sub.paths, collapse=',')} -o {dir.ica.out}"),
  str_glue('-m {path.mask} --nl={nl}'),
  str_glue('--nobet --tr=0.75 --Oorig'),
  sep = ' '
)
if (no.migp) {
  flags <- paste(flags, '--disableMigp', sep = ' ')
}
if (no.varnorm) {
  flags <- paste(flags, '--varnorm', sep = ' ')
}
if (!is.na(num.comps)) {
  flags <- paste(flags, str_glue('-d {num.comps}'), sep = ' ')
}
print('\n----- START ICA -----')
command <- file.path(analysis$fsl_path, 'melodic')
out <- system2(
  command = command, args = flags,
  env = 'FSLOUTPUTTYPE=NIFTI_GZ'
)
print('\n----- END ICA -----')

