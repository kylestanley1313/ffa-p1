library(argparser)
library(dplyr)
library(ggplot2)
library(ggpubr)
library(gridExtra)
library(reshape2)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))


p <- arg_parser("Script for plotting components generated via Iraji method.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
p <- add_argument(p, "--n_splits", type = 'numeric', help = "Number of splits.")
p <- add_argument(p, "--n_comps_list", type = 'numeric', nargs = Inf, help = "List of the number of components.")
args <- parse_args(p)
# args <- list(
#   analysis.id = 'multi-sub-2',
#   n_splits = 5,
#   n_comps_list = c(10, 20)
# )
n.splits <- args$n_splits
n.comps.list <- args$n_comps_list

## Load analysis and set paths
analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
M1 <- analysis$settings$M1
M2 <- analysis$settings$M2
dir.ica <- file.path(analysis$dir$data, 'iraji')
dir.results <- analysis$dir$results

## Load selected components
path <- file.path(dir.ica, 'comps-distinct.csv')
comps.idx <- read.csv(path)
comps <- matrix(nrow = M1*M2, ncol = nrow(comps.idx))
for (i in 1:nrow(comps.idx)) {
  s <- comps.idx[i,1]
  c <- comps.idx[i,2] 
  comps.list <- list()
  for (n.comps in n.comps.list) {
    path <- file.path(dir.ica, str_glue('IC_split-{s}_K-{n.comps}.csv.gz'))
    comps.list[[length(comps.list)+1]] <- csv_to_matrix(path)
  }
  comps.split <- do.call(cbind, comps.list)
  comps[,i] <- comps.split[,c]
}


## Plotting
ncomps <- ncol(comps)
comps <- array_reshape(comps, c(M1, M2, ncomps))
page.nrow <- min(5, ceiling(sqrt(ncomps)))
page.ncol <- min(5, floor(sqrt(ncomps)))
num.comps.per.page <- page.nrow * page.ncol
num.pages <- ceiling(ncomps / num.comps.per.page)
data <- melt(comps)
colnames(data) <- c('x', 'y', 'k', 'val')
breaks <- c(-2, -1, 0, 1, 2)
max.pltmag <- max(abs(data$val))
for (i in 1:num.pages) {
  plots <- vector('list', num.comps.per.page)
  for (j in 1:num.comps.per.page) {
    plots[[j]] <- plot_loading(data, (i-1) * num.comps.per.page + j, 0, breaks, max.pltmag, log.scale = FALSE)
  }
  g <- ggarrange(
    plotlist = plots,
    nrow = page.nrow, ncol = page.ncol, 
    common.legend = TRUE, 
    legend = 'bottom'
  )
  if (num.pages > 1) {
    path <- file.path(dir.results, str_glue('rs-iraji-{i}.png'))
  } else {
    path <- file.path(dir.results, str_glue('rs-iraji.png'))
  }
  ggexport(g, filename=path, width=200*page.ncol, height=200*page.nrow)
}



