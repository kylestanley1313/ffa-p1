library(argparser)
library(pbmcapply)
library(RNifti)
library(yaml)


source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))


p <- arg_parser("Script for splitting samples into training and test sets.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
args <- parse_args(p)


compute_sums <- function(scan.file, num.tests, prop.train) {
  
  scan <- csv_to_matrix(scan.file)
  full.sum <- rowSums(scan)
  full.cnt <- ncol(scan)
  tests <- vector('list', num.tests)
  for (v in 1:num.tests) {

    train.bool <- sample(
      c(FALSE, TRUE), ncol(scan), 
      replace = TRUE, 
      prob = c(1 - prop.train, prop.train)
    )
    train.sum <- rowSums(scan[,train.bool])
    test.sum <- full.sum - train.sum

    tests[[v]] <- list(
      train.bool = train.bool, 
      train.sum = train.sum, 
      test.sum = test.sum
    )    
  }
  
  out <- list(full.sum = full.sum, full.cnt = full.cnt, tests = tests)
  
}


compute_file_covariance <- function(file.info, means, temp.dir) {
  
  sub_label <- str_match(file.info$path, 'mat-X(.*?).csv.gz')[2]
  print(sub_label)
  scan <- csv_to_matrix(file.info$path)
  scan <- scan[1:(M1*M2),]

  scan.cent <- scan - means$full.mean
  cov.full <- scan.cent %*% t(scan.cent)
  write_matrix(cov.full, temp.dir, str_glue('C{sub_label}'))
  rm(cov.full)

  for (v in 1:length(means$tests)) {

    scan.train.cent <- scan[,file.info$train.bools[[v]]] - means$tests[[v]]$train.mean
    scan.test.cent <- scan[,!file.info$train.bools[[v]]] - means$tests[[v]]$test.mean

    cov.train <- scan.train.cent %*% t(scan.train.cent)
    write_matrix(cov.train, temp.dir, str_glue('C{sub_label}'), v = v, split = 'train')
    rm(cov.train)

    cov.test <- scan.test.cent %*% t(scan.test.cent)
    write_matrix(cov.test, temp.dir, str_glue('C{sub_label}'), v = v, split = 'test')
    rm(cov.test)

  }
  
}
  


## Execution ===================================================================

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
scratch.root <- analysis$scratch_root
dir.data <- analysis$dirs$data
M1 <- analysis$settings$M1
M2 <- analysis$settings$M2
N <- analysis$settings$N_
num.tests <- analysis$settings$num_tests
prop.train <- analysis$settings$prop_train

## Get preprocessed scans
temp.dir <- file.path(scratch.root, dir.data, 'preprocessed-scans')
scan.files <- list.files(temp.dir, full.names = TRUE)


## Compute means for full data then split and compute means for test/train data
print("----- START COMPUTING MEANS -----")
set.seed(12345)
print("Computing file sums in parallel...")
num.cores <- detectCores()
print(str_glue("Found {num.cores} cores!"))
options(mc.cores = num.cores)
file.sums <- pbmclapply(
  scan.files, compute_sums,
  num.tests = num.tests, prop.train = prop.train, 
  ignore.interactive = TRUE
)
print("Combining file sums..")
sums <- list(full.sum = 0, full.cnt = 0, tests = vector('list', num.tests))
for (v in 1:num.tests) {
  sums$tests[[v]] <- list(
    train.sum = 0, train.cnt = 0, 
    test.sum = 0, test.cnt = 0
  )
}
for (i in 1:length(file.sums)) {
  sums$full.sum = sums$full.sum + file.sums[[i]]$full.sum
  sums$full.cnt = sums$full.cnt + file.sums[[i]]$full.cnt
  for (v in 1:num.tests) {
    sums$tests[[v]]$train.sum <- sums$tests[[v]]$train.sum + file.sums[[i]]$tests[[v]]$train.sum
    sums$tests[[v]]$train.cnt <- sums$tests[[v]]$train.cnt + sum(file.sums[[i]]$tests[[v]]$train.bool)
    sums$tests[[v]]$test.sum <- sums$tests[[v]]$test.sum + file.sums[[i]]$tests[[v]]$test.sum
    sums$tests[[v]]$test.cnt <- sums$tests[[v]]$test.cnt + sum(!file.sums[[i]]$tests[[v]]$train.bool)
  }
}
print("Computing means...")
means <- list(
  full.mean = sums$full.sum / sums$full.cnt,
  tests = vector('list', num.tests)
)
for (v in 1:num.tests) {
  means$tests[[v]] <- list(
    train.mean = sums$tests[[v]]$train.sum / sums$tests[[v]]$train.cnt,
    test.mean = sums$tests[[v]]$test.sum / sums$tests[[v]]$test.cnt
  )
}
print("----- DONE COMPUTING MEANS -----")

## Compile information needed to compute file-wise covariances
file.info <- vector('list', length(scan.files))
for (i in 1:length(scan.files)) {
  file.info[[i]] <- list(path = scan.files[i], train.bools = vector('list', num.tests))
  for (v in 1:num.tests) {
    file.info[[i]]$train.bools[[v]] <- file.sums[[i]]$tests[[v]]$train.bool
  }
}

## Create directory for storing file-wise covariances
temp.dir <- file.path(scratch.root, dir.data, 'scan-covariances')
dir.create(temp.dir)

## Compute file-wise covariances
print("----- START COMPUTING SCAN COVARIANCES -----")
out <- pbmclapply(
  file.info, compute_file_covariance,
  means = means, temp.dir = temp.dir,
  ignore.interactive = TRUE
)
print("----- DONE COMPUTING SCAN COVARIANCES -----")


## Assemble covariances and write
print("----- START ASSEMBLING COVARIANCES -----")
cov.dir <- file.path(scratch.root, dir.data)
cov.paths <- list.files(temp.dir, full.names = TRUE)

print("Full covariance...")
cov.full.paths <- cov.paths[grep('split', cov.paths, invert=TRUE)]
cov <- matrix(0, nrow = M1*M2, ncol = M1*M2)
for (path in cov.full.paths) {
  print(str_glue("\t file: {path}"))
  cov <- cov + csv_to_matrix(path)
}
cov <- cov / (sums$full.cnt - 1)
write_matrix(cov, cov.dir, 'Chat')
rm(cov)

for (v in 1:num.tests) {
  
  print(str_glue("Test {v} of {num.tests}..."))
  
  cov.train <- matrix(0, nrow = M1*M2, ncol = M1*M2)
  cov.train.paths <- cov.paths[grep(str_glue('v-{v}_split-train'), cov.paths)]
  for (path in cov.train.paths) {
    print(str_glue("\t file: {path}"))
    cov.train <- cov.train + csv_to_matrix(path)
  }
  cov.train <- cov.train / (sums$tests[[v]]$train.cnt - 1)
  write_matrix(cov.train, cov.dir, 'Chat', v = v, split = 'train')
  rm(cov.train)
  
  
  cov.test <- matrix(0, nrow = M1*M2, ncol = M1*M2)
  cov.test.paths <- cov.paths[grep(str_glue('v-{v}_split-test'), cov.paths)]
  for (path in cov.test.paths) {
    print(str_glue("\t file: {path}"))
    cov.test <- cov.test + csv_to_matrix(path)
  }
  cov.test <- cov.test / (sums$tests[[v]]$test.cnt - 1)
  write_matrix(cov.test, cov.dir, 'Chat', v = v, split = 'test')
  rm(cov.test)
}
print("----- DONE ASSEMBLING COVARIANCES -----")



