library(argparser)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('simulation', 'utils', 'utils.R'))



## Execution ===================================================================

p <- arg_parser("Script to estimate L via MELODIC.")
p <- add_argument(p, "design_id", help = "ID of design.")
p <- add_argument(p, "--num_facs", type = 'numeric', help = "Number of factors.")
p <- add_argument(p, "--archive", flag = TRUE, help = "Flag to archive old config.")
args <- parse_args(p)

config.ids <- list.dirs(
  file.path('simulation', 'data', args$design_id),
  full.names = FALSE, recursive = FALSE
)

for (config.id in config.ids) {
  
  ## Read in and (optionally) archive old config
  path.in <- file.path('simulation', 'data', args$design_id, config.id, 'config.yml')
  config <- yaml.load_file(path.in)
  if (args$archive) {
    path.out <- file.path('simulation', 'data', args$design_id, config.id, 'config-archive.yml')
    write_yaml(config, path.out)
  }
  
  ## Edit supported config fields
  if (!is.null(args$num_facs)) {
    config$settings$K <- args$num_facs
  }
  
  ## Write edited config
  write_yaml(config, path.in)
  
}

