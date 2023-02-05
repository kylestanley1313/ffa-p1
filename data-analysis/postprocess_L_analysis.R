library(argparser)
library(dplyr)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))


p <- arg_parser("Script for postprocessing loadings.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
p <- add_argument(p, "time", help = "time (1, 2, 3, ...)")
args <- parse_args(p)


analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
kappas <- as.numeric(analysis$settings$kappas[[str_glue('time_{args$time}')]])  ## Appropriately re-order these

L.hat <- csv_to_matrix(file.path(
  analysis$dirs$data, gen_mat_fname('Lhat', time = args$time)
))
L.hat.star <- varimax(L.hat)$loadings
L.hat.pp <- shrink_loadings(L.hat.star, kappas)
write_matrix(L.hat.pp, analysis$dirs$data, 'Lhatpp', time = args$time)
write_matrix(L.hat.star, analysis$dirs$data, 'Lhatrot', time = args$time)
