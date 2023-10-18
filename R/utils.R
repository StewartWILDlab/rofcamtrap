
#'@export
summarise_folder <- function(){
  return(NULL)
}


folder <- "/media/vlucet/TrailCamST/TrailCamStorage"

folders <- list.dirs(folder, recursive = FALSE)

list_fun <- function(the_dir){
  list.files(the_dir, pattern="JPG$", recursive = TRUE)
}

file_list <- lapply(X = folders, FUN = list_fun)


# -------------------------------------------------------------------------

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

countinst(folder, ".JPG")
