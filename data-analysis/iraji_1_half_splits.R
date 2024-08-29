library(argparser)
library(stringr)
library(yaml)

p <- arg_parser("Script that prepares AOMIC data for MELODIC.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
p <- add_argument(p, "--n_splits", type = 'numeric', help = "Number of splits to generate.")
p <- add_argument(p, "--n_subs_per_split", type = 'numeric', help = "Number of subjects per split.")
p <- add_argument(p, "--sigma", type = 'numeric', help = "The sigma used previously to smooth data.")
p <- add_argument(p, "--seed", default = 12345, help = "Seed for reproducibility.")
args <- parse_args(p)

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
z <- analysis$settings$z_

## Get all possible subjects
dir.ica <- file.path(analysis$dirs$data, 'iraji')
dir.create(dir.ica, recursive = TRUE)
dir.pp <- file.path(analysis$scratch_root, analysis$dirs$data, 'preprocessed')
if (!is.na(args$sigma) | args$sigma > 0 ) {
  dir.in <- file.path(dir.pp, str_glue('temp_z-{z}_sigma-{args$sigma}'))
} else {
  dir.in <- file.path(dir.pp, str_glue('temp_z-{z}'))
}
sub.nums <- list()
for (sub.num in 1:216) {
  sub.lab <- str_pad(sub.num, 4, pad = '0')
  path <- file.path(dir.in, str_glue("{sub.lab}.nii.gz"))
  if (file.exists(path)) {
    sub.nums[[length(sub.nums)+1]] = sub.num
  }
}
sub.nums <- unlist(sub.nums)
print(path)

## Generate splits
if (length(sub.nums) < args$n_subs_per_split) {
  stop("Requested number of subjects per split exceeds the available number of subjects.")
} 
splits <- matrix(nrow = args$n_splits, ncol = args$n_subs_per_split)
set.seed(args$seed)
for (i in 1:args$n_splits) {
  splits[i,] <- sample(sub.nums, args$n_subs_per_split)
}
path <- file.path(dir.ica, 'splits.csv')
write.table(
  splits,
  path,
  sep = ',',
  row.names = FALSE,
  col.names = FALSE,
  append = FALSE
)




