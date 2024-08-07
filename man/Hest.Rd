\name{Hest}
\alias{Hest}
\title{Spherical Contact Distribution Function}
\description{
  Estimates the spherical contact distribution function of a
  random set.
}
\usage{
Hest(X, r=NULL, breaks=NULL, ...,
     W,
     correction=c("km", "rs", "han"),
     conditional=TRUE)
}
\arguments{
  \item{X}{The observed random set.
    An object of class \code{"ppp"}, \code{"psp"} or \code{"owin"}.
    Alternatively a pixel image (class \code{"im"}) with logical values.
  }
  \item{r}{
    Optional. Vector of values for the argument \eqn{r} at which \eqn{H(r)} 
    should be evaluated. Users are advised \emph{not} to specify this
    argument; there is a sensible default.
  }
  \item{breaks}{
	This argument is for internal use only.
  }
  \item{\dots}{Arguments passed to \code{\link[spatstat.geom]{as.mask}}
    to control the discretisation.
  }
  \item{W}{
    Optional. A window (object of class \code{"owin"})
    to be taken as the window of observation.
    The contact distribution function will be estimated
    from values of the contact distance inside \code{W}.
    The default is \code{W=Frame(X)} when \code{X} is a window,
    and \code{W=Window(X)} otherwise.
  }
  \item{correction}{
   Optional.
    The edge correction(s) to be used to estimate \eqn{H(r)}.
    A vector of character strings selected from
    \code{"none"}, \code{"rs"}, \code{"km"}, \code{"han"}
    and \code{"best"}.
    Alternatively \code{correction="all"} selects all options.
  }
  \item{conditional}{
    Logical value indicating whether to compute the
    conditional or unconditional distribution. See Details.
  }
}
\details{
  The spherical contact distribution function
  of a stationary random set \eqn{X}
  is the cumulative distribution function \eqn{H} of the distance
  from a fixed point in space to the nearest point of \eqn{X},
  given that the point lies outside \eqn{X}.
  That is, \eqn{H(r)} equals
  the probability that \code{X} lies closer than \eqn{r} units away
  from the fixed point \eqn{x}, given that \code{X} does not cover \eqn{x}.

  Let \eqn{D = d(x,X)} be the shortest distance from an arbitrary
  point \eqn{x} to the set \code{X}. Then the spherical contact
  distribution function is
  \deqn{H(r) = P(D \le r \mid D > 0)}{H(r) = P(D <= r | D > 0)}
  For a point process, the spherical contact distribution function
  is the same as the empty space function \eqn{F} discussed
  in \code{\link{Fest}}. 

  The argument \code{X} may be a point pattern
  (object of class \code{"ppp"}), a line segment pattern
  (object of class \code{"psp"}) or a window (object of class
  \code{"owin"}). It is assumed to be a realisation of a stationary
  random set.

  The algorithm first calls \code{\link[spatstat.geom]{distmap}} to compute the
  distance transform of \code{X}, then computes the Kaplan-Meier
  and reduced-sample estimates of the cumulative distribution
  following Hansen et al (1999).
  If \code{conditional=TRUE} (the default) the algorithm
  returns an estimate of the spherical contact function
  \eqn{H(r)} as defined above. 
  If \code{conditional=FALSE}, it instead returns an estimate of the
  cumulative distribution function
  \eqn{H^\ast(r) = P(D \le r)}{H*(r) = P(D <= r)}
  which includes a jump at \eqn{r=0} if \code{X} has nonzero area.

  Accuracy depends on the pixel resolution, which is controlled by the
  arguments \code{eps}, \code{dimyx} and \code{xy} passed to
  \code{\link[spatstat.geom]{as.mask}}. For example, use \code{eps=0.1} to specify
  square pixels of side 0.1 units, and \code{dimyx=256} to specify a
  256 by 256 grid of pixels.
}
\value{
  An object of class \code{"fv"}, see \code{\link{fv.object}},
  which can be plotted directly using \code{\link{plot.fv}}.

  Essentially a data frame containing up to six columns:
  \item{r}{the values of the argument \eqn{r} 
    at which the function \eqn{H(r)} has been  estimated
  }
  \item{rs}{the ``reduced sample'' or ``border correction''
    estimator of \eqn{H(r)}
  }
  \item{km}{the spatial Kaplan-Meier estimator of \eqn{H(r)}
  }
  \item{hazard}{the hazard rate \eqn{\lambda(r)}{lambda(r)}
    of \eqn{H(r)} by the spatial Kaplan-Meier method
  }
  \item{han}{the spatial Hanisch-Chiu-Stoyan estimator of \eqn{H(r)}
  }
  \item{raw}{the uncorrected estimate of \eqn{H(r)},
  i.e. the empirical distribution of the distance from 
  a fixed point in the window to the nearest point of \code{X}
  }
}
\references{
  Baddeley, A.J. Spatial sampling and censoring.
     In O.E. Barndorff-Nielsen, W.S. Kendall and
     M.N.M. van Lieshout (eds) 
     \emph{Stochastic Geometry: Likelihood and Computation}.
     Chapman and Hall, 1998.
     Chapter 2, pages 37-78.
  
  Baddeley, A.J. and Gill, R.D. 
    The empty space hazard of a spatial pattern.
    Research Report 1994/3, Department of Mathematics,
    University of Western Australia, May 1994.

  Hansen, M.B., Baddeley, A.J. and Gill, R.D.
  First contact distributions for spatial patterns:
  regularity and estimation.
  \emph{Advances in Applied Probability} \bold{31} (1999) 15-33.

  Ripley, B.D. \emph{Statistical inference for spatial processes}.
  Cambridge University Press, 1988.

  Stoyan, D, Kendall, W.S. and Mecke, J.
  \emph{Stochastic geometry and its applications}.
  2nd edition. Springer Verlag, 1995.
}
\seealso{\code{\link{Fest}}}
\examples{
   X <- runifpoint(42)
   H <- Hest(X)
   Y <- rpoisline(10)
   H <- Hest(Y)
   H <- Hest(Y, dimyx=256)
   X <- heather$coarse
   plot(Hest(X))
   H <- Hest(X, conditional=FALSE)

   P <- owin(poly=list(x=c(5.3, 8.5, 8.3, 3.7, 1.3, 3.7),
                       y=c(9.7, 10.0, 13.6, 14.4, 10.7, 7.2)))
   plot(X)
   plot(P, add=TRUE, col="red")
   H <- Hest(X, W=P)
   Z <- as.im(FALSE, Frame(X))
   Z[X] <- TRUE
   Z <- Z[P, drop=FALSE]
   plot(Z)
   H <- Hest(Z)
}
\author{
  \spatstatAuthors
  with contributions from Kassel Hingee.
}
\keyword{spatial}
\keyword{nonparametric}
