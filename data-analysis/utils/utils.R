library(stringr)

get_sub_labs <- function(dir) {
  all.dirs <- list.dirs(dir, full.names = FALSE, recursive = FALSE)
  sub.labs <- c()
  for (dir in all.dirs) {
    if (str_starts(dir, 'sub-')) {
      sub.lab <- str_split(dir, '-')[[1]][2]
      sub.labs <- c(sub.labs, sub.lab)
    }
  }
  return(sub.labs)
}