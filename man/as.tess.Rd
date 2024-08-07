\name{as.tess}
\alias{as.tess.quadrattest}
\title{Convert Data To Tessellation}
\description{
Converts data specifying a tessellation,
in any of several formats, into an object of class \code{"tess"}.
}
\usage{
 \method{as.tess}{quadrattest}(X)
}
\arguments{
  \item{X}{Data to be converted to a tessellation.}
}
\value{
  An object of class \code{"tess"} specifying a tessellation.
}
\details{
  A tessellation is a collection of disjoint spatial regions
  (called \emph{tiles}) that fit together to form a larger spatial
  region. This command creates an object of class \code{"tess"} that
  represents a tessellation. 

  This function converts data in any of several formats 
  into an object of class \code{"tess"} for use by the \pkg{spatstat}
  package.  The argument \code{X} may be
  \itemize{
    \item
    an object of class \code{"tess"}.
    The object will be stripped of any extraneous attributes
    and returned.
    \item
    a pixel image (object of class \code{"im"}) with pixel values that
    are logical or factor values. Each level of the factor will
    determine a tile of the tessellation.
    \item
    a window (object of class \code{"owin"}). The result will be a
    tessellation consisting of a single tile.
    \item
    a set of quadrat counts (object of class \code{"quadratcount"})
    returned by the command \code{\link[spatstat.geom]{quadratcount}}.
    The quadrats
    used to generate the counts will be extracted and returned as a
    tessellation.
    \item
    a quadrat test (object of class \code{"quadrattest"})
    returned by the command \code{\link[spatstat.explore]{quadrat.test}}. 
    The quadrats
    used to perform the test will be extracted and returned as a
    tessellation.
    \item
    a list of windows (objects of class \code{"owin"})
    giving the tiles of the tessellation.
  }
  The function \code{as.tess} is generic, with methods for
  various classes, as listed above.
}
\seealso{
  \code{\link[spatstat.geom]{tess}}

}
\examples{

 h <- quadrat.test(nztrees, nx=4, ny=3)
 as.tess(h)
}
\author{
  \adrian
  and \rolf
}
\keyword{spatial}
\keyword{manip}
 
 
\concept{Tessellation}
