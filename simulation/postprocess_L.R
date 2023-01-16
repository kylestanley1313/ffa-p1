library(argparser)
library(pbmcapply)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('simulation', 'utils', 'utils.R'))


p <- arg_parser("Script to tune the post-processing shrinkage parameter.")
p <- add_argument(p, "design.id", help = "ID of design")
args <- parse_args(p)  ## TODO: Uncomment
# args <- list(design.id = 'des-1-test')  ## TODO: Remove


postprocess_L <- function(config.id, design.id) {
  
  ## Load config
  config <- yaml.load_file(
    file.path('simulation', 'data', design.id, config.id, 'config.yml')
  )
  data.dir <- config$dirs$data
  
  for (rep in 1:config$settings$num_reps) {
    
    ## Get L.hat.smooth
    L.hat.smooth.mat <- csv_to_matrix(
      file.path(data.dir, format_matrix_filename('Lhat', method = 'dps', r = rep))
    )
    
    ## Rotate L.hat.smooth
    L.hat.smooth.star.mat <- varimax(L.hat.smooth.mat)$loadings
    write_matrix(L.hat.smooth.star.mat, data.dir, 'Lhat', method = 'dpsrot', r = rep)
    
    ## Shrink L.hat.smooth.star
    L.hat.smooth.star.sparse.mat <- shrink_loading(
      L.hat.smooth.star.mat, config$tuning$selections$comp_sim$kappas[rep]
    )
    write_matrix(
      L.hat.smooth.star.sparse.mat, data.dir, 'Lhat', method = 'ffa', r = rep
    )
    
  }
}


## Execution ===================================================================

config.ids <- list.dirs(
  file.path('simulation', 'data', args$design.id), 
  full.names = FALSE, recursive = FALSE
)

print("----- START POSTPROCESSING -----")
out <- pbmclapply(
  config.ids, postprocess_L, design.id = args$design.id, 
  ignore.interactive = TRUE
)
print("----- END POSTPROCESSING -----")