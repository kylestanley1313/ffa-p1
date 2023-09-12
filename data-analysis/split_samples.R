library(argparser)
library(pbmcapply)
library(RNifti)
library(yaml)


source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))


p <- arg_parser("Script for splitting samples into training and test sets.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
args <- parse_args(p)


process_chunk <- function(chunk, data) {
  
  chunk$cov <- NA
  for (i in 1:nrow(chunk)) {
    chunk[i,3] <- sum(data[chunk[i,1],] * data[chunk[i,2],])
  }
  return(chunk)
  
}


assemble_covariance <- function(out.chunks, num.vars, num.samps) {
  
  cov_ <- matrix(nrow = num.vars, ncol = num.vars)
  for (chunk in out.chunks) {
    for (r in 1:nrow(chunk)) {
      cov_[chunk[r,1], chunk[r,2]] <- chunk[r,3]
      cov_[chunk[r,2], chunk[r,1]] <- chunk[r,3]
    }
  }
  cov_ <- cov_ / (num.samps - 1)
  return(cov_)
  
}
  


## Execution ===================================================================

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
scratch.root <- analysis$scratch_root
dir.data <- analysis$dirs$data
N <- analysis$settings$N_
num.tests <- analysis$settings$ffa$num_tests
prop.train <- analysis$settings$ffa$prop_train

## Read in full data
path.X <- file.path(scratch.root, dir.data, gen_mat_fname('X'))
X <- csv_to_matrix(path.X)
X.cent <- X - rowMeans(X)

## Generate chunks of covariance matrix indices
num.vars <- nrow(X)
num.cores <- detectCores()
idx <- expand.grid(1:num.vars, 1:num.vars)
idx.mask <- idx[,1] <= idx[,2]
idx <- idx[idx.mask,]
chunks <- list()
chunk.size <- 10000
row <- 1
while (row <= nrow(idx)) {
  last.row <- min(row + chunk.size - 1, nrow(idx))
  chunks[[length(chunks)+1]] <- idx[row:last.row,]
  row <- last.row + 1
}

print("----- START ESTIMATION (FULL DATA) -----")
print("Esimating covariance in parallel...")
options(mc.cores = num.cores)
out <- pbmclapply(
  chunks, process_chunk,
  data = X.cent, 
  ignore.interactive = TRUE
)
print("Assembling covariance...")
C <- assemble_covariance(out, num.vars, ncol(X))
write_matrix(C, file.path(scratch.root, dir.data), 'Chat')
print("----- END ESTIMATION -----")



## Perform splits
n.train <- round(prop.train*N)  ## number of samples to use for training
set.seed(1)
for (v in 1:num.tests) {
  
  print(str_glue("---------- TEST {v} OF {num.tests} ----------"))
  
  idx.train <- sample(1:N, n.train)
  idx.test <- setdiff(1:N, idx.train)
  X.train <- X[,idx.train]
  X.test <- X[,idx.test]
  X.cent.train <- X.train - rowMeans(X.train)
  X.cent.test <- X.test - rowMeans(X.test)
  
  print("----- START ESTIMATION (TRAINING DATA) -----")
  print("Esimating covariance in parallel...")
  options(mc.cores = num.cores)
  out <- pbmclapply(
    chunks, process_chunk,
    data = X.cent.train, 
    ignore.interactive = TRUE
  )
  print("Assembling covariance...")
  C.train <- assemble_covariance(out, num.vars, length(idx.train))
  write_matrix(
    C.train, file.path(scratch.root, dir.data), 'Chat', 
    v = v, split = 'train'
  )
  print("----- END ESTIMATION -----")
  
  print("----- START ESTIMATION (TESTING DATA) -----")
  print("Esimating covariance in parallel...")
  options(mc.cores = num.cores)
  out <- pbmclapply(
    chunks, process_chunk,
    data = X.cent.test, 
    ignore.interactive = TRUE
  )
  print("Assembling covariance...")
  C.test <- assemble_covariance(out, num.vars, length(idx.test))
  write_matrix(
    C.test, file.path(scratch.root, dir.data), 'Chat', 
    v = v, split = 'test'
  )
  print("----- END ESTIMATION -----")
  
}



