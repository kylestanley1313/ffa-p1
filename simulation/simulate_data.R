library(argparser)
library(pbmcapply)
library(yaml)


source(file.path('utils', 'utils.R'))
source(file.path('simulation', 'utils', 'utils.R'))


simulate_data <- function(idx, config.ids, seeds, design.id) {
  
  # Unpack params and load design
  config.id <- config.ids[idx]
  set.seed(seeds[idx])
  design <- yaml.load_file(
    file.path('simulation', 'designs', str_glue('{design.id}.yml'))
  )
  
  ## Load and unpack config
  config <- yaml.load_file(
    file.path('simulation', 'data', design.id, config.id, 'config.yml')
  )
  M <- config$settings$M
  n <- config$settings$num_samps
  K <- config$settings$K
  J <- config$settings$J
  delta <- config$settings$delta
  
  ## Generate loading array
  L <- compute_loading_array(
    loading.scheme = config$settings$loading_scheme,
    loading.scales = seq(
      from = config$settings$loading_scale_range[[1]],
      to = config$settings$loading_scale_range[[2]],
      length.out = K
    ),
    M = M
  )
  L.mat <- array_reshape(L, dim = c(M*M, K))
  write_matrix(L.mat, config$dirs$data, 'L')
  
  ## Generate error array
  error.scales <- sample(seq(
    from = config$settings$error_scale_range[[1]],
    to = config$settings$error_scale_range[[2]],
    length.out = J
  ))
  E <- compute_error_array(config$settings$error_scheme, error.scales, delta, M)
  
  ## Generate samples
  for (r in 1:config$settings$num_reps) {
    X <- array(0, dim = c(M, M, n))

    for (i in 1:n) {

      f <- rnorm(K)
      b <- rnorm(J)
      for (k in 1:K) {
        X[,,i] <- X[,,i] + L[,,k]*f[k]
      }
      for (j in 1:J) {
        X[,,i] <- X[,,i] + E[,,j]*b[j]
      }
    }

    X.mat <- array_reshape(X, dim = c(M*M, n))
    C.hat.mat <- cov(t(X.mat))
    write_matrix(
      X.mat, file.path(design$scratch_root, config$dirs$data),
      'X', r = r
    )
    write_matrix(
      C.hat.mat, file.path(design$scratch_root, config$dirs$data),
      'Chat', r = r
    )

  }
}


## Execution ===================================================================

p <- arg_parser("Script to simulate data.")
p <- add_argument(p, "design.id", help = "ID of design")
p <- add_argument(p, "--seed", default = 12345, type = 'integer', help = "Seed used in random number generation.")
args <- parse_args(p)

config.ids <- list.dirs(
  file.path('simulation', 'data', args$design.id), 
  full.names = FALSE, recursive = FALSE
)
seeds <- gen_seeds(args$seed, length(config.ids))

print("----- START SIMULATIONS -----")
slurm.ntasks <- Sys.getenv('SLURM_NTASKS', unset = NA)
num.cores <- ifelse(is.na(slurm.ntasks), detectCores(), slurm.ntasks)
print(str_glue("Using {num.cores} cores..."))
out <- pbmclapply(
  1:length(config.ids), simulate_data,
  config.ids = config.ids,
  seeds = seeds,
  design.id = args$design.id,
  mc.cores = num.cores, 
  ignore.interactive = TRUE
)
print("----- END SIMULATIONS -----")





