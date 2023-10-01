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
p <- add_argument(p, "--slice", flag = TRUE, help = "Flag to perform ICA on only one slice")
args <- parse_args(p)

analysis.id <- args$analysis.id
slice <- args$slice
num_comps <- args$num_comps
sigma <- args$sigma

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{analysis.id}.yml'))
)
z <- analysis$settings$z_

## Set paths and directories
dir.ica <- file.path(analysis$dirs$data, 'ica')
dir.create(dir.ica)
dir.create(file.path(analysis$scratch_root, dir.ica))
if (slice) {

  path.mask <- file.path('data-analysis', 'data', str_glue('common_mask_z-{z}.nii.gz'))

  dir.ica <- file.path(analysis$dirs$data, 'ica', 'slice')
  dir.ica.scratch <- file.path(analysis$scratch_root, analysis$dirs$data, 'ica', 'slice')
  dir.ica.sl <- file.path(dir.ica.scratch, 'sliced')

  dir.create(dir.ica)
  dir.create(dir.ica.scratch)
  dir.create(dir.ica.sl)

} else {

  path.mask <- file.path('data-analysis', 'data', str_glue('common_mask.nii.gz'))

  dir.ica <- file.path(analysis$dirs$data, 'ica', 'volume')
  dir.ica.scratch <- file.path(analysis$scratch_root, analysis$dirs$data, 'ica', 'volume')

  dir.create(dir.ica)
  dir.create(dir.ica.scratch)

}

if (is.na(num_comps)) {
  dir.ica.out <- file.path(dir.ica, str_glue('output_sigma-{sigma}_numcomps-auto'))
} else {
  dir.ica.out <- file.path(dir.ica, str_glue('output_sigma-{sigma}_numcomps-{num_comps}'))
}
dir.ica.sm <- file.path(dir.ica.scratch, 'smoothed')
dir.create(dir.ica.sm)
dir.create(dir.ica.out)


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


## Run MELODIC ICA
flags <- paste0(
  str_glue("-i {paste(sub.paths.sm, collapse=',')} -o {dir.ica.out} "),
  str_glue('-m {path.mask} --nobet --tr=0.75 ')
)
if (!is.na(num_comps)) {
  flags <- paste0(flags, str_glue('-d {num_comps}'))
}
print('\n----- START ICA -----')
out <- system2(
  command = file.path(analysis$settings$ica$fsl_path, 'melodic'),
  args = flags, env = 'FSLOUTPUTTYPE=NIFTI_GZ'
)
print('\n----- END ICA -----')

