library(argparser)
library(pbmcapply)
library(reshape2)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))



## Helpers =====================================================================

compute_pair_corrs <- function(
    pair.num, 
    split.pairs, 
    dir.ica, 
    n.splits, 
    n.comps.list
) {
  
  pair <- split.pairs[pair.num,]
  
  ## Get component matrices
  comps1.list <- list()
  comps2.list <- list()
  for (n.comps in n.comps.list) {
    
    path <- file.path(dir.ica, str_glue('IC_split-{pair[1]}_K-{n.comps}.csv.gz'))
    comps1.list[[length(comps1.list)+1]] <- csv_to_matrix(path)
    
    path <- file.path(dir.ica, str_glue('IC_split-{pair[2]}_K-{n.comps}.csv.gz'))
    comps2.list[[length(comps2.list)+1]] <- csv_to_matrix(path)
  }
  comps1 <- do.call(cbind, comps1.list)
  comps2 <- do.call(cbind, comps2.list)
  
  ## Get correlation dataframe
  corrs <- cor(comps1, comps2)
  corrs <- melt(corrs)
  colnames(corrs) <- c('c1', 'c2', 'corr')
  corrs$s1 <- pair[1]
  corrs$s2 <- pair[2]
  corrs <- corrs[,c(4, 5, 1, 2, 3)]
  
  ## Write correlation dataframe
  path <- file.path(dir.ica, str_glue('corrs-{pair.num}.csv.gz'))
  write.csv(corrs, gzfile(path), row.names = FALSE)
  
}


process_df_stab <- function(df.stab, corrs) {
  
  df.match.list <- list()
  for (j in 1:nrow(df.stab)) {
    
    # Get jth split and component
    s <- df.stab[j,1]
    c <- df.stab[j,2]
    
    ## Get corr rows for this split and component
    tmp1 <- corrs %>%
      filter(s1 == s, c1 == c) %>%
      select(-c('s1', 'c1')) %>%
      rename(s = s2, c = c2)
    tmp2 <- corrs %>%
      filter(s2 == s, c2 == c) %>%
      select(-c('s2', 'c2')) %>%
      rename(s = s1, c = c1)
    tmp <- rbind(tmp1, tmp2)
    
    ## Get the best matches and their correlations
    matches <- tmp %>% 
      arrange(s, desc(corr)) %>%
      group_by(s) %>%
      mutate(rank = rank(desc(corr), ties.method = 'first')) %>%
      filter(rank == 1) %>%
      select(s, c, corr)
    
    ## Update df.stab
    df.stab[j,3] <- mean(matches$corr)
    
    ## Add to df.match
    df.match.list[[length(df.match.list)+1]] <- matches %>%
      select(s, c) %>%
      rename(s.match = s, c.match = c) %>%
      mutate(s = s, c = c) %>%
      select(s, c, s.match, c.match) %>%
      as_tibble()
    
  }
  df.match <- bind_rows(df.match.list)
  return(list(
    df.stab = df.stab,
    df.match = df.match
  ))
}



## Execution ===================================================================

