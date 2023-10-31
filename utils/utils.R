library(dplyr)


gen_seeds <- function(seed, n) {
  set.seed(seed)
  max.int <- .Machine$integer.max
  seeds <- sample(1:max.int, n)
  return(seeds)
}


array_reshape <- function(A, dim) {
  dim(A) <- dim
  return(A)
}


csv_to_matrix <- function(path) {
  read.csv(path, header = FALSE) %>% 
    as.matrix() %>% 
    unname()
}


create_band_deletion_array <- function(M1, M2, delta) {
  A <- array(0, dim = c(M1, M2, M1, M2))
  delta.1 <- ceiling(M1*delta)
  delta.2 <- ceiling(M2*delta)
  for (m11 in 1:M1) {
    for (m21 in 1:M2) {
      for (m12 in 1:M1) {
        for (m22 in 1:M2) {
          diff.1 <- abs(m11 - m12)
          diff.2 <- abs(m21 - m22)
          if (diff.1 > delta.1 | diff.2 > delta.2) {
            A[m11, m21, m12, m22] <- 1
          }
        }
      }
    }
  }
  return(list(
    A = A, 
    A.mat = array_reshape(A, c(M1*M2, M1*M2))
  ))
}


shrink_loading <- function(L, kappa) {
  sign(L) * pmax(abs(L) - kappa/abs(L)^2, 0)
}


shrink_loadings <- function(L, kappas) {
  for (k in 1:length(kappas)) {
    L[,k] <- shrink_loading(L[,k], kappas[k])
  }
  return(L)
}

