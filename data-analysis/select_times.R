library(argparser)
library(yaml)


source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))

p <- arg_parser("Script to select times for FFA.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
args <- parse_args(p)


## Utilities ===================================================================

gen_events_fname <- function(
    sub,
    task,
    acq = 'seq',
    ext = 'tsv'
) {
  fname <- paste0(str_glue('sub-{sub}_task-{task}_acq-{acq}'),
                  str_glue('_events.{ext}'))
  return(fname)
}

gen_events_path <- function(data.type, sub, task) {
  fname <- gen_events_fname(sub, task)
  path <- file.path(dir.dataset, str_glue('sub-{sub}'), data.type, fname)
  return(path)
}


select_times_workingmemory <- function(sub.labs) {
  pairs <- rbind(
    # c(57, 54), # workingmemory-1
    # c(106, 101)
    # c(17, 22), # workingmemory-2
    # c(25, 22),
    # c(54, 57),
    # c(60, 57),
    # c(63, 67),
    # c(71, 67),
    # c(79, 82),
    # c(90, 85),
    # c(101, 106),
    # c(109, 106),
    # c(136, 140),
    # c(152, 144),
    # c(82, 85),
    # c(140, 144),
    # c(37, 40),
    # c(47, 50),
    # c(112, 115),
    # c(123, 126)
    c(79, 83),  ## workingmemory-3
    c(90, 86),
    c(136, 140),
    c(152, 148),
    c(83, 86),
    c(84, 87),
    c(140, 143),
    c(141, 144),
    c(142, 145),
    c(143, 146),
    c(144, 147),
    c(145, 148),
    c(146, 149)
  )
  times <- data.frame(matrix(nrow = 0, ncol = 3))
  colnames(times) <- c('sub', 't1', 't2')  ## t1 (active), t2 (passive)
  for (sub.lab in sub.labs) {
    for (r in 1:nrow(pairs)) {
      times[nrow(times) + 1,] <- c(sub.lab, pairs[r,1], pairs[r,2])
    }
  }
  return(list(times = times, num.times = nrow(pairs)))
}


select_times_emomatching <- function(sub.labs) {
  pairs <- rbind(
    # c(33, 18), # emomatching-1
    # c(56, 48),
    # c(93, 78),
    # c(123, 108)
    # c(23, 21), # emomatching-2
    # c(36, 38),
    # c(53, 51),
    # c(66, 68),
    # c(83, 81),
    # c(96, 98),
    # c(113, 111)
    c(23, 18),  ## emomatching-3
    c(26, 18),
    c(53, 48),
    c(56, 48),
    c(83, 78),
    c(86, 78),
    c(113, 108),
    c(116, 108),
    c(13, 16),
    c(16, 18),
    c(43, 46),
    c(46, 48),
    c(73, 76),
    c(76, 78),
    c(103, 106),
    c(106, 108)
  )
  times <- data.frame(matrix(nrow = 0, ncol = 3))
  colnames(times) <- c('sub', 't1', 't2')  ## t1 (emotion), t2 (control)
  for (sub.lab in sub.labs) {
    for (r in 1:nrow(pairs)) {
      times[nrow(times) + 1,] <- c(sub.lab, pairs[r,1], pairs[r,2])
    }
  }
  return(list(times = times, num.times = nrow(pairs)))
}

select.times.fcns <- list(
  workingmemory = select_times_workingmemory,
  emomatching = select_times_emomatching
)

## Execution ===================================================================

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
sub.labs <- get_sub_labs(analysis$dirs$dataset)
out <- select.times.fcns[[analysis$settings$task]](sub.labs)
times <- out$times
num.times <- out$num.times

## Write CSV
write.table(
  times, 
  file.path(analysis$dirs$results, 'times.csv'), 
  sep = ',',
  col.names = TRUE,
  row.names = FALSE,
  append = FALSE,
  quote = FALSE
)

## Update config
analysis$settings$num_times <- num.times
write_yaml(analysis, file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml')))