p <- arg_parser("Script for running FSL's MELODIC ICA.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
p <- add_argument(p, "--n_splits", type = 'numeric', help = "Number of splits.")
p <- add_argument(p, "--n_comps_list", type = 'numeric', nargs = Inf, help = "List of the number of components.")
args <- parse_args(p)
args <- list(
  analysis.id = 'multi-sub-2',
  n_splits = 4,
  n_comps_list = c(10, 20)
)
n.splits <- args$n_splits
tot.comps <- sum(args$n_comps_list)

## Load analysis and set paths
analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
dir.ica <- file.path(analysis$dir$data, 'iraji')

## Generate split pairs
splits <- 1:n.splits
split.pairs <- expand.grid(splits, splits)
split.pairs <- unname(data.matrix(split.pairs))
split.pairs <- split.pairs[split.pairs[,1] < split.pairs[,2],]

## Multiprocessing configuration
slurm.ntasks <- Sys.getenv('SLURM_NTASKS', unset = NA)
num.cores <- ifelse(is.na(slurm.ntasks), detectCores(), slurm.ntasks)
print(str_glue("Found {num.cores} cores!"))
options(mc.cores = num.cores)

## Compute pair correlations in parallel
print("----- START COMPUTING CORRELATIONS -----")
out <- pbmclapply(
  1:nrow(split.pairs), compute_pair_corrs,
  split.pairs = split.pairs,
  dir.ica = dir.ica,
  n.splits = n.splitsargs,
  n.comps.list = args$n_comps_list,
  ignore.interactive = TRUE
)
print("----- END COMPUTING CORRELATIONS -----")

## Aggregate corrs dataframes
corrs.list <- list()
for (i in 1:nrow(split.pairs)) {
  path <- file.path(dir.ica, str_glue('corrs-{i}.csv.gz'))
  corrs.list[[length(corrs.list)+1]] <- read.csv(path)
  unlink(path)
}
corrs <- do.call(rbind, corrs.list)
path <- file.path(dir.ica, 'corrs.csv.gz')
write.csv(corrs, path, row.names = FALSE)


# ---------- Select Components ---------- #
print("----- START SELECTING COMPONENTS -----")

## Instantiate dataframes for...
##  - the best components
##  - the components to exclude from subsequent interations
df.best <- data.frame(
  s = numeric(), 
  c = numeric()
)
df.exclude <- data.frame(
  s = numeric(), 
  c = numeric()
)

for (i in 1:tot.comps) {
  
  ## Instantiate dataframe for stability coefficients, excluding components that
  ## have either been selected or were the best matches of those selected
  df.stab <- data.frame(
    s = rep(1:n.splits, each = tot.comps),
    c = rep(1:tot.comps, n.splits),
    coeff = NA
  )
  df.stab <- df.stab %>%
    anti_join(df.exclude, by = c('s', 'c'))
  
  ## Process df.stab in chunks
  chunk.size <- ceiling(nrow(df.stab) / num.cores)
  df.stab.chunks <- split(df.stab, ceiling(seq_len(nrow(df.stab)) / chunk.size))
  out <- pbmclapply(
    df.stab.chunks, process_df_stab,
    corrs = corrs
  )
  
  ## Handle multiprocessing output
  df.stab.list <- list()
  df.match.list <- list()
  for (k in 1:length(out)) {
    df.stab.list[[k]] <- out[[k]]$df.stab
    df.match.list[[k]] <- out[[k]]$df.match
  }
  df.stab <- bind_rows(df.stab.list)
  df.match <- bind_rows(df.match.list)
  
  
  # ---------- Component Selection ---------- #
  
  ## Select most stable component and identify its matches
  best <- df.stab %>%
    arrange(desc(coeff)) %>%
    filter(row_number() == 1) %>%
    select(s, c)
  best.matches <- df.match %>%
    filter(s == best$s, c == best$c) %>%
    select(s.match, c.match) %>%
    rename(s = s.match, c = c.match)
  df.best <- bind_rows(df.best, best)
  
  ## Log selection
  coeff <- df.stab %>%
    filter(s == best$s, c == best$c) %>%
    select(coeff)
  print(str_glue("Selection {i}: split = {best$s} | comp = {best$c} | coeff = {coeff}"))
  
  ## Remove best component and matches from corrs
  df.exclude <- df.exclude %>%
    bind_rows(best) %>%
    bind_rows(best.matches)
  corrs <- corrs %>%
    rename(s = s1, c = c1) %>%
    anti_join(df.exclude, by = c('s', 'c')) %>%
    rename(s1 = s, c1 = c) %>%
    rename(s = s2, c = c2) %>%
    anti_join(df.exclude, by = c('s', 'c')) %>%
    rename(s2 = s, c2 = c)
  
}

## Write df.best to CSV
path <- file.path(dir.ica, 'comps-stable.csv')
write.csv(df.best, path, row.names = FALSE)

print("----- END SELECTING COMPONENTS -----")



