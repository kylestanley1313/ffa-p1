library(argparser)
library(dplyr)
library(pbmcapply)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))


p <- arg_parser("Script for tuning the shrinkage parameter.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
p <- add_argument(p, "time", help = "time (1, 2, 3, ...)")
args <- parse_args(p)


tune_kappa <- function(analysis, time, kappa.grid) {
  
  ## Unpack analysis
  scratch.root <- analysis$scratch_root
  dir.data <- analysis$dirs$data
  dir.results <- analysis$dirs$results
  M1 <- analysis$settings$M1
  M2 <- analysis$settings$M2
  delta <- analysis$settings$delta
  num.tests <- analysis$settings$num_tests
  
  A.mat <- create_band_deletion_array(M1, M2, delta)$A.mat
  
  ## Create dataframe table.tune to store tuning results
  col.names <- c(sapply(1:ncol(kappa.grid), function(k) str_glue("kappa_{k}")), 'v', 'err')
  data.tune <- data.frame(matrix(nrow = 0, ncol = length(col.names)))
  colnames(data.tune) <- col.names
  
  ## NOTE: This list caches matrices that we either don't want to read 
  ## repeatedly (e.g., C.hat.test, L.hat.sm) or that we don't want to compute
  ## repeatedly (e.g., L.hat.sm.st, L.hat.sm.st.sp). 
  cache <- list()
  
  for (i in 1:nrow(kappa.grid)) {
    print(str_glue("{i} of {nrow(kappa.grid)}"))
    kappas <- as.numeric(kappa.grid[i,])
    for (v in 1:num.tests) {
      
      ## Generate top-level keys for the cache
      notsparse.key <- str_glue('notsparse_{v}')
      sparse.key <- str_glue('sparse_{v}_{i}')
      
      ## Either 
      ##   (i) retrieve C.hat.test, L.hat.sm, and L.hat.sm.st from the 
      ##       cache, or
      ##   (ii) read C.hat.test and L.hat.sm from files, rotate L.hat.sm, 
      ##        then store everything in the cache
      if (notsparse.key %in% names(cache)) {
        C.hat.test.mat <- cache[[notsparse.key]][['C.hat.test']]
        L.hat.smooth.mat <- cache[[notsparse.key]][['L.hat.sm']]
        L.hat.smooth.star.mat <- cache[[notsparse.key]][['L.hat.sm.st']]
      }
      else {
        C.hat.test.fname <- gen_mat_fname('Chat', time = time, v = v, split = 'test')
        L.hat.smooth.fname <- gen_mat_fname('Lhat', time = time, v = v, split = 'train')
        C.hat.test.mat <- csv_to_matrix(file.path(scratch.root, dir.data, C.hat.test.fname))
        L.hat.smooth.mat <- csv_to_matrix(file.path(dir.data, L.hat.smooth.fname))
        L.hat.smooth.star.mat <- varimax(L.hat.smooth.mat)$loadings
        write_matrix(
          L.hat.smooth.star.mat, dir.data, 'Lhatrot', 
          time = time, v = v, split = 'train'
        )
        cache[[notsparse.key]] <- list(
          C.hat.test = C.hat.test.mat,
          L.hat.sm = L.hat.smooth.mat,
          L.hat.sm.st = L.hat.smooth.star.mat
        )
      }
      
      # Shrink loadings
      L.hat.smooth.star.sparse.mat <- shrink_loadings(L.hat.smooth.star.mat, kappas)
      cache[[sparse.key]] <- L.hat.smooth.star.sparse.mat
      
      ## Compute normalized off-band prediction error and add row to data.tune
      err <- norm(A.mat * 
                    (L.hat.smooth.star.sparse.mat %*% 
                       t(L.hat.smooth.star.sparse.mat) 
                     - C.hat.test.mat),
                  type = 'f') / norm(A.mat * C.hat.test.mat, type = 'f')
      data.tune[nrow(data.tune)+1,] <- c(kappas, v, err)
      
    }
  }
  
  return(data.tune)
}



## Working Memory ==============================================================

## NOTE: kappa^(1/3) gives the largest magnitude that will be shrunk to zero.

## To focus the search grid, the following we fixed 4 of 5 kappas at
## zero, then observed error behavior as the remaining kappa changed.
##  - kappa.1 strictly decreasing until 200^3 
##  - kappa.2 strictly decreasing until 100^3
##  - kappa.3 local min in [0, 50^3]
##  - kappa.4 strictly increasing until 200^3
##  - kappa.5 local min in [0, 50^3]

## Based on the above analysis, we construct the search grid
kappa.1 <- c(1000^3)
kappa.2 <- c(1000^3)
kappa.3 <- seq(0, 50^3, length.out = 20)
kappa.4 <- c(0)
kappa.5 <- seq(0, 50^3, length.out = 20)
kappa.grid <- expand.grid(kappa.1, kappa.2, kappa.3, kappa.4, kappa.5)


analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
out <- tune_kappa(analysis, args$time, kappa.grid)
out[which.min(out$err),]  ## TUNED KAPPAS

