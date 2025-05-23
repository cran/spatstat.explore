\name{ISE.envelope}
\alias{ISE.envelope}
\title{Integrated Squared Error on an Envelope Object}
\description{
  Compute integrated squared error of each of the simulated
  function estimates in an envelope object.
}
\usage{
ISE.envelope(object, theo, domain, dimension=2)
}
\arguments{
  \item{object}{
    Object of class \code{"envelope"}
    generated by the function \code{\link[spatstat.explore]{envelope}}
  }
  \item{theo}{
    Function in the \R language that evaluates the
    true (theoretically expected) value of the
    spatial summary function. 
  }
  \item{domain}{
    Numeric vector of length 2 specifying the limits of the
    domain of integration for the integrated squared error.
  }
  \item{dimension}{
    Integer (either 1 or 2) specifying whether to calculate the
    one-dimensional or two-dimensional integral of squared error.
  }
}
\details{
  The first argument should be an object of class \code{"envelope"} 
  and should contain the simulated function estimates (i.e. it should
  have been computed using \code{\link[spatstat.explore]{envelope}}
  with \code{savefuns=TRUE}).

  The simulated function estimates are extracted from \code{object},
  and their squared error from the true value \code{theo}
  is computed pointwise. The squared errors are integrated over the
  interval specified by \code{domain}, giving one value of integrated
  squared error for each simulated function estimate. These values
  are returned as a numerical vector.
}
\value{
  A numeric vector of length equal to the number of simulated functions.
}
\examples{
  E <- envelope(cells, Kest, correction="translate", nsim=20, savefuns=TRUE)
  theoK <- function(r) { pi * r^2 }
  dom <- c(0, 0.1)
  ISE.envelope(E, theoK, dom)
}
\seealso{
  \code{\link{bias.envelope}},
  \code{\link{MISE.envelope}}.
}
\author{\adrian, \martinH and \tilman.}
\keyword{spatial}
\keyword{iteration}
