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
p <- add_argument(p, "--slice", flag = TRUE, help = "Flag to perform ICA on only one slice")
p <- add_argument(p, "--auto", flag = TRUE, help = "Flag to automatically select number of ICs")
args <- parse_args(p)

analysis.id <- args$analysis.id
slice <- args$slice
auto <- args$auto

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{analysis.id}.yml'))
)
z <- analysis$settings$z_
sigma <- analysis$settings$ica$sigma_smoothing

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

if (auto) {
  dir.ica.out <- file.path(dir.ica, 'output-auto')
} else {
  dir.ica.out <- file.path(dir.ica, 'output-manual')
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
if (!auto) {
  flags <- paste0(flags, str_glue('-d {analysis$settings$ica$num_comps}'))
}
print('\n----- START ICA -----')
out <- system2(
  command = file.path(analysis$settings$ica$fsl_path, 'melodic'),
  args = flags, env = 'FSLOUTPUTTYPE=NIFTI_GZ'
)
print('\n----- END ICA -----')


















# library(argparser)
# library(pbmcapply)
# library(RNifti)
# library(stringr)
# library(yaml)
# 
# source(file.path('data-analysis', 'utils', 'utils.R'))
# 
# 
# 
# ## Helpers =====================================================================
# 
# smooth_scan <- function(idx, sub.paths, sub.paths.out, sigma) {
#   out <- system2(
#     command = file.path(analysis$settings$ica$fsl_path, 'fslmaths'),
#     args = str_glue('{sub.paths[[idx]]} -s {sigma} {sub.paths.out[[idx]]}'),
#     env = 'FSLOUTPUTTYPE=NIFTI_GZ'
#   )
# }
# 
# ## Execution ===================================================================
# 
# p <- arg_parser("Script running FSL's MELODIC ICA.")
# p <- add_argument(p, "analysis.id", help = "ID of analysis")
# args <- parse_args(p)
# 
# analysis <- yaml.load_file(
#   file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
# )
# 
# ## Set input/output paths
# path.mask <- file.path('data-analysis', 'data', 'common_mask.nii.gz')
# dir.ica.out <- file.path(analysis$dirs$results, 'ica')
# dir.ica.out.sm <- file.path(
#   analysis$scratch_root, 
#   analysis$dirs$data, 
#   'ica-smoothed'
# )
# dir.create(dir.ica.out)
# dir.create(dir.ica.out.sm)
# 
# ## Generate list of subject paths
# if (analysis$settings$all_subs) {
#   sub.nums <- 1:216
# } else {
#   sub.nums <- analysis$settings$sub_nums
# }
# sub.labs <- str_pad(sub.nums, 4, pad = '0')
# sub.paths <- list()
# sub.paths.out <- list()
# for (sub.lab in sub.labs) {
#   sub.path <- gen_fmriprep_path(analysis$dirs$dataset, sub.lab)
#   if (file.exists(sub.path)) {
#     sub.paths[[length(sub.paths)+1]] <- sub.path
#     sub.paths.out[[length(sub.paths.out)+1]] <- file.path(
#       dir.ica.out.sm, 
#       str_glue('{sub.lab}.nii.gz')
#     )
#   } else {
#     print(str_glue("No resting state scan found for {sub.lab}"))
#   }
# }
# 
# ## Smooth functional images in parallel
# print("----- START SMOOTHING -----")
# num.cores <- detectCores()
# print(str_glue("Found {num.cores} cores!"))
# options(mc.cores = num.cores)
# out <- pbmclapply(
#   1:length(sub.paths), smooth_scan,
#   sub.paths = sub.paths,
#   sub.paths.out = sub.paths.out,
#   sigma = analysis$settings$ica$sigma_smoothing,
#   ignore.interactive = TRUE
# )
# print("----- END SMOOTHING -----")
# 
# ## Run MELODIC ICA
# flags <- paste0(
#   str_glue("-i {paste(sub.paths.out, collapse=',')} -o {dir.ica.out} "), 
#   str_glue('-m {path.mask} --nobet --tr=0.75 ')
# )
# if (!is.null(analysis$settings$ica$num_comps)) {
#   flags <- paste0(flags, str_glue('-d {analysis$settings$ica$num_comps}'))
# }
# print('\n----- START ICA -----')
# out <- system2(
#   command = file.path(analysis$settings$ica$fsl_path, 'melodic'),
#   args = flags, env = 'FSLOUTPUTTYPE=NIFTI_GZ'
# )
# print('\n----- END ICA -----')
# 
# 
# 








################################################################################
################################################################################
################################################################################

# ## Set input/output paths
# dir.create(file.path(analysis$scratch_root, analysis$dirs$data, 'ica'))
# path.func <- file.path(analysis$scratch_root, analysis$dirs$data, 'X.nii.gz')
# path.func.out <- file.path(analysis$scratch_root, analysis$dirs$data, 'ica', 'X_ica.nii.gz')
# path.mask <- file.path(
#   analysis$dirs$dataset, 'derivatives', 'fmriprep', 
#   str_glue('sub-{analysis$settings$sub_label}'), 'func', 
#   paste0(str_glue('sub-{analysis$settings$sub_label}_task-restingstate_'), 
#          'acq-mb3_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz'))
# dir.melodic.out <- file.path(analysis$dirs$results, 'ica')
# 
# 
# ## Smooth functional image
# out <- system2(
#   command = file.path(analysis$settings$ica$fsl_path, 'fslmaths'),
#   args = str_glue('{path.func} -s {analysis$settings$ica$sigma_smoothing} {path.func.out}'),
#   env = 'FSLOUTPUTTYPE=NIFTI_GZ'
# )
# 
# 
# ## Run MELODIC ICA
# flags <- paste0(str_glue('-i {path.func.out} -o {dir.melodic.out} '), 
#                 str_glue('-m {path.mask} --nobet --tr=0.75 '))
# if (analysis$settings$ica$num_comps != 'auto') {
#   flags <- paste0(flags, str_glue('-d {analysis$settings$ica$num_comps}'))
# }
# out <- system2(
#   command = file.path(analysis$settings$ica$fsl_path, 'melodic'),
#   args = flags, env = 'FSLOUTPUTTYPE=NIFTI_GZ'
# )





