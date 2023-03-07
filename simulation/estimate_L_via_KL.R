library(argparser)
library(parallelly)
library(pbmcapply)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('simulation', 'utils', 'utils.R'))


p <- arg_parser("Script to estimate L via truncation of the Karhunen-Loeve expansion.")
p <- add_argument(p, "design.id", help = "ID of design")
args <- parse_args(p)  ## TODO: Uncomment
# args <- list(design.id = 'des-1-test')  ## TODO: Remove


pll <- function(d) {
  p <- length(d)
  lq <- rep(0, p) 
  for (q in 1:(p-1)) {
    d1 <- d[1:q]
    d2 <- d[(q+1):p]
    mu1 <- mean(d1)
    mu2 <- mean(d2)
    var1 <- ifelse(length(d1) == 1, 0, var(d1))
    var2 <- ifelse(length(d2) == 1, 0, var(d2))
    sigma <- sqrt(((q - 1) * var1 + (p - q - 1) * var2) / (p - 2))
    lq[q] <- sum(log(dnorm(d1, mu1, sigma))) + sum(log(dnorm(d2, mu2, sigma)))
  }
  lq[p] <- sum(log(dnorm(d, mean(d), sd(d))))
  return(lq)
}


estimate_L_via_KL <- function(config.id, design.id) {
  
  ## Load design
  design <- yaml.load_file(
    file.path('simulation', 'designs', str_glue('{design.id}.yml'))
  )
  
  ## Load config
  config <- yaml.load_file(
    file.path('simulation', 'data', design.id, config.id, 'config.yml')
  )
  
  for (r in 1:config$settings$num_reps) {
    C.hat <- csv_to_matrix(file.path(
      design$scratch_root, config$dirs$data,
      format_matrix_filename('Chat', r = r)
    ))
    C.hat.eigen <- eigen(C.hat, symmetric = TRUE)
    vals <- C.hat.eigen$values
    vecs <- C.hat.eigen$vectors
    # K.star <- which(cumsum(vals) / sum(vals) >= 0.95)[1]
    # K.star <- config$settings$K
    K.star <- which.max(pll(vals))
    L.hat <- vecs[,1:K.star] %*% diag(sqrt(vals[1:K.star]))
    write_matrix(L.hat, config$dirs$data, 'Lhat', method = 'kl', r = r)
  }
  
}



## Execution ===================================================================

config.ids <- list.dirs(
  file.path('simulation', 'data', args$design.id), 
  full.names = FALSE, recursive = FALSE
)

print("----- START ESTIMATION -----")
num.cores <- availableCores()
print(str_glue("Using {num.cores} cores..."))
out <- pbmclapply(
  config.ids, estimate_L_via_KL, design.id = args$design.id,
  mc.cores = num.cores, ignore.interactive = TRUE
)
print("----- END ESTIMATION -----")

