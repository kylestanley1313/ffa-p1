library(argparser)
library(pbmcapply)
library(yaml)


source(file.path('utils', 'utils.R'))
source(file.path('simulation', 'utils', 'utils.R'))


split_data <- function(idx, config.ids, seeds, design.id) {
  
  ## Unpack params and load design
  config.id <- config.ids[idx]
  set.seed(seeds[idx])
  design <- yaml.load_file(
    file.path('simulation', 'designs', str_glue('{design.id}.yml'))
  )
  
  ## Load config
  config <- yaml.load_file(
    file.path('simulation', 'data', design.id, config.id, 'config.yml')
  )
  num.train <- ceiling(config$settings$num_samps * config$tuning$train_prop)
  
  for (r in 1:config$settings$num_reps) {
    X.mat.path <- file.path(
      design$scratch_root, config$dirs$data, format_matrix_filename('X', r = r)
    )
    X.mat <- csv_to_matrix(X.mat.path)
    
    for (v in 1:config$tuning$num_reps) {
      
      train.idx <- sample(1:config$settings$num_samps, num.train)
      X.mat.train <- X.mat[,train.idx]
      X.mat.test <- X.mat[,-train.idx]
      C.hat.mat.train <- cov(t(X.mat.train))
      C.hat.mat.test <- cov(t(X.mat.test))
      write_matrix(
        X.mat.train, file.path(design$scratch_root, config$dirs$data), 
        mat = 'X', r = r, v = v, split = 'train'
      )
      write_matrix(
        X.mat.test, file.path(design$scratch_root, config$dirs$data), 
        mat = 'X', r = r, v = v, split = 'test'
      )
      write_matrix(
        C.hat.mat.train, file.path(design$scratch_root, config$dirs$data), 
        mat = 'Chat', r = r, v = v, split = 'train'
      )
      write_matrix(
        C.hat.mat.test, file.path(design$scratch_root, config$dirs$data), 
        mat = 'Chat', r = r, v = v, split = 'test'
      ) 
      
    }
  }
}


## Execution ===================================================================

p <- arg_parser("Script to split data into training and test sets.")
p <- add_argument(p, "design.id", help = "ID of design")
p <- add_argument(p, "--seed", default = 12345, type = 'integer', help = "Seed used in random number generation.")
args <- parse_args(p)

config.ids <- list.dirs(
  file.path('simulation', 'data', args$design.id), 
  full.names = FALSE, recursive = FALSE
)
seeds <- gen_seeds(args$seed, length(config.ids))

print("----- START SPLITTING -----")
slurm.ntasks <- Sys.getenv('SLURM_NTASKS', unset = NA)
num.cores <- ifelse(is.na(slurm.ntasks), detectCores(), slurm.ntasks)
print(str_glue("Using {num.cores} cores..."))
out <- pbmclapply(
  1:length(config.ids),
  split_data,
  config.ids = config.ids,
  seeds = seeds,
  design.id = args$design.id,
  mc.cores = num.cores, 
  ignore.interactive = TRUE
)
print("----- END SPLITTING -----")


