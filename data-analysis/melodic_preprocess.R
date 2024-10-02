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

smooth_scan <- function(idx, sub.paths.in, sub.paths.out, sigma, fsl_path) {
  out <- system2(
    command = file.path(fsl_path, 'fslmaths'),
    args = str_glue('{sub.paths.in[[idx]]} -s {sigma} {sub.paths.out[[idx]]}'),
    env = 'FSLOUTPUTTYPE=NIFTI_GZ'
  )
}


## Execution ===================================================================

p <- arg_parser("Script that prepares AOMIC data for MELODIC.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
p <- add_argument(p, "--sigma", help = "Sigma to use for smoothing.")
args <- parse_args(p)

analysis.id <- args$analysis.id
sigma <- args$sigma

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{analysis.id}.yml'))
)
z <- analysis$settings$z_

## Set paths and directories
dir.pp <- file.path(analysis$scratch_root, analysis$dirs$data, 'preprocessed')
dir.pp.sl <- file.path(
  dir.pp,
  str_glue('temp_z-{z}')
)
dir.pp.sm <- file.path(
  dir.pp,
  str_glue('temp_z-{z}_sigma-{sigma}')
)
dir.create(dir.pp.sl, recursive = TRUE)
dir.create(dir.pp.sm, recursive = TRUE)

## Generate list of subject paths
if (analysis$settings$all_subs) {
  sub.nums <- 1:216
} else {
  sub.nums <- analysis$settings$sub_nums
}
sub.labs <- str_pad(sub.nums, 4, pad = '0')
sub.paths <- list()
sub.paths.sl <- list()
sub.paths.sm <- list()
for (sub.lab in sub.labs) {
  sub.path <- gen_fmriprep_path(analysis$dirs$dataset, sub.lab)
  if (file.exists(sub.path)) {
    sub.paths[[length(sub.paths)+1]] <- sub.path
    sub.paths.sl[[length(sub.paths.sl)+1]] <- file.path(
      dir.pp.sl,
      str_glue('{sub.lab}.nii.gz')
    )
    sub.paths.sm[[length(sub.paths.sm)+1]] <- file.path(
      dir.pp.sm,
      str_glue('{sub.lab}.nii.gz')
    )
  } else {
    print(str_glue("No resting state scan found for {sub.lab}"))
  }
}

## Slice functional images in parallel
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

## Smooth functional images in parallel
if (!is.na(sigma) | sigma > 0 ) {
  print("----- START SMOOTHING -----")
  num.cores <- detectCores()
  print(str_glue("Found {num.cores} cores!"))
  options(mc.cores = num.cores)
  out <- pbmclapply(
    1:length(sub.paths), smooth_scan,
    sub.paths.in = sub.paths.sl,
    sub.paths.out = sub.paths.sm,
    sigma = sigma,
    fsl_path = analysis$fsl_path,
    ignore.interactive = TRUE
  )
  print("----- END SMOOTHING -----")
}
