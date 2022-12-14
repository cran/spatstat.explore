#
#  smoothfv.R
#
#   $Revision: 1.16 $   $Date: 2022/01/04 05:30:06 $
#
  
# smooth.fv <- function(x, which="*", ..., 
#                      method=c("smooth.spline", "loess"),
#                      xinterval=NULL) {
#  .Deprecated("Smooth.fv", package="spatstat",
#     msg="smooth.fv is deprecated: use the generic Smooth with a capital S")
#  Smooth(x, which=which, ..., method=method, xinterval=xinterval)
# }
  
Smooth.fv <- function(X, which="*", ..., 
                      method=c("smooth.spline", "loess"),
                      xinterval=NULL) {
  x <- X
  stopifnot(is.character(which))
  method <- match.arg(method)
  if(!is.null(xinterval))
    check.range(xinterval)
  if(length(which) == 1 && which %in% .Spatstat.FvAbbrev) {
    if(which == ".x")
      stop("Cannot smooth the function argument")
    which <- fvnames(x, which)
  }
  if(any(nbg <- !(which %in% names(x)))) 
    stop(paste("Unrecognised column",
               ngettext(sum(nbg), "name", "names"),
               commasep(sQuote(which[nbg])), 
               "in argument", sQuote("which")))
  xx <- x[[fvnames(x, ".x")]]
  # process each column of function values
  for(ynam in which) {
    yy <- x[[ynam]]
    ok <- is.finite(yy)
    if(!is.null(xinterval))
      ok <- ok & inside.range(xx, xinterval)
    switch(method,
           smooth.spline = {
             ss <- smooth.spline(xx[ok], yy[ok], ...)
             yhat <- predict(ss, xx[ok])$y
           },
           loess = {
             df <- data.frame(x=xx[ok], y=yy[ok])
             lo <- loess(y ~ x, df, ...)
             yhat <- predict(lo, df[,"x", drop=FALSE])
           })
    yy[ok] <- yhat
    x[[ynam]] <- yy
  }
  return(x)
}
