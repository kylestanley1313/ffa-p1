library(argparser)
library(RNifti)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('simulation', 'utils', 'utils.R'))



## Helpers =====================================================================

smooth_scan <- function(path.in, path.out, sigma, fsl.path) {
  out <- system2(
    command = file.path(fsl.path, 'fslmaths'),
    args = str_glue('{path.in} -s {sigma} {path.out}'),
    env = 'FSLOUTPUTTYPE=NIFTI_GZ'
  )
}


## Execution ===================================================================

p <- arg_parser("Script to perform ICA on a CSV data file.")
p <- add_argument(p, "design_id", help = "ID of design.")
p <- add_argument(p, "fsl_path", help = "FSL path.")
p <- add_argument(p, "--sigma", help = "Sigma to use for smoothing.")
p <- add_argument(p, "--num_comps", help = "Flag to manually set number of ICs. If not passed, used automatic selection.")
p <- add_argument(p, "--no_migp", flag = TRUE, help = "Flag to diable dimension reduction before ICA.")
p <- add_argument(p, "--no_varnorm", flag = TRUE, help = "Flag to disable variance normalization before ICA.")
p <- add_argument(p, "--nonlinearity", default = 'pow3', help = "Nonlinearity used during ICA unmixing.")
args <- parse_args(p)

## NOTE: Designs called by this script have only 1 associated config. Moreover, 
## this config has only 1 repetition.
config <- yaml.load_file(
  file.path('simulation', 'data', args$design_id, 'config-1', 'config.yml')
)

## Set globals
path.data <- file.path(config$dirs$data, 'mat-X_r-1_.csv.gz')
fname.data <- str_replace(tail(str_split(path.data, '/')[[1]], n = 1), '.csv.gz', '')
dir.ica <- file.path(config$dirs$data, 'ica')
fsl.path <- args$fsl_path
sigma <- args$sigma
num.comps <- args$num_comps
no.migp <- args$no_migp
no.varnorm <- args$no_varnorm
nl <- args$nonlinearity
# path.data <- '/Users/kylestanley/repos/ffa-p1/simulation/data/melodic-1/config-1/mat-X_r-1_.csv.gz' # args$path_data
# fname.data <- str_replace(tail(str_split(path.data, '/')[[1]], n = 1), '.csv.gz', '')
# dir.ica <- '/Users/kylestanley/repos/ffa-p1/simulation/data/melodic-1/config-1/ica' #args$dir_ica
# fsl.path <- '/Users/kylestanley/fsl/share/fsl/bin'  # args.fsl_path 
# sigma <- 1.0  # args$sigma
# num.comps <- 2  # args$num_comps
# no.migp <- TRUE  # args$no_migp
# no.varnorm <- FALSE  # args$no_varnorm
# nl <- 'pow3'  # args$nonlinearity

## Path/directory management
if (!dir.exists(dir.ica)) dir.create(dir.ica)

## Create Nifti copy of data
data <- csv_to_matrix(path.data)
data <- array_reshape(data, c(30, 30, 1, 500))
data <- asNifti(data)
path.data.nii <- file.path(dir.ica, str_glue('{fname.data}.nii.gz'))
writeNifti(data, path.data.nii)

## Smooth scan
path.data.sm <- file.path(dir.ica, str_glue('{fname.data}sm.nii.gz'))
smooth_scan(path.data.nii, path.data.sm, sigma, fsl.path)

## Run MELODIC ICA
flags <- paste(
  str_glue("-i {path.data.sm} -o {dir.ica}"),
  str_glue('--nomask --nl={nl}'),
  str_glue('--nobet --tr=1.0 --Oorig'),
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
command <- file.path(fsl.path, 'melodic')
print(str_glue("Command: {command}"))
print(str_glue("Flags: {flags}"))
out <- system2(
  command = command, args = flags,
  env = 'FSLOUTPUTTYPE=NIFTI_GZ'
)
print('\n----- END ICA -----')

