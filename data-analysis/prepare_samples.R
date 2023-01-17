library(argparser)
library(pbmcapply)
library(RNifti)
library(yaml)


source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))


p <- arg_parser("Script to wrangle fMRI data to FFA-compatible format.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
args <- parse_args(p)


## Utilities ===================================================================

gen_fmriprep_fname <- function(
    sub,
    task,
    acq = 'seq',
    space = 'MNI152NLin2009cAsym',
    desc = 'preproc',
    suffix = 'bold',
    ext = 'nii.gz'
) {
  fname <- paste0(str_glue('sub-{sub}_task-{task}_acq-{acq}_space-{space}'),
                  str_glue('_desc-{desc}_{suffix}.{ext}'))
  return(fname)
}

gen_fmriprep_path <- function(data.type, sub, task, dir.dataset) {
  fname <- gen_fmriprep_fname(sub, task)
  path <- file.path(
    dir.dataset, 'derivatives', 'fmriprep', 
    str_glue('sub-{sub}'), data.type, fname
  )
  return(path)
}

gen_samp_fname <- function(sub.lab, time) {
  return(str_glue('sub-{sub.lab}_time-{time}.csv.gz'))
}

samp_to_csv <- function(samp, dir, sub.lab, time) {
  fname <- gen_samp_fname(sub.lab, time)
  path <- file.path(dir, fname)
  write.table(
    samp,
    gzfile(path),
    sep = ',',
    row.names = FALSE,
    col.names = FALSE,
    append = FALSE
  )
}

prepare_sample <- function(
    sub.lab, 
    times, 
    num.times, 
    task, 
    z, 
    dir.dataset, 
    scratch.root, 
    dir.samps) {
  ## Exit Codes: 
  ##   0: success
  ##   1: warning/error
  sub.times <- times[times$sub == sub.lab,]
  out <- tryCatch({
    path <- gen_fmriprep_path('func', sub.lab, task, dir.dataset)
    samp.full <- readNifti(path)
    samps <- list()
    for (r in 1:nrow(sub.times)) {
      samps[[length(samps)+1]] <- samp.full[,,z,sub.times$t1[r]] - 
        samp.full[,,z,sub.times$t2[r]] ## Difference sample
    }
    samps
  }, error = function(e) {
    message(str_glue("Error: failed to read in sub-{sub.lab}."))
    return(NULL)
  }, warning = function(w) {
    message(str_glue("Warning: failed to read in sub-{sub.lab}."))
    return(NULL)
  })
  
  if (!is.null(out)) {
    for (t in 1:num.times) {
      samp_to_csv(out[[t]], file.path(scratch.root, dir.samps), sub.lab, t)
    }
    return(0)
  }
  else{
    return(1)
  }
  
}


## Execution ===================================================================

analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml'))
)
times <- read.csv(
  file.path(analysis$dirs$results, 'times.csv'), 
  colClasses = c('sub' = 'character')
)
sub.labs <- unique(times$sub)
dir.create(file.path(analysis$scratch_root, analysis$dirs$samps))

print("----- START SAMPLE PREPARATION -----")
out <- pbmclapply(
  sub.labs[1:2], prepare_sample, 
  times = times, num.times = analysis$outs$num_times, 
  task = analysis$ins$task, z = analysis$ins$z_,
  dir.dataset = analysis$dirs$dataset,
  scratch.root = analysis$scratch_root,
  dir.samps = analysis$dirs$samps,
  ignore.interactive = TRUE
)
print("----- END SAMPLE PREPARATION -----")

## Results summary
num.tot <- length(out)
errs <- sum(sapply(out, function(x) {x}))
print(str_glue("Errors: {errs} of {num.tot}"))

## Get M1 and M2 from first sample
path.samp <- list.files(
  file.path(analysis$scratch_root, analysis$dirs$samps), 
  pattern = 'sub-', full.names = TRUE)[1]
dim.samp <- dim(csv_to_matrix(path.samp))
M1 <- dim.samp[1]
M2 <- dim.samp[2]

## Update config
analysis$outs$num_samps <- num.tot - errs
analysis$outs$M1 <- M1
analysis$outs$M2 <- M2
write_yaml(analysis, file.path('data-analysis', 'analyses', str_glue('{args$analysis.id}.yml')))
