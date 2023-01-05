library(argparser)
library(stringr)
library(yaml)


source(file.path('simulation', 'utils', 'utils.R'))


p <- arg_parser("Script to set up simulation.")
p <- add_argument(p, "design.id", help = "ID of design")
args <- parse_args(p)  ## TODO: Uncomment
# args <- list(design.id = 'des-1-test')  ## TODO: Remove

design <- yaml.load_file(file.path('simulation', 'designs', str_glue('{args$design.id}.yml')))

## Create directories
dir.create(file.path('simulation', 'data', args$design.id))
dir.create(file.path('simulation', 'results', args$design.id))
dir.create(file.path(design$scratch_root, 'simulation', 'data', args$design.id))

## Iniitalize config map
col.names <- c(
  'config.id', 'l.scheme', 'e.scheme', 'K', 'delta', 'n', 
  'l.scale.min', 'l.scale.max', 'e.scale.min', 'e.scale.max', 'M', 'J'
  )
config.map <- data.frame(matrix(nrow = 0, ncol = length(col.names)))
colnames(config.map) <- col.names

config.num <- 1
for (l.scheme in design$loading_schemes) {
  for (K in design$Ks) {
    for (l.scale.range in design$loading_scale_ranges) {
      for (e.scheme in design$error_schemes) {
        for (J in design$Js) {
          for (delta in design$deltas) {
            for (e.scale.range in design$error_scale_ranges) {
              for (n in design$num_samps) {
                
                config.id <- str_glue('config-{config.num}')
                
                dir.data <- file.path('simulation', 'data', args$design.id, config.id)
                dir.scratch.data <- file.path(design$scratch_root, dir.data)
                dir.results <- file.path('simulation', 'results', args$design.id, config.id)
                # dir.create(dir.data)
                if (!dir.exists(dir.scratch.data)) dir.create(dir.scratch.data)
                dir.create(dir.results)
                
                config <- list(
                  dirs = list(
                    data = dir.data,
                    results = dir.results
                  ),
                  settings = list(
                    M = design$M,
                    num_reps = design$num_reps, 
                    num_reps_rank = design$num_reps_rank,
                    loading_scheme = l.scheme,
                    K = K,
                    loading_scale_range = l.scale.range,
                    error_scheme = e.scheme,
                    J = J,
                    delta = delta,
                    delta_est = design$delta_est,
                    error_scale_range = e.scale.range,
                    num_samps = n
                  ),
                  tuning = list(
                    train_prop = design$train_prop,
                    num_reps = design$num_tuning_reps,
                    K_max = design$K_max,
                    selections = list(
                      rank_sim = list(alphas = NULL),
                      comp_sim = list(alphas = NULL, kappas = NULL)
                    )
                  )
                )
                # write_yaml(config, file.path(dir.data, 'config.yml'))
                
                row <- c(
                  config.num, l.scheme, e.scheme, K, delta, n, 
                  l.scale.range[1], l.scale.range[2], 
                  e.scale.range[1], e.scale.range[2], 
                  design$M, J
                )
                config.map[nrow(config.map)+1,] <- row
                
                config.num <- config.num + 1
                
              }
            }
          }
        }
      }
    }
  }
}

write.table(
  config.map, 
  file.path('simulation', 'results', args$design.id, 'config_map.csv'), 
  sep = ',',
  col.names = TRUE,
  row.names = FALSE,
  append = FALSE,
  quote = FALSE
)


