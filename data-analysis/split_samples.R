library(argparser)
library(pbmcapply)
library(RNifti)
library(yaml)


source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))


p <- arg_parser("Script for splitting samples into training and test sets.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
args <- parse_args(p)


perform_split <- function(split.specs, X_, num.times, dir) {
  ## NOTE: split.specs is list with key/value pairs...
  ##         split: train/test
  ##         v: # test
  ##         idx: vector of indices
  X.sub <- X_[,split.specs$idx]
  C.hat.sub <- cov(t(X.sub))
  write_matrix(
    X.sub, dir, 'X', 
    split.specs$v, split.specs$split
  )
  write_matrix(
    C.hat.sub, dir, 'Chat', 
    split.specs$v, split.specs$split
  )
}


## Execution ===================================================================

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
scratch.root <- analysis$scratch_root
dir.data <- analysis$dirs$data
M1 <- analysis$settings$M1
M2 <- analysis$settings$M2
z <- analysis$settings$z_
N <- analysis$settings$N_
num.tests <- analysis$settings$ffa$num_tests
prop.train <- analysis$settings$ffa$prop_train

## Read in full data
path.X <- file.path(scratch.root, dir.data, 'X.nii.gz')
X <- readNifti(path.X)
X <- X[,,z,]
dim(X) <- c(M1*M2, N)

## Compute and write covariance
C <- cov(t(X))
write_matrix(C, file.path(scratch.root, dir.data), 'Chat')

## Organize splits
splits <- list()
n.train <- round(prop.train*N)  ## number of samples to use for training
set.seed(1)
for (v in 1:num.tests) {
  
  idx.train <- sample(1:N, n.train)
  idx.test <- setdiff(1:N, idx.train)
  splits[[length(splits) + 1]] <- list(
    split = 'train', v = v, idx = idx.train
  )
  splits[[length(splits) + 1]] <- list(
    split = 'test', v = v, idx = idx.test
  )
  
}

## Perform splits
num.cores <- min(length(splits), detectCores())
options(mc.cores = num.cores)
print("----- START SPLITTING -----")
out <- pbmclapply(
  splits, perform_split, 
  X_ = X, dir = file.path(scratch.root, dir.data), 
  ignore.interactive = TRUE
)
print("----- END SPLITTING -----")

