## scriptUtils.R
##       $Revision: 1.13 $ $Date: 2024/12/27 08:27:27 $

## slick way to use precomputed data
##    If the named file exists, it is loaded, giving access to the data.
##    Otherwise, 'expr' is evaluated, and all objects created
##    are saved in the designated file, for loading next time.

reload.or.compute <- function(filename, expr, 
                              objects=NULL,
                              context=parent.frame(),
                              destination=parent.frame(),
                              force=FALSE, verbose=TRUE, exclude=NULL) {
  stopifnot(is.character(filename) && length(filename) == 1)
  if(force || !file.exists(filename)) {
    if(verbose) splat("Recomputing...")
    ## evaluate 'expr' in a fresh environment
    .Expr <- ee <- as.expression(substitute(expr))
    en <- new.env(parent=context)
    assign(".Expr", ee, pos=en)
    local(eval(.Expr), envir=en)
    ## default is to save all objects that were created
    if(is.null(objects))
      objects <- ls(envir=en)
    ## exclude specified objects?
    objects <- setdiff(objects, exclude)
    ## save them in the designated file
    save(list=objects, file=filename, compress=TRUE, envir=en)
    ## assign them into the parent frame 
    for(i in seq_along(objects))
      assign(objects[i], get(objects[i], envir=en), envir=destination)
    result <- objects
  } else {
    if(verbose)
      splat("Reloading from", sQuote(filename),
            "saved at", file.mtime(filename))
    result <- load(filename, envir=destination)
    ## expect to find all objects listed in 'objects' and not excluded
    objects <- setdiff(objects, exclude)
    if(!all(ok <- (objects %in% result))) {
      nbad <- sum(!ok)
      warning(paste(ngettext(nbad, "object", "objects"),
                    commasep(sQuote(objects[!ok])),
                    ngettext(nbad, "was", "were"),
                    "not present in data file", dQuote(filename)),
              call.=FALSE)
    }
  }
  return(invisible(result))
}
