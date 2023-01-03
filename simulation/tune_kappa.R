library(dplyr)
library(pbmcapply)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('simulation', 'utils', 'utils.R'))


p <- arg_parser("Script to tune the post-processing shrinkage parameter.")
p <- add_argument(p, "design.id", help = "ID of design")
# args <- parse_args(p)  ## TODO: Uncomment
args <- list(design.id = 'des-1-test')  ## TODO: Remove


tune_kappa <- function(config.id, design.id) {
  
  ## Load design
  design <- yaml.load_file(
    file.path('simulation', 'designs', str_glue('{design.id}.yml'))
  )
  
  ## Load config
  config <- yaml.load_file(
    file.path('simulation', 'data', design.id, config.id, 'config.yml')
  )
  data.dir <- config$dirs$data
  results.dir <- config$dirs$results
  
  A.mat <- create_band_deletion_array(
    config$settings$M, 
    config$settings$M, 
    config$settings$delta)$A.mat
  
  ## Create dataframe table.tune and vector kappa.stars for tuning results
  col.names <- c('kappa', 'rep', 'v', 'nobpe')
  data.tune <- data.frame(matrix(nrow = 0, ncol = length(col.names)))
  colnames(data.tune) <- col.names
  kappa.stars <- rep(0, config$settings$num_reps)
  for (rep in 1:config$settings$num_reps) {
    
    ## NOTE: This list caches matrices that we either don't want to read 
    ## repeatedly (e.g., C.hat.test, L.hat.sm) or that we don't want to compute
    ## repeatedly (e.g., L.hat.sm.st, L.hat.sm.st.sp). 
    cache <- list()
    kappas <- seq(0, 1, by = 0.001)  ## TODO: Choose grid
    for (l in 1:length(kappas)) {
      
      for (v in 1:config$tuning$num_reps) {
        
        ## Generate top-level keys for the cache
        notsparse.key <- str_glue('notsparse_{v}')
        sparse.key <- str_glue('sparse_{v}_{kappas[l]}')
        
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
          C.hat.test.fname <- format_matrix_filename('Chat', r = rep, v = v, split = 'test')
          L.hat.smooth.fname <- format_matrix_filename('Lhat', method = 'dps', r = rep, v = v, split = 'train')
          C.hat.test.mat <- csv_to_matrix(file.path(design$scratch_root, data.dir, C.hat.test.fname))
          L.hat.smooth.mat <- csv_to_matrix(file.path(data.dir, L.hat.smooth.fname))
          L.hat.smooth.star.mat <- varimax(L.hat.smooth.mat)$loadings
          write_matrix(
            L.hat.smooth.star.mat, data.dir, 'Lhat', 
            method = 'dpsrot', r = rep, v = v, split = 'train'
          )
          cache[[notsparse.key]] <- list(
            C.hat.test = C.hat.test.mat,
            L.hat.sm = L.hat.smooth.mat,
            L.hat.sm.st = L.hat.smooth.star.mat
          )
        }
        
        ## Shrink rotated loading estimates
        L.hat.smooth.star.sparse.mat <- shrink_loading(L.hat.smooth.star.mat, kappas[l])
        cache[[sparse.key]] <- L.hat.smooth.star.sparse.mat
        
        ## Compute normalized off-band prediction error and add row to data.tune
        nobpe <- norm(A.mat * 
                        (L.hat.smooth.star.sparse.mat %*% 
                           t(L.hat.smooth.star.sparse.mat) 
                         - C.hat.test.mat),
                      type = 'f') / norm(A.mat * C.hat.test.mat, type = 'f')
        data.tune[nrow(data.tune)+1,] <- c(kappas[l], rep, v, nobpe)
        
      }
      
      ## Determine whether MNOBPE is decreasing
      ##   - If it is, then
      ##       (i) store current kappa in kappa.stars
      ##       (ii) break from kappa loop
      ##   - If it is not, then proceed to next kappa
      if (l > 1) {
        mnobpe.last <- mean(filter(data.tune, rep == rep & kappa == kappas[l-1])$nobpe)
        mnobpe.curr <- mean(filter(data.tune, rep == rep & kappa == kappas[l])$nobpe)
        if (mnobpe.last - mnobpe.curr < 0) {
          
          kappa.stars[rep] <- kappas[l-1]
          
          for (v in 1:config$tuning$num_reps) {
            sparse.key <- str_glue('sparse_{v}_{kappas[l-1]}')
            L.hat.smooth.star.sparse.mat <- cache[[sparse.key]]
            write_matrix(
              L.hat.smooth.star.sparse.mat, config$dirs$data, 'Lhat', 
              method = 'ffa', r = rep, v = v, split = 'train'
            )
          }
          
          break  ## Move to next rep
        }
      }
    }
    
    ## Write tuning results to appropriate files   
    config$tuning$selections$comp_sim$kappas <- kappa.stars
    write_yaml(
      config, 
      file.path(data.dir, 'config.yml')
    )
    write.table(
      data.tune, 
      file.path(results.dir, 'data_tune_sparsity.csv'), 
      sep = ',',
      col.names = TRUE,
      row.names = FALSE,
      append = FALSE,
      quote = FALSE
    )
    
  }
}


## Execution ===================================================================

config.ids <- list.dirs(
  file.path('simulation', 'data', args$design.id), 
  full.names = FALSE, recursive = FALSE
)

print("----- START KAPPA TUNING -----")
out <- pbmclapply(
  config.ids, tune_kappa, design.id = args$design.id, 
  ignore.interactive = TRUE
)
print("----- END KAPPA TUNING -----")

