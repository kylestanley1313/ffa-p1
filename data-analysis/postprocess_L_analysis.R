library(argparser)
library(dplyr)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))


p <- arg_parser("Script for postprocessing loadings.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
p <- add_argument(p, "--alpha", type = 'numeric', help = "Smoothing parameter for which to perform postprocessing.")
p <- add_argument(p, "--delta", type = 'numeric', help = "Bandwidth parameter for which to perform postprocessing.")
p <- add_argument(p, "--K", type = 'numeric', help = "Rank parameter for which to perform postprocessing.")
args <- parse_args(p)
analysis.id <- args$analysis.id
alpha <- args$alpha
delta <- args$delta
K <- args$K

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{analysis.id}.yml'))
)
dir.data <- analysis$dirs$data
dir.results <- analysis$dirs$results

## Read kappas from post-processing table
path <- file.path(
  dir.results, 'kappa-tuning',
  str_glue('kappas_K-{K}_alpha-{alpha}_delta-{delta}.csv')
)
kappas <- read.csv(path, header = FALSE)[,1]

L.hat <- csv_to_matrix(file.path(
  analysis$dirs$data, 
  gen_mat_fname('Lhat', K = K, alpha = alpha)
))
L.hat.star <- varimax(L.hat)$loadings
L.hat.pp <- shrink_loadings(L.hat.star, kappas)
write_matrix(L.hat.pp, dir.data, 'Lhatpp', K = K, alpha = alpha)
write_matrix(L.hat.star, dir.data, 'Lhatrot', K = K, alpha = alpha)
