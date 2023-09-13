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


process_scan <- function(scan, temp.dir) {
  
  sub_label <- scan$sub_label
  scan <- scan$scan
  
  for (v in 1:nrow(scan)) {
    if (any(scan[v,] != 0)) {  ## Skip time courses of all zeros

      ## Whiten
      scan[v,] <- auto.arima(
        scan[v,],
        seasonal = FALSE,
        stationary = FALSE,
        max.d = 2,
        max.p = 20,
        max.q = 20,
        ic = 'aic',
        nmodels = 500
      )$residuals

      ## Scale to unit variance
      scan[v,] <- scan[v,] / sd(scan[v,])

    }
  }
  
  write_matrix(scan, temp.dir, str_glue('X{sub_label}'))
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
scans <- list()
for (i in 1:num_subs) {
  path.func <- gen_fmriprep_path(analysis$dirs$dataset, sub_labels[i])
  if (file.exists(path.func)) {
    sub_scan <- readNifti(path.func)
    sub_scan <- sub_scan[,,z,]
    dim(sub_scan) <- c(M1*M2, T_)
    scans[[length(scans)+1]] <- list(sub_label=sub_labels[i], scan=sub_scan) 
  } else {
    print(str_glue("No resting state scan found for {sub_labels[i]}"))
  }
}
num_subs <- length(scans)

## Create folder for intermediate preprocessed scans
temp.dir <- file.path(analysis$scratch_root, analysis$dirs$data, 'preprocessed-scans')
dir.create(temp.dir)

## Preprocess in parallel
print("----- START PREPROCESSING -----")
num.cores <- detectCores()
print(str_glue("Found {num.cores} cores!"))
options(mc.cores = num.cores)
out <- pbmclapply(
  scans, process_scan,
  temp.dir = temp.dir,
  ignore.interactive = TRUE
)
print("----- END PREPROCESSING -----")

## Stitch together processed functional image and write to CSV
## NOTE: Read directly from temp directory instead of re-generating file names
## in case this script needs to be run in batches. 
temp.files <- list.files(temp.dir)
num.temp.files <- length(temp.files)
X <- array(dim = c(M1*M2, T_*num.temp.files))
for (i in 1:num.temp.files) {
  path <- file.path(temp.dir, temp.files[i])
  X[,(T_*(i-1)+1):(T_*i)] <- csv_to_matrix(path)
}
write_matrix(X, file.path(analysis$scratch_root, analysis$dirs$data), 'X')

## Update analysis YAML
analysis$settings$N_ <- T_ * num_subs
write_yaml(analysis, file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml')))


