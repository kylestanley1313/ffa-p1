library(argparser)
library(forecast)
library(pbmcapply)
library(RNifti)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))


gen_fmriprep_path <- function(dir.dataset, sub) {
  fname <- paste0(
    str_glue('sub-{sub}_task-restingstate_acq-mb3_'),
    'space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz'
  )
  path <- file.path(
    dir.dataset, 'derivatives', 'fmriprep', 
    str_glue('sub-{sub}'), 'func', fname
  )
  return(path)
}


process_chunk <- function(chunk) {
  for (v in 1:nrow(chunk)) {
    if (any(chunk[v,] != 0)) {  ## Skip time courses of all zeros
      
      ## Whiten
      chunk[v,] <- auto.arima(
        chunk[v,],
        seasonal = FALSE,
        stationary = FALSE,
        max.d = 2,
        max.p = 20,
        max.q = 20,
        ic = 'aic',
        nmodels = 500
      )$residuals
      
      ## Scale to unit variance
      chunk[v,] <- chunk[v,] / sd(chunk[v,])
      
    }
  }
  return(chunk)
}


## Execution ===================================================================

p <- arg_parser("Script for preprocessing AOMIC resting state functional scans.")
p <- add_argument(p, "analysis.id", help = "ID of analysis.")
args <- parse_args(p)

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
M1 <- analysis$settings$M1
M2 <- analysis$settings$M2
T_ <- analysis$settings$T_
z <- analysis$settings$z_

## Generate subject labels
if (analysis$settings$all_subs) {
  sub_labels <- str_pad(1:216, 4, pad = '0')
} else {
  sub_labels <- str_pad(analysis$settings$sub_nums, 4, pad = '0')
}
num_subs <- length(sub_labels)

## Read in each subject's scan
scans <- vector('list', num_subs)
for (i in 1:num_subs) {
  path.func <- gen_fmriprep_path(analysis$dirs$dataset, sub_labels[i])
  sub_scan <- readNifti(path.func)
  sub_scan <- sub_scan[,,z,]
  dim(sub_scan) <- c(M1*M2, T_)
  scans[[i]] <- sub_scan
}

## Preprocess in parallel
print("----- START PREPROCESSING -----")
num.cores <- detectCores()
print(str_glue("Found {num.cores} cores!"))
options(mc.cores = num.cores)
out <- pbmclapply(
  scans, process_chunk,
  ignore.interactive = TRUE
)
print("----- END PREPROCESSING -----")

## Stitch together processed functional image and write to CSV
X <- array(dim = c(M1*M2, T_*num_subs))
for (i in 1:length(out)) {
  X[,(T_*(i-1)+1):(T_*i)] <- out[[i]]
}
write_matrix(X, file.path(analysis$scratch_root, analysis$dirs$data), 'X')

## Update analysis YAML
analysis$settings$N_ <- N
write_yaml(analysis, file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml')))


