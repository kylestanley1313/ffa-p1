library(argparser)
library(pbmcapply)
library(RNifti)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))


## Helpers =====================================================================

run_melodic <- function(
    split.num,
    splits, 
    dir.ica.in, 
    dir.ica,
    dir.ica.scratch, 
    fsl.path,
    path.mask, 
    nl, 
    no.migp, 
    no.varnorm, 
    num.comps
) {
  
  ## Generate subject paths
  split <- splits[split.num,]
  sub.labs <- str_pad(split, 4, pad = '0')
  sub.paths <- file.path(dir.ica.in, str_glue("{sub.labs}.nii.gz"))
  
  ## Create output directory
  dir.ica.out <- file.path(dir.ica.scratch, str_glue('out_split-{split.num}'))
  dir.create(dir.ica.out, recursive = TRUE)
  
  ## Run MELODIC
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
  command <- file.path(fsl.path, 'melodic')
  out <- system2(
    command = command, args = flags,
    env = 'FSLOUTPUTTYPE=NIFTI_GZ'
  )
  
  ## Convert ICs to CSV
  path <- file.path(dir.ica.out, 'melodic_oIC.nii.gz')
  comps <- readNifti(path)
  new_dim <- c(
    analysis$settings$M1*analysis$settings$M2,
    dim(comps)[length(dim(comps))]
  )
  comps <- array_reshape(comps, dim = new_dim)
  path <- file.path(dir.ica, str_glue('IC_split-{split.num}_K-{num.comps}.csv.gz'))
  write.table(
    comps,
    gzfile(path),
    sep = ',',
    row.names = FALSE,
    col.names = FALSE,
    append = FALSE
  )
  
  ## Cleanup
  unlink(dir.ica.out, recursive = TRUE)
}


## Execution ===================================================================

p <- arg_parser("Script for running ICA via Iraji method.")
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
dir.ica <- file.path(analysis$dirs$data, 'iraji')
dir.ica.scratch <- file.path(analysis$scratch_root, analysis$dirs$data, 'iraji')
dir.create(dir.ica.scratch, recursive = TRUE)
dir.pp <- file.path(analysis$scratch_root, analysis$dirs$data, 'preprocessed')
if (!is.na(sigma) | sigma > 0 ) {
  dir.ica.in <- file.path(dir.pp, str_glue('temp_z-{z}_sigma-{sigma}'))
} else {
  dir.ica.in <- file.path(dir.pp, str_glue('temp_z-{z}'))
}
path.mask <- file.path(
  'data-analysis', 'data', str_glue('common_mask_z-{z}.nii.gz')
)

## Get list of splits
path <- file.path(dir.ica, 'splits.csv')
splits <- csv_to_matrix(path)

## Run MELODIC in parallel
print("----- START MELODIC -----")
num.cores <- detectCores()
print(str_glue("Found {num.cores} cores!"))
options(mc.cores = num.cores)
out <- pbmclapply(
  1:nrow(splits), run_melodic,
  splits = splits,
  dir.ica.in = dir.ica.in, 
  dir.ica = dir.ica,
  dir.ica.scratch = dir.ica.scratch,
  fsl.path = analysis$fsl_path,
  path.mask = path.mask, 
  nl = args$nonlinearity, 
  no.migp = args$no_migp, 
  no.varnorm = args$no_varnorm, 
  num.comps = args$num_comps,
  ignore.interactive = TRUE
)
print("----- END MELODIC -----")



