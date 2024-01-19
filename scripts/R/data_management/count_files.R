# V. LUCET 2022
# For Sam, to count survey pictures

# Change path
folder <- "/media/vlucet/TrailCamST/TrailCamStorage"

# -------------------------------------------------------------------------

# FUNCTIONS
# Taken from
# https://www.r-bloggers.com/2017/04/a-python-like-walk-function-for-r/

checkname <- function(drname, filelist, arg) {
  if (length(filelist)>0){
    arg$tot <- arg$tot + sum(sapply(filelist, pattern = arg$flname, FUN = grepl))
  }
  arg
}

walk <- function(currdir, f, arg) {

  # "leave trail of bread crumbs"
  savetop <- getwd()
  setwd(currdir)

  print(currdir)

  fls <- list.files()
  arg <- f(currdir, fls, arg)

  # subdirectories of this directory
  dirs <- list.dirs(recursive=FALSE)

  for (d in dirs) arg <- walk(d,f,arg)

  setwd(savetop) # go back to calling directory
  return(arg)
}

countinst <- function(startdir, flname) {
  walk(startdir, checkname,
       list(flname=flname, tot=0))
}

ret <- countinst(folder, ".JPG")
print(ret$tot)
