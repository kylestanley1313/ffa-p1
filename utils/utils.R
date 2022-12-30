array_reshape <- function(A, dim) {
  dim(A) <- dim
  return(A)
}

csv_to_matrix <- function(path) {
  read.csv(path, header = FALSE) %>% 
    as.matrix() %>% 
    unname()
}
