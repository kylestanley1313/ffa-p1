library(argparser)
library(pbmcapply)
library(yaml)


source(file.path('utils', 'utils.R'))
source(file.path('simulation', 'utils', 'utils.R'))


p <- arg_parser("Script to simulate data.")
p <- add_argument(p, "design.id", help = "ID of design")
# args <- parse_args(p)  ## TODO: Uncomment
args <- list(design.id = 'des-1-test')  ## TODO: Remove


simulate_data <- function(config.id, design.id) {
  
  ## Load design
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

config.ids <- list.dirs(
  file.path('simulation', 'data', args$design.id), 
  full.names = FALSE, recursive = FALSE
)

print("----- START SIMULATIONS -----")
set.seed(1)
out <- pbmclapply(
  config.ids, simulate_data, design.id = args$design.id, 
  ignore.interactive = TRUE
  )
print("----- END SIMULATIONS -----")





