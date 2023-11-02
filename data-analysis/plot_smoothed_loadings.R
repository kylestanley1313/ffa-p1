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
p <- add_argument(p, "--alphas", help = "Values of the smoothing parameter to plot.")
p <- add_argument(p, "--K", type = 'numeric', help = "Value of the rank to plot.")
args <- parse_args(p)
analysis.id <- args$analysis.id
alphas <- as.numeric(str_split(substr(args$alphas, 2, nchar(args$alphas) - 1), ' ')[[1]])
K <- args$K

## Read analysis
analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', paste0(analysis.id, '.yml'))
)
dir.data <- analysis$dirs$data
dir.results <- analysis$dirs$results
M1 <- analysis$settings$M1
M2 <- analysis$settings$M2
z <- analysis$settings$z_

## FFA
path.mask <- file.path('data-analysis', 'data', str_glue('common_mask_z-{z}.nii.gz'))
mask <- readNifti(path.mask)
dim(mask) <- c(M1*M2, 1)
masks <- matrix(rep(mask, K), ncol = K)

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








