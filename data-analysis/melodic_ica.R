library(argparser)
library(pbmcapply)
library(RNifti)
library(stringr)
library(yaml)

source(file.path('data-analysis', 'utils', 'utils.R'))



## Helpers =====================================================================


slice_scan <- function(idx, sub.paths.in, sub.paths.out, z) {
  img <- readNifti(sub.paths.in[[idx]])
  slice <- img[,,z,,drop=F]
  writeNifti(slice, sub.paths.out[[idx]])
}

smooth_scan <- function(idx, sub.paths.in, sub.paths.out, sigma) {
  out <- system2(
    command = file.path(analysis$settings$ica$fsl_path, 'fslmaths'),
    args = str_glue('{sub.paths.in[[idx]]} -s {sigma} {sub.paths.out[[idx]]}'),
    env = 'FSLOUTPUTTYPE=NIFTI_GZ'
  )
}


## Execution ===================================================================

p <- arg_parser("Script for running FSL's MELODIC ICA.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
p <- add_argument(p, "--sigma", help = "Sigma to use for smoothing.")
p <- add_argument(p, "--num_comps", help = "Flag to manually set number of ICs. If not passed, used automatic selection.")
p <- add_argument(p, "--slice", flag = TRUE, help = "Flag to perform ICA on only one slice.")
p <- add_argument(p, "--no_migp", flag = TRUE, help = "Flag to diable dimension reduction before ICA.")
p <- add_argument(p, "--no_varnorm", flag = TRUE, help = "Flag to disable variance normalization before ICA.")
p <- add_argument(p, "--nonlinearity", default = 'pow3', help = "Nonlinearity used during ICA unmixing.")
args <- parse_args(p)

analysis.id <- args$analysis.id
slice <- args$slice
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
dir.ica <- file.path(analysis$dirs$data, 'ica')
dir.ica.scratch <- file.path(analysis$scratch_root, dir.ica)
dir.ica.sl <- file.path(
  dir.ica.scratch,
  str_glue('sliced-z-{z}')
)
dir.ica.sm <- file.path(
  dir.ica.scratch,
  str_glue('smoothed-sigma-{sigma}')
)
dir.ica.out <- file.path(
  dir.ica, 
  paste0(
    str_glue("{ifelse(slice, 'slice', 'volume')}_"),
    str_glue("sigma-{ifelse(is.na(sigma), 0, sigma)}_"),
    str_glue("migp-{ifelse(no.migp, 'no', 'yes')}_"),
    str_glue("varnorm-{ifelse(no.varnorm, 'no', 'yes')}_"),
    str_glue("nl-{nl}_"),
    str_glue('ncomps-{num.comps}')
  )
)
if (slice) {
  dir.create(dir.ica.sl, recursive = TRUE)
}
if (!is.na(sigma)) {
  dir.create(dir.ica.sm, recursive = TRUE)
}
dir.create(dir.ica.out, recursive = TRUE)
path.mask <- file.path(
  'data-analysis', 'data',
  ifelse(
    slice,
    str_glue('common_mask_z-{z}.nii.gz'),
    'common_mask.nii.gz'
  )
)

## Generate list of subject paths
if (analysis$settings$all_subs) {
  sub.nums <- 1:216
} else {
  sub.nums <- analysis$settings$sub_nums
}
sub.labs <- str_pad(sub.nums, 4, pad = '0')
sub.paths <- list()
if (slice) {
  sub.paths.sl <- list()
}
sub.paths.sm <- list()
sub.paths.out <- list()
for (sub.lab in sub.labs) {
  sub.path <- gen_fmriprep_path(analysis$dirs$dataset, sub.lab)
  if (file.exists(sub.path)) {
    sub.paths[[length(sub.paths)+1]] <- sub.path
    if (slice) {
      sub.paths.sl[[length(sub.paths.sl)+1]] <- file.path(
        dir.ica.sl,
        str_glue('{sub.lab}.nii.gz')
      )
    }
    sub.paths.sm[[length(sub.paths.sm)+1]] <- file.path(
      dir.ica.sm,
      str_glue('{sub.lab}.nii.gz')
    )
    sub.paths.out[[length(sub.paths.out)+1]] <- file.path(
      dir.ica.out,
      str_glue('{sub.lab}.nii.gz')
    )
  } else {
    print(str_glue("No resting state scan found for {sub.lab}"))
  }
}

## Slice functional images in parallel
if (slice) {
  print("----- START SLICING -----")
  num.cores <- detectCores()
  print(str_glue("Found {num.cores} cores!"))
  options(mc.cores = num.cores)
  out <- pbmclapply(
    1:length(sub.paths), slice_scan,
    sub.paths.in = sub.paths,
    sub.paths.out = sub.paths.sl,
    z = z,
    ignore.interactive = TRUE
  )
  print("----- END SLICING -----")
}

## Smooth functional images in parallel
if (slice) {
  sub.paths.in = sub.paths.sl
} else {
  sub.paths.in = sub.paths
}
if (is.na(sigma) | sigma <= 0 ) {
  sub.paths.sm <- sub.paths.in
} else {
  print("----- START SMOOTHING -----")
  num.cores <- detectCores()
  print(str_glue("Found {num.cores} cores!"))
  options(mc.cores = num.cores)
  out <- pbmclapply(
    1:length(sub.paths), smooth_scan,
    sub.paths.in = sub.paths.in,
    sub.paths.out = sub.paths.sm,
    sigma = sigma,
    ignore.interactive = TRUE
  )
  print("----- END SMOOTHING -----")
}


## Run MELODIC ICA
flags <- paste(
  str_glue("-i {paste(sub.paths.sm, collapse=',')} -o {dir.ica.out}"),
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
command <- file.path(analysis$settings$ica$fsl_path, 'melodic')
print(str_glue("Command: {command}"))
print(str_glue("Flags: {flags}"))
out <- system2(
  command = command, args = flags,
  env = 'FSLOUTPUTTYPE=NIFTI_GZ'
)
print('\n----- END ICA -----')

