library(argparser)
library(dplyr)
library(GPArotation)
library(pbmcapply)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))


p <- arg_parser("Script for tuning the shrinkage parameter.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
p <- add_argument(p, "time", help = "time (1, 2, 3, ...)")
args <- parse_args(p)


tune_kappa <- function(kappa.grids, L.star.train, C.test, A) {
  
  ## NOTE: The kth element of kappa.grids contains all candidate values of 
  ## kappa.star[k]. To choose kappa.star[k], we fix kappa[j] = 0, j != k, then
  ## choose the value in the kth column of kappa.grids that minimizes the
  ## error. In this sense, we choose kappa.star[k] marginally. 
  
  K <- length(kappa.grids)
  kappa.star <- rep(NA, K)
  
  all.errs <- c() ## DEBUG
  
  for (k in 1:K) {
    kappa.grid <- kappa.grids[[k]]
    num.kappas <- length(kappa.grid)
    errs <- rep(NA, num.kappas)
    
    for (i in 1:num.kappas) {
      kappa.test <- rep(0, K)
      kappa.test[k] <- kappa.grid[i]
      
      # Shrink loadings
      L.star.sparse.train <- shrink_loadings(L.star.train, kappa.test)
      
      ## Compute normalized off-band prediction error
      errs[i] <- norm(A * (L.star.sparse.train %*% t(L.star.sparse.train) - C.test),
                      type = 'f') / norm(A * C.test, type = 'f')
      
      all.errs <- c(all.errs, errs[i]) ## DEBUG
      
    }
    
    kappa.star[k] <- kappa.grid[which.min(errs)]
  }
  
  return(kappa.star)
}


## Execution ===================================================================

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
scratch.root <- analysis$scratch_root
dir.data <- analysis$dirs$data
M1 <- analysis$settings$M1
M2 <- analysis$settings$M2
delta <- analysis$settings$ffa$delta
K <- analysis$settings$ffa$K
alpha <- analysis$settings$ffa$alpha

## Get input matrices
A <- create_band_deletion_array(M1, M2, delta)$A.mat
C.test.fname <- gen_mat_fname('Chat', v = 1, split = 'test')
L.fname <- L.fname <- gen_mat_fname('Lhat', K = K, alpha = alpha)
L.train.fname <- gen_mat_fname('Lhat', K = K, alpha = alpha, v = 1, split = 'train')
C.test <- csv_to_matrix(file.path(scratch.root, dir.data, C.test.fname))
L <- csv_to_matrix(file.path(dir.data, L.fname))
L.train <- csv_to_matrix(file.path(dir.data, L.train.fname))
L.star <- varimax(L)$loadings
L.star.train <- targetT(L.train, Target = L.star)$loadings
write_matrix(
  L.star.train, dir.data, 'Lhatrot', 
  K = K, alpha = alpha, v = 1, split = 'train'
)

## Construct kappa grid
kappa.grids <- list()
for (k in 1:K) {
  max.val <- max(abs(L.star[,k]))
  kappa.grids[[length(kappa.grids)+1]] <- seq(0, max.val + 0.01, by = 0.01)^3
}

## Tune kappa and write to config
kappa.star <- tune_kappa(kappa.grids, L.star.train, C.test, A)
analysis$settings$ffa$kappas <- kappa.star
write_yaml(analysis, file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml')))

