library(argparser)
library(fastICA)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))

p <- arg_parser("Script for preprocessing AOMIC resting state functional scans.")
p <- add_argument(p, "analysis.id", help = "ID of analysis.")
p <- add_argument(p, "--nonlinearity", default = 'logcosh', help = "Nonlinearity used during ICA unmixing.")
p <- add_argument(p, "--num_comps", default = 20, help = "Number of ICs to estimate.")
args <- parse_args(p)
analysis.id <- args$analysis.id
nl <- args$nonlinearity
num.comps <- args$num_comps

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{analysis.id}.yml'))
)
M1 <- analysis$settings$M1
M2 <- analysis$settings$M2
T_ <- analysis$settings$T_
temp.dir <- file.path(analysis$scratch_root, analysis$dirs$data, 'preprocessed-scans')
out.dir <- file.path(analysis$dirs$data, 'fast-ica')
dir.create(out.dir)

## Read in scans
paths <- list.files(temp.dir, full.names = TRUE)
num.scans <- length(paths)
data <- array(dim = c(M1, M2, num.scans*T_))
print("\n----- READING DATA ----- #")
for (i in 1:num.scans) { 
  print(str_glue("Reading scan {i} of {num.scans}"))
  idx <- ((i - 1) * T_ + 1):(i * T_)
  data[,,idx] <- csv_to_matrix(paths[i])
}
data <- array_reshape(data, c(M1*M2, num.scans*T_))

## Run ICA
## NOTE: In spatial ICA, mixing matrix A contains time courses. The source 
## matrix S contains independent spatial maps.
print("\n----- RUNNING FAST ICA ----- #")
out <- fastICA(data, num.comps)
S <- out$S
path <- file.path(out.dir, str_glue('maps_nl-{nl}_K-{num.comps}.csv.gz'))
write.table(
  S, gzfile(path),
  sep = ',',
  row.names = FALSE,
  col.names = FALSE,
  append = FALSE
)

