library(stringr)
library(yaml)


source(file.path('simulation', 'utils', 'utils.R'))


p <- arg_parser("Script to set up simulation.")
p <- add_argument(p, "design.id", help = "ID of design")
# args <- parse_args(p)  ## TODO: Uncomment
args <- list(design.id = 'des-1-test')  ## TODO: Remove

design <- yaml.load_file(file.path('simulation', 'designs', str_glue('{args$design.id}.yml')))

## Create directories
dir.create(file.path('simulation', 'data', args$design.id))
dir.create(file.path('simulation', 'results', args$design.id))
dir.create(file.path(design$scratch_root, 'simulation', 'data', args$design.id))


config.num <- 1
for (l.scheme in design$loading_schemes) {
  for (K in design$Ks) {
    for (l.scale.range in design$loading_scale_ranges) {
      for (e.scheme in design$error_schemes) {
        for (J in design$Js) {
          for (delta in design$deltas) {
            for (e.scale.range in design$error_scale_ranges) {
              for (N in design$num_samps) {
                
                config.id <- str_glue('config-{config.num}')
                
                dir.data <- file.path('simulation', 'data', args$design.id, config.id)
                dir.scratch.data <- file.path(design$scratch_root, dir.data)
                dir.results <- file.path('simulation', 'results', args$design.id, config.id)
                dir.create(dir.data)
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
                    num_samps = N
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
                write_yaml(config, file.path(dir.data, 'config.yml'))
                
                config.num <- config.num + 1
                
              }
            }
          }
        }
      }
    }
  }
}


