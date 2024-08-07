\name{idw}
\alias{idw}
\title{Inverse-distance weighted smoothing of observations at irregular points}
\description{
  Performs spatial smoothing of numeric values observed
  at a set of irregular locations using inverse-distance weighting.
}
\usage{
idw(X, power=2, at=c("pixels", "points"), ..., se=FALSE)
}
\arguments{
  \item{X}{A marked point pattern (object of class \code{"ppp"}).}
  \item{power}{Numeric. Power of distance used in the weighting.}
  \item{at}{
    Character string specifying whether to compute the intensity values
    at a grid of pixel locations (\code{at="pixels"}) or
    only at the points of \code{X} (\code{at="points"}).
    String is partially matched.
  }
  \item{\dots}{Arguments passed to \code{\link[spatstat.geom]{as.mask}}
    to control the pixel resolution of the result.}
  \item{se}{
    Logical value specifying whether to calculate a standard error.
  }
}
\details{
  This function performs spatial smoothing of numeric values
  observed at a set of irregular locations.
  
  Smoothing is performed by inverse distance weighting. If the
  observed values are \eqn{v_1,\ldots,v_n}{v[1],...,v[n]}
  at locations \eqn{x_1,\ldots,x_n}{x[1],...,x[n]} respectively,
  then the smoothed value at a location \eqn{u} is
  \deqn{
    g(u) = \frac{\sum_i w_i v_i}{\sum_i w_i}
  }{
    g(u) = (sum of w[i] * v[i])/(sum of w[i])
  }
  where the weights are the inverse \eqn{p}-th powers of distance,
  \deqn{
    w_i = \frac 1 {d(u,x_i)^p}
  }{
    w[i] = 1/d(u,x[i])^p
  }
  where \eqn{d(u,x_i) = ||u - x_i||}{d(u,x[i])}
  is the Euclidean distance from \eqn{u} to \eqn{x_i}{x[i]}.
  
  The argument \code{X} must be a marked point pattern (object
  of class \code{"ppp"}, see \code{\link[spatstat.geom]{ppp.object}}).
  The points of the pattern are taken to be the
  observation locations \eqn{x_i}{x[i]}, and the marks of the pattern
  are taken to be the numeric values \eqn{v_i}{v[i]} observed at these
  locations.

  The marks are allowed to be a data frame.
  Then the smoothing procedure is applied to each
  column of marks. 
  
  If \code{at="pixels"} (the default), the smoothed mark value
  is calculated at a grid of pixels, and the result is a pixel image.
  The arguments \code{\dots} control the pixel resolution.
  See \code{\link[spatstat.geom]{as.mask}}.

  If \code{at="points"}, the smoothed mark values are calculated
  at the data points only, using a leave-one-out rule (the mark value
  at a data point is excluded when calculating the smoothed value
  for that point). 

  An estimate of standard error is also calculated, if \code{se=TRUE}.
  The calculation assumes that the data point locations are fixed,
  that is, the standard error only takes into account the variability
  in the mark values, and not the variability due to randomness of the
  data point locations.
  
  An alternative to  inverse-distance weighting is kernel smoothing,
  which is performed by \code{\link{Smooth.ppp}}.
}
\value{
  \emph{If \code{X} has a single column of marks:}
  \itemize{
    \item 
    If \code{at="pixels"} (the default), the result is
    a pixel image (object of class \code{"im"}). 
    Pixel values are values of the interpolated function.
    \item
    If \code{at="points"}, the result is a numeric vector
    of length equal to the number of points in \code{X}.
    Entries are values of the interpolated function at the points of \code{X}.
  }
  \emph{If \code{X} has a data frame of marks:}
  \itemize{
    \item 
    If \code{at="pixels"} (the default), the result is a named list of 
    pixel images (object of class \code{"im"}). There is one
    image for each column of marks. This list also belongs to
    the class \code{"solist"}, for which there is a plot method.
    \item
    If \code{at="points"}, the result is a data frame
    with one row for each point of \code{X},
    and one column for each column of marks. 
    Entries are values of the interpolated function at the points of \code{X}.
  }
  If \code{se=TRUE}, then the result is a list
  with two entries named \code{estimate} and \code{SE}, which
  each have the format described above.
}
\seealso{
  \code{\link{density.ppp}},
  \code{\link[spatstat.geom]{ppp.object}},
  \code{\link[spatstat.geom]{im.object}}.

  See \code{\link{Smooth.ppp}} for kernel smoothing,
  \code{\link{SpatialMedian.ppp}} for median smoothing
  and \code{\link[spatstat.geom]{nnmark}} for nearest-neighbour interpolation.
  
  To perform other kinds of interpolation, see also the \code{akima} package.
}
\examples{
   # data frame of marks: trees marked by diameter and height
   plot(idw(finpines))
   idw(finpines, at="points")[1:5,]
   plot(idw(finpines, se=TRUE)$SE)
   idw(finpines, at="points", se=TRUE)$SE[1:5, ]
}
\references{
  Shepard, D. (1968) A two-dimensional interpolation function for
  irregularly-spaced data.
  \emph{Proceedings of the 1968 ACM National Conference},
  1968, pages 517--524. DOI: 10.1145/800186.810616
}
\author{
  \spatstatAuthors.
  Variance calculation by Andrew P Wheeler with modifications by
  Adrian Baddeley.
}
\keyword{spatial}
\keyword{methods}
\keyword{smooth}
