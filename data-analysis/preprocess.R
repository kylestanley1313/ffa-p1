library(argparser)
library(forecast)
library(RNifti)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))  ## TODO: Update utils.R


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

p <- arg_parser("Script for preprocessing a functional scan for FFA and ICA.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
args <- parse_args(p)

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)

## Specify input/output files
path.func <- gen_fmriprep_path(analysis$dirs$dataset, analysis$settings$sub_label)
path.out <- file.path(analysis$scratch_root, analysis$dirs$data, 'X.nii.gz')

## Read in functional image
X <- readNifti(path.func)
M1 <- dim(img)[1]
M2 <- dim(img)[2]
M3 <- dim(img)[3]
N <- dim(img)[4]
dim(X) <- c(M1*M2*M3, N)

## Chunk the functional image for parallel preprocessing
num.cores <- detectCores()
chunks <- list()
chunk.size <- 1000
row <- 1
while (row <= nrow(X)) {
  last.row <- min(row + chunk.size - 1, nrow(X))
  chunks[[length(chunks)+1]] <- X[row:last.row,]
  row <- last.row + 1
}

## Preprocess in parallel
print("----- START PREPROCESSING -----")
options(mc.cores = num.cores)
out <- pbmclapply(
  chunks, process_chunk, 
  ignore.interactive = TRUE
)
print("----- END PREPROCESSING -----")

## Stitch together processed functional image and write to NIFTI
X.resid <- array(dim = dim(X))
for (i in 1:length(out)) {
  X.resid[(chunk.size*(i-1)+1):min(chunk.size*i, nrow(X)),] <- out[[i]]
}
dim(X.resid) <- c(M1, M2, M3, N)
writeNifti(X.resid, path.out)

## Update analysis YAML
analysis$settings$M1 <- M1
analysis$settings$M2 <- M2
analysis$settings$N_ <- N
write_yaml(analysis, file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml')))


