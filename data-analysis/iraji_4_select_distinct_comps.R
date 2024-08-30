library(argparser)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))


p <- arg_parser("Script for running FSL's MELODIC ICA.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
p <- add_argument(p, "--n_splits", type = 'numeric', help = "Number of splits.")
p <- add_argument(p, "--n_comps_list", type = 'numeric', nargs = Inf, help = "List of the number of components.")
p <- add_argument(
  p, "--max_corr", type = 'numeric', 
  help = "If two selected components have a correlation above this threshold, only the most stable is retained."
)
args <- parse_args(p)
# args <- list(
#   analysis.id = 'multi-sub-2',
#   n_splits = 4,
#   n_comps_list = c(8, 15),
#   max_corr = 0.6
# )
n.splits <- args$n_splits
tot.comps <- sum(args$n_comps_list)

## Load analysis and set paths
analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
dir.ica <- file.path(analysis$dir$data, 'iraji')

## Get correlation and component dataframes
path <- file.path(dir.ica, 'corrs.csv.gz')
df.corrs <- read.csv(path)
path <- file.path(dir.ica, 'comps-stable.csv')
df.comps <- read.csv(path)

## Filter correlation dataframe
df.corrs <- df.corrs %>%
  rename(s = s1, c = c1) %>%
  inner_join(df.comps, by = c('s', 'c')) %>%
  rename(s1 = s, c1 = c) %>%
  rename(s = s2, c = c2) %>%
  inner_join(df.comps, by = c('s', 'c')) %>%
  rename(s2 = s, c2 = c) %>%
  filter(corr >= args$max_corr) %>%
  arrange(desc(corr))


## Select spatially distinct components
while(nrow(df.corrs) > 0) {
  
  ## Extract split and column values
  s1 <- df.corrs$s1[1]
  c1 <- df.corrs$c1[1]
  s2 <- df.corrs$s2[1]
  c2 <- df.corrs$c2[1]
    
  ## Get the stability rank for each component in the pair
  rank1 <- which(df.comps$s == s1 & df.comps$c == c1)
  rank2 <- which(df.comps$s == s2 & df.comps$c == c2)
  s.remove <- ifelse(rank1 > rank2, s1, s2)
  c.remove <- ifelse(rank1 > rank2, c1, c2)
  print(str_glue("Remove ({s.remove},{c.remove})"))
  
  ## Remove component with worse rank from df.comps
  df.comps <- df.comps[-rank1,]
  rownames(df.comps) <- NULL
  
  ## Remove any row containing removed component from df.corrs
  idx.remove <- which(
    (df.corrs$s1 == s.remove & df.corrs$c1 == c.remove) |
    (df.corrs$s2 == s.remove & df.corrs$c2 == c.remove)
  )
  df.corrs <- df.corrs[-idx.remove,]
  rownames(df.corrs) <- NULL
    
}

## Write distinct comps to CSV
path <- file.path(dir.ica, 'comps-distinct.csv')
write.csv(df.comps, path, row.names = FALSE)

