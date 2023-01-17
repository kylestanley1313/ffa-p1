library(argparser)
library(pbmcapply)
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
  for (t in 1:num.times) {
    X.sub <- X_[[t]][split.specs$idx,]
    C.hat.sub <- cov(X.sub)
    write_matrix(
      X.sub, dir, 'X', 
      t, split.specs$v, split.specs$split
    )
    write_matrix(
      C.hat.sub, dir, 'CHat', 
      t, split.specs$v, split.specs$split
    )
  }
}


## Execution ===================================================================

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
scratch.root <- analysis$scratch_root
dir.data <- analysis$dirs$data
M1 <- analysis$outs$M1
M2 <- analysis$outs$M2
num.times <- analysis$outs$num_times
num.samps <- analysis$outs$num_samps
num.tests <- analysis$ins$num_tests
prop.train <- analysis$ins$prop_train

## Compile full data matrices
paths.samps <- list.files(
  analysis$dirs$samps, 
  full.names = TRUE
)
X <- list()
for (t in 1:num.times) {
  X[[t]] <- matrix(nrow = 0, ncol = M1*M2)
}
for (ps in paths.samps) {
  samp <- array_reshape(csv_to_matrix(ps), c(M1*M2, 1))
  for (t in 1:num.times) {
    if (str_detect(ps, str_glue('time-{t}'))) {
      X[[t]] <- rbind(X[[t]], t(samp))
      break
    }
  }
}

## Write full data matrices and covariances
for (t in 1:num.times) {
  write_matrix(X[[t]], file.path(scratch.root, dir.data), 'X', time = t)
  write_matrix(cov(X[[t]]), file.path(scratch.root, dir.data), 'Chat', time = t)
}


## Organize splits
splits <- list()
n.train <- round(prop.train*num.samps)  ## number of samples to use for training
set.seed(1)
for (v in 1:num.tests) {
  
  idx.train <- sample(1:num.samps, n.train)
  idx.test <- setdiff(1:num.samps, idx.train)
  splits[[length(splits) + 1]] <- list(
    split = 'train', v = v, idx = idx.train
  )
  splits[[length(splits) + 1]] <- list(
    split = 'test', v = v, idx = idx.test
  )

}


## Perform splits
print("----- START SPLITTING -----")
out <- pbmclapply(
  splits, perform_split, 
  X_ = X, num.times = num.times, dir = dir.data, 
  ignore.interactive = TRUE
)
print("----- END SPLITTING -----")


