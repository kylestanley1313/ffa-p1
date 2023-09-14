library(argparser)
library(dplyr)
library(ggplot2)
library(ggpubr)
library(gridExtra)
library(reshape2)
library(RNifti)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))

p <- arg_parser("Script for plotting loadings smoothed according to different 
                valuesof the smoothing parameter.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
p <- add_argument(p, "alphas", help = "Values of the smoothing parameter to plot.")
args <- parse_args(p)
analysis.id <- args$analysis.id
alphas <- as.numeric(str_split(substr(args$alphas, 2, nchar(args$alphas) - 1), ' ')[[1]])
# args <- list(analysis.id = 'rs-sub-0181', alphas = c(20, 30, 40))  ## TODO: Remove

## Read analysis
analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', paste0(analysis.id, '.yml'))
)
dir.dataset <- analysis$dirs$dataset
dir.results <- analysis$dirs$results
sub <- analysis$settings$sub_label
M1 <- analysis$settings$M1
M2 <- analysis$settings$M2
K <- analysis$settings$ffa$K

## FFA
path.mask <- file.path(
  dir.dataset,
  'derivatives', 'fmriprep',
  str_glue('sub-{sub}'), 'func',
  str_glue('sub-{sub}_task-restingstate_acq-mb3_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz')
)
mask <- readNifti(path.mask)
dim(mask) <- c(M1*M2, dim(mask)[3])
masks <- matrix(rep(mask[,30], K), ncol = K)

for (alpha in alphas) {

  fname <- str_glue('mat-Lhat_K-{K}_alpha-{alpha}.csv.gz')
  path <- file.path('data-analysis', 'data', analysis.id, fname)
  L.mat <- csv_to_matrix(path)
  L.mat <- masks*L.mat
  L <- array_reshape(L.mat, c(M1, M2, K))
  data <- melt(L)
  colnames(data) <- c('x', 'y', 'k', 'val')

  plots <- list()
  max.abs.val <- max(abs(data$val))
  breaks <- c(
    -round(2 * max.abs.val / 3, 2),
    -round(max.abs.val / 3, 2),
    0,
    round(max.abs.val / 3, 2),
    round(2 * max.abs.val / 3, 2)
  )
  for (k in 1:K) {
    plots[[k]] <- plot_loading(data, k, 0, breaks)
  }
  n.row.col = ceiling(sqrt(K))
  g <- ggarrange(
    plotlist = plots,
    nrow = n.row.col, ncol = n.row.col,
    common.legend = TRUE,
    legend = 'bottom'
  )
  path <- file.path(dir.results, str_glue('Lhat_K-{K}_alpha-{alpha}.png'))
  ggexport(g, filename=path, width=800, height=800)


}







