
#' @export
read_md_json <- function(md_json_file){
  stopifnot(file.exists(md_json_file))
  jsonlite::read_json(md_json_file, simplifyVector=F)
}
