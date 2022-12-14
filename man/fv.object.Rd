\name{fv.object}
\alias{fv.object} %DoNotExport
\title{Function Value Table}
\description{
  A class \code{"fv"} to support the convenient plotting
  of several estimates of the same function.
}
\details{
  An object of this class is a convenient way of storing and plotting
  several different estimates of the same function.

  It is a data frame with extra attributes indicating
  the recommended way of plotting the function, and other information.

  There are methods for \code{print} and \code{plot} for
  this class.
  
  Objects of class \code{"fv"} are returned by
  \code{\link[spatstat.explore]{Fest}}, \code{\link[spatstat.explore]{Gest}},\code{\link[spatstat.explore]{Jest}},
  and \code{\link[spatstat.explore]{Kest}} along with many other functions.
}
\seealso{
  Objects of class \code{"fv"} are returned by
  \code{\link[spatstat.explore]{Fest}}, \code{\link[spatstat.explore]{Gest}},\code{\link[spatstat.explore]{Jest}},
  and \code{\link[spatstat.explore]{Kest}} along with many other functions.
  
  See \code{\link{plot.fv}} for plotting an \code{"fv"} object.

  See \code{\link{as.function.fv}} to convert an \code{"fv"} object
  to an \R function.
  
  Use \code{\link{cbind.fv}} to combine several \code{"fv"} objects.
  Use \code{\link{bind.fv}} to glue additional columns onto an existing
  \code{"fv"} object.

  \emph{Undocumented} functions for modifying an \code{"fv"} object
  include \code{fvnames}, \code{fvnames<-},
  \code{tweak.fv.entry} and \code{rebadge.fv}.
}
\examples{
    K <- Kest(cells)
    class(K)

    K  # prints a sensible summary

    plot(K)
}
\author{\adrian
  
  
  and \rolf
  
}
\keyword{spatial}
\keyword{attribute}
 
 
