\name{localpcf}
\alias{localpcf}
\alias{localpcfinhom}
\title{Local pair correlation function}
\description{
  Computes individual contributions to the
  pair correlation function from each data point.
}
\usage{
  localpcf(X, ..., delta=NULL, rmax=NULL, nr=512, stoyan=0.15, rvalue=NULL)

  localpcfinhom(X, ..., delta=NULL, rmax=NULL, nr=512, stoyan=0.15,
         lambda=NULL, sigma=NULL, varcov=NULL,
         update=TRUE, leaveoneout=TRUE, rvalue=NULL)
}
\arguments{
  \item{X}{A point pattern (object of class \code{"ppp"}).}
  \item{delta}{
    Smoothing bandwidth for pair correlation.
    The halfwidth of the Epanechnikov kernel.
  }
  \item{rmax}{
    Optional. Maximum value of distance \eqn{r} for which
    pair correlation values \eqn{g(r)} should be computed.
  }
  \item{nr}{
    Optional. Number of values of distance \eqn{r} for which
    pair correlation \eqn{g(r)} should be computed.
  }
  \item{stoyan}{
    Optional. The value of the constant \eqn{c} in Stoyan's rule
    of thumb for selecting the smoothing bandwidth \code{delta}.
  }
  \item{lambda}{
    Optional.
    Values of the estimated intensity function, for the
    inhomogeneous pair correlation.
    Either a vector giving the intensity values
    at the points of the pattern \code{X},
    a pixel image (object of class \code{"im"}) giving the
    intensity values at all locations, a fitted point process model
    (object of class \code{"ppm"}, \code{"kppm"} or \code{"dppm"})
    or a \code{function(x,y)} which
    can be evaluated to give the intensity value at any location.
  }
  \item{sigma,varcov,\dots}{
    These arguments are ignored by \code{localpcf}
    but are passed by \code{localpcfinhom} (when \code{lambda=NULL})
    to the function \code{\link{density.ppp}}
    to control the kernel smoothing estimation of \code{lambda}.
  }
  \item{leaveoneout}{
    Logical value (passed to \code{\link{density.ppp}} or
    \code{\link[spatstat.model]{fitted.ppm}}) specifying whether to use a
    leave-one-out rule when calculating the intensity.
  }
  \item{update}{
    Logical value indicating what to do when \code{lambda} is a fitted model
    (class \code{"ppm"}, \code{"kppm"} or \code{"dppm"}).
    If \code{update=TRUE} (the default),
    the model will first be refitted to the data \code{X}
    (using \code{\link[spatstat.model]{update.ppm}} or \code{\link[spatstat.model]{update.kppm}})
    before the fitted intensity is computed.
    If \code{update=FALSE}, the fitted intensity of the
    model will be computed without re-fitting it to \code{X}.
  }
  \item{rvalue}{Optional. A \emph{single} value of the distance argument
    \eqn{r} at which the local pair correlation should be computed.
  }
}
\details{
  \code{localpcf} computes the contribution, from each individual
  data point in a point pattern \code{X}, to the
  empirical pair correlation function of \code{X}.
  These contributions are sometimes known as LISA (local indicator
  of spatial association) functions based on pair correlation.
  
  \code{localpcfinhom} computes the corresponding contribution
  to the \emph{inhomogeneous} empirical pair correlation function of \code{X}.
  
  Given a spatial point pattern \code{X}, the local pcf
  \eqn{g_i(r)}{g[i](r)} associated with the \eqn{i}th point
  in \code{X} is computed by
  \deqn{
    g_i(r) = \frac a {2 \pi n} \sum_j k(d_{i,j} - r) 
  }{
    g[i](r) = (a/(2 * pi * n) * sum[j] k(d[i,j] - r) 
  }
  where the sum is over all points \eqn{j \neq i}{j != i},
  \eqn{a} is the area of the observation window, \eqn{n} is the number
  of points in \code{X}, and \eqn{d_{ij}}{d[i,j]} is the distance
  between points \code{i} and \code{j}. Here \code{k} is the
  Epanechnikov kernel,
  \deqn{
    k(t) = \frac 3 { 4\delta} \max(0, 1 - \frac{t^2}{\delta^2}).
  }{
    k(t) = (3/(4*delta)) * max(0, 1 - t^2/delta^2).
  }
  Edge correction is performed using the border method
  (for the sake of computational efficiency):
  the estimate \eqn{g_i(r)}{g[i](r)} is set to \code{NA} if
  \eqn{r > b_i}{r > b[i]}, where \eqn{b_i}{b[i]}
  is the distance from point \eqn{i} to the boundary of the
  observation window.

  The smoothing bandwidth \eqn{\delta}{delta} may be specified.
  If not, it is chosen by Stoyan's rule of thumb
  \eqn{\delta = c/\hat\lambda}{delta = c/lambda}
  where \eqn{\hat\lambda = n/a}{lambda = n/a} is the estimated intensity
  and \eqn{c} is a constant, usually taken to be 0.15.
  The value of \eqn{c} is controlled by the argument \code{stoyan}.

  For \code{localpcfinhom}, the optional argument \code{lambda}
  specifies the values of the estimated intensity function.
  If \code{lambda} is given, it should be either a
  numeric vector giving the intensity values
  at the points of the pattern \code{X},
  a pixel image (object of class \code{"im"}) giving the
  intensity values at all locations, a fitted point process model
  (object of class \code{"ppm"}, \code{"kppm"} or \code{"dppm"})
  or a \code{function(x,y)} which
  can be evaluated to give the intensity value at any location.
  If \code{lambda} is not given, then it will be estimated
  using a leave-one-out kernel density smoother as described
  in \code{\link{pcfinhom}}.

  Alternatively, if the argument \code{rvalue} is given, and it is a
  single number, then the function will only be computed for this value
  of \eqn{r}, and the results will be returned as a numeric vector,
  with one entry of the vector for each point of the pattern \code{X}.
}
\value{
  An object of class \code{"fv"}, see \code{\link{fv.object}},
  which can be plotted directly using \code{\link{plot.fv}}.
  Essentially a data frame containing columns
  \item{r}{the vector of values of the argument \eqn{r} 
    at which the function \eqn{K} has been  estimated
  }
  \item{theo}{the theoretical value \eqn{K(r) = \pi r^2}{K(r) = pi * r^2}
    or \eqn{L(r)=r} for a stationary Poisson process
  }
  together with columns containing the values of the
  local pair correlation function for each point in the pattern.
  Column \code{i} corresponds to the \code{i}th point.
  The last two columns contain the \code{r} and \code{theo} values.
}
\seealso{
  \code{\link{localK}},
  \code{\link{localKinhom}},
  \code{\link{pcf}},
  \code{\link{pcfinhom}}
}
\examples{
  X <- ponderosa

  g <- localpcf(X, stoyan=0.5)
  colo <- c(rep("grey", npoints(X)), "blue")
  a <- plot(g, main=c("local pair correlation functions", "Ponderosa pines"),
          legend=FALSE, col=colo, lty=1)

  # plot only the local pair correlation function for point number 7
  plot(g, est007 ~ r)

  # Extract the local pair correlation at distance 15 metres, for each point
  g15 <- localpcf(X, rvalue=15, stoyan=0.5)
  g15[1:10]
  # Check that the value for point 7 agrees with the curve for point 7:
  points(15, g15[7], col="red") 

  # Inhomogeneous 
  gi <- localpcfinhom(X, stoyan=0.5)
  a <- plot(gi, main=c("inhomogeneous local pair correlation functions",
                       "Ponderosa pines"),
                legend=FALSE, col=colo, lty=1)
}
\author{
  \spatstatAuthors.
}
\keyword{spatial}
\keyword{nonparametric}

