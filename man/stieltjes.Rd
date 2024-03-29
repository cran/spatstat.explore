\name{stieltjes}
\alias{stieltjes}
\title{Compute Integral of Function Against Cumulative Distribution}
\description{
  Computes the Stieltjes integral 
  of a function \eqn{f} with respect to a function \eqn{M}.
}
\usage{
stieltjes(f, M, ...)
}
\arguments{
  \item{f}{
    The integrand. A function in the \R language.
  }
  \item{M}{
    The cumulative function against which \code{f} will be
    integrated. An object of class \code{"fv"} or \code{"stepfun"}.
  }
  \item{\dots}{
    Additional arguments passed to \code{f}.
  }
}
\details{
  This command computes the Stieltjes integral
  \deqn{I = \int f(x) dM(x)}{I = integral f(x) dM(x)}
  of a real-valued function \eqn{f(x)}
  with respect to a nondecreasing function \eqn{M(x)}.

  One common use of the Stieltjes integral is
  to find the mean value of a random variable from its
  cumulative distribution function \eqn{F(x)}. The mean value is
  the Stieltjes integral of \eqn{f(x)=x} with respect to \eqn{F(x)}.

  The argument \code{f} should be a \code{function} in the \R language.
  It should accept a numeric vector argument \code{x} and should return
  a numeric vector of the same length.

  The argument \code{M} should be either a step function
  (object of class \code{"stepfun"}) or a function value table
  (object of class \code{"fv"} %, see \code{\link{fv.object}}).
  ).
  Objects of class \code{"stepfun"} are returned by
  \code{\link[stats]{ecdf}}, \code{\link{ewcdf}},
  % \code{\link[spatstat.explore]{spatialcdf}}
  and other utilities.
  % Objects of class \code{"fv"} are returned
  % by the commands \code{\link[spatstat.explore]{Kest}}, \code{\link[spatstat.explore]{Gest}}, etc.
}
\value{
  A list containing the value of the Stieltjes integral
  computed using each of the versions of the function \code{M}.
}
%\seealso{
%  \code{\link[spatstat.explore]{fv.object}}.

%  Use \code{\link[spatstat.explore]{integral.fv}} to integrate a function
%  object of class \code{"fv"}.
%}
\examples{
  x <- runif(100)
  w <- runif(100)
  H <- ewcdf(x, w)
  stieltjes(function(x) { x^2 }, H)

%  # estimate cdf of nearest neighbour distance in redwood data
%  G <- Gest(redwood)
%  # compute estimate of mean nearest neighbour distance
%  stieltjes(function(x){x}, G)
%  # estimated probability of a distance in the interval [0.1,0.2]
%  stieltjes(function(x,a,b){ (x >= a) & (x <= b)}, G, a=0.1, b=0.2)

%  # stepfun example
%  H <- spatialcdf(bei.extra$elev, normalise=TRUE)
%  stieltjes(function(x){x}, H)
}
\author{
  \spatstatAuthors.
}
\keyword{spatial}
\keyword{math}
