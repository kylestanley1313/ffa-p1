library(argparser)
library(dplyr)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))


p <- arg_parser("Script for postprocessing loadings.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
args <- parse_args(p)


analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
K <- analysis$settings$ffa$K
alpha <- analysis$settings$ffa$alpha
kappas <- analysis$settings$ffa$kappas

L.hat <- csv_to_matrix(file.path(
  analysis$dirs$data, 
  gen_mat_fname('Lhat', K = K, alpha = alpha)
))
L.hat.star <- varimax(L.hat)$loadings
L.hat.pp <- shrink_loadings(L.hat.star, kappas)
write_matrix(L.hat.pp, analysis$dirs$data, 'Lhatpp', K = K, alpha = alpha)
write_matrix(L.hat.star, analysis$dirs$data, 'Lhatrot', K = K, alpha = alpha)
