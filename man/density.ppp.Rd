\name{density.ppp}
\alias{density.ppp}
\title{Kernel Smoothed Intensity of Point Pattern}
\description{
  Compute a kernel smoothed intensity function from a point pattern.
}
\usage{
  \method{density}{ppp}(x, sigma=NULL, \dots,
        weights=NULL, edge=TRUE, varcov=NULL,
        at="pixels", leaveoneout=TRUE,
        adjust=1, diggle=FALSE,
        se=FALSE, wtype=c("value", "multiplicity"),
        kernel="gaussian",
        scalekernel=is.character(kernel), 
        positive=FALSE, verbose=TRUE, sameas) 
}
\arguments{
  \item{x}{
    Point pattern (object of class \code{"ppp"}).
  }
  \item{sigma}{
    The smoothing bandwidth (the amount of smoothing).
    The standard deviation of the isotropic smoothing kernel.
    Either a numerical value, 
    or a function that computes an appropriate value of \code{sigma}.
  }
  \item{weights}{
    Optional weights to be attached to the points.
    A numeric vector, numeric matrix, an \code{expression},
    or a pixel image.
  }
  \item{\dots}{
    Additional arguments passed to \code{\link[spatstat.geom]{pixellate.ppp}}
    and \code{\link[spatstat.geom]{as.mask}} to determine
    the pixel resolution, or passed to \code{sigma} if it is a function.
  }
  \item{edge}{
    Logical value indicating whether to apply edge correction.
  }
  \item{varcov}{
    Variance-covariance matrix of anisotropic smoothing kernel.
    Incompatible with \code{sigma}.
  }
  \item{at}{
    String specifying whether to compute the intensity values
    at a grid of pixel locations (\code{at="pixels"}) or
    only at the points of \code{x} (\code{at="points"}).
  }
  \item{leaveoneout}{
    Logical value indicating whether to compute a leave-one-out
    estimator. Applicable only when \code{at="points"}.
  }
  \item{adjust}{
    Optional. Adjustment factor for the smoothing parameter.
  }
  \item{diggle}{
    Logical. If \code{TRUE}, use the Jones-Diggle improved edge correction,
    which is more accurate but slower to compute than the default
    correction.
  }
  \item{kernel}{
    The smoothing kernel.
    A character string specifying the smoothing kernel
    (current options are \code{"gaussian"}, \code{"epanechnikov"},
    \code{"quartic"} or \code{"disc"}),
    or a pixel image (object of class \code{"im"})
    containing values of the kernel, or a \code{function(x,y)} which
    yields values of the kernel.
  }
  \item{scalekernel}{
    Logical value.
    If \code{scalekernel=TRUE}, then the kernel will be rescaled
    to the bandwidth determined by \code{sigma} and \code{varcov}:
    this is the default behaviour when \code{kernel} is a character string.
    If \code{scalekernel=FALSE}, then \code{sigma} and \code{varcov}
    will be ignored: this is the default behaviour when \code{kernel} is a
    function or a pixel image.
  }
  \item{se}{
    Logical value indicating whether to compute standard errors as well.
  }
  \item{wtype}{
    Character string (partially matched) specifying how the weights
    should be interpreted for the calculation of standard error.
    See Details.
  }
  \item{positive}{
    Logical value indicating whether to force all density values to
    be positive numbers. Default is \code{FALSE}.
  }
  \item{verbose}{
    Logical value indicating whether to issue warnings
    about numerical problems and conditions.
  }
  \item{sameas}{
    Optional. The result of a previous evaluation of \code{density.ppp}.
    Smoothing will be performed using the same kernel and bandwidth that
    were used to produce \code{sameas}. Namely the values of the
    arguments \code{kernel}, \code{sigma}, \code{varcov},
    \code{scalekernel} and \code{adjust} will be overwritten by the
    values that were used to produce \code{sameas}.
  }
}
\value{
  By default, the result is
  a pixel image (object of class \code{"im"}). 
  Pixel values are estimated intensity values,
  expressed in \dQuote{points per unit area}.

  If \code{at="points"}, the result is a numeric vector
  of length equal to the number of points in \code{x}.
  Values are estimated intensity values at the points of \code{x}.

  In either case, the return value has attributes
  \code{"sigma"} and \code{"varcov"} which report the smoothing
  bandwidth that was used.

  If \code{weights} is a matrix with more than one column, then the
  result is a list of images (if \code{at="pixels"}) or a matrix of
  numerical values (if \code{at="points"}).
  
  If \code{se=TRUE}, the result is a list with two elements named
  \code{estimate} and \code{SE}, each of the format described above.
}
\details{
  This is a method for the generic function \code{density}.

  It computes a fixed-bandwidth kernel estimate 
  (Diggle, 1985) of the intensity function of the point process
  that generated the point pattern \code{x}.

  The amount of smoothing is controlled by \code{sigma}
  if it is specified.

  By default, smoothing is performed using a Gaussian kernel.  
  The resulting density estimate is the convolution of the
  isotropic Gaussian kernel, of standard deviation \code{sigma},
  with point masses at each of the data points in \code{x}.

  Anisotropic kernels, and non-Gaussian kernels, are also supported.
  Each point has unit weight, unless the argument \code{weights} is
  given.

  If \code{edge=TRUE} (the default), the intensity estimate is corrected
  for edge effect bias.

  If \code{at="pixels"} (the default), the result is a pixel image
  giving the estimated intensity at each pixel in a grid.
  If \code{at="points"}, the result is a numeric vector giving the
  estimated intensity at each of the original data points in \code{x}.
}
\section{Amount of smoothing}{
  The amount of smoothing is determined by the arguments
  \code{sigma}, \code{varcov} and \code{adjust}.
  \itemize{
    \item if \code{sigma} is a single numerical value,
    this is taken as the standard deviation of the isotropic Gaussian
    kernel.
    \item alternatively \code{sigma} may be a function that computes
    an appropriate bandwidth 
    from the data point pattern by calling \code{sigma(x)}.
    To perform automatic bandwidth selection using cross-validation,
    it is recommended to use the functions
    \code{\link{bw.diggle}},
    \code{\link{bw.CvL}},
    \code{\link{bw.scott}}
    or
    \code{\link{bw.ppl}}.
    \item
    The smoothing kernel may be made anisotropic
    by giving the variance-covariance matrix \code{varcov}.
    The arguments \code{sigma} and \code{varcov} are incompatible.
    \item
    Alternatively \code{sigma} may be a vector of length 2 giving the
    standard deviations of the \eqn{x} and \eqn{y} coordinates,
    thus equivalent to \code{varcov = diag(rep(sigma^2, 2))}.
    \item if neither \code{sigma} nor \code{varcov} is specified,
    an isotropic Gaussian kernel will be used, 
    with a default value of \code{sigma}
    calculated by a simple rule of thumb
    that depends only on the size of the window.
    \item
    The argument \code{adjust} makes it easy for the user to change the
    bandwidth specified by any of the rules above.
    The value of \code{sigma} will be multiplied by
    the factor \code{adjust}. The matrix \code{varcov} will be
    multiplied by \code{adjust^2}. To double the smoothing bandwidth, set
    \code{adjust=2}.
    \item
    An infinite bandwidth, \code{sigma=Inf} or \code{adjust=Inf},
    is permitted, and yields an intensity estimate which is constant
    over the spatial domain.
  }
}
\section{Edge correction}{
  If \code{edge=TRUE}, the intensity estimate is corrected for
  edge effect bias in one of two ways:
  \itemize{
    \item If \code{diggle=FALSE} (the default) the intensity estimate is
    correted by dividing it by the convolution of the
    Gaussian kernel with the window of observation.
    This is the approach originally described in Diggle (1985).
    Thus the intensity value at a point \eqn{u} is
    \deqn{
      \hat\lambda(u) = e(u) \sum_i k(x_i - u) w_i
    }{
      \lambda(u) = e(u) \sum[i] k(x[i] - u) w[i]
    }
    where \eqn{k} is the Gaussian smoothing kernel,
    \eqn{e(u)} is an edge correction factor, 
    and \eqn{w_i}{w[i]} are the weights.
    \item
    If \code{diggle=TRUE} then the code uses the improved edge correction
    described by Jones (1993) and Diggle (2010, equation 18.9).
    This has been shown to have better performance (Jones, 1993)
    but is slightly slower to compute. 
    The intensity value at a point \eqn{u} is 
    \deqn{
      \hat\lambda(u) = \sum_i k(x_i - u) w_i e(x_i)
    }{
      \lambda(u) = \sum[i] k(x[i] - u) w[i] e(x[i])
    }
    where again \eqn{k} is the Gaussian smoothing kernel,
    \eqn{e(x_i)}{e(x[i])} is an edge correction factor, 
    and \eqn{w_i}{w[i]} are the weights.
  }
  In both cases, the edge correction term \eqn{e(u)} is the reciprocal of the
  kernel mass inside the window:
  \deqn{
    \frac{1}{e(u)} = \int_W k(v-u) \, {\rm d}v
  }{
    1/e(u) = integral[v in W] k(v-u) dv
  }
  where \eqn{W} is the observation window.
}
\section{Smoothing kernel}{
  By default, smoothing is performed using a Gaussian kernel.
  
  The choice of smoothing kernel is determined by the argument \code{kernel}.
  This should be a character string giving the name of a recognised
  two-dimensional kernel
  (current options are \code{"gaussian"}, \code{"epanechnikov"},
  \code{"quartic"} or \code{"disc"}),
  or a pixel image (object of class \code{"im"})
  containing values of the kernel, or a \code{function(x,y)} which
  yields values of the kernel. The default is a Gaussian kernel.
  
  If \code{scalekernel=TRUE} then the kernel values will be rescaled
  according to the arguments \code{sigma}, \code{varcov} and
  \code{adjust} as explained above, effectively treating
  \code{kernel} as the template kernel with standard deviation equal to 1.
  This is the default behaviour when \code{kernel} is a character string.
  If \code{scalekernel=FALSE}, the kernel values will not be altered,
  and the arguments \code{sigma}, \code{varcov} and \code{adjust}
  are ignored. This is the default behaviour when \code{kernel} is a
  pixel image or a function.
}
\section{Desired output}{
  If \code{at="pixels"} (the default), intensity values are
  computed at every location \eqn{u} in a fine grid,
  and are returned as a pixel image. The point pattern is first discretised 
  using \code{\link[spatstat.geom]{pixellate.ppp}}, then the intensity is
  computed using the Fast Fourier Transform.
  Accuracy depends on the pixel resolution and the discretisation rule.
  The pixel resolution is controlled by the arguments
  \code{\dots} passed to \code{\link[spatstat.geom]{as.mask}} (specify the number of
  pixels by \code{dimyx} or the pixel size by \code{eps}). 
  The discretisation rule is controlled by the arguments
  \code{\dots} passed to \code{\link[spatstat.geom]{pixellate.ppp}}
  (the default rule is that each point is allocated to the nearest
  pixel centre; this can be modified using the arguments
  \code{fractional} and \code{preserve}).

  If \code{at="points"}, the intensity values are computed 
  to high accuracy at the points of \code{x} only. Computation is
  performed by directly evaluating and summing the kernel
  contributions without discretising the data. The result is a numeric
  vector giving the density values.
  The intensity value at a point \eqn{x_i}{x[i]} is (if \code{diggle=FALSE})
  \deqn{
    \hat\lambda(x_i) = e(x_i) \sum_j k(x_j - x_i) w_j
  }{
    \lambda(x[i]) = e(x[i]) \sum[j] k(x[j] - x[i]) w[j]
  }
  or (if \code{diggle=TRUE})
  \deqn{
    \hat\lambda(x_i) = \sum_j k(x_j - x_i) w_j e(x_j)
  }{
    \lambda(x[i]) = \sum[j] k(x[j] - x[i]) w[j] e(x[j])
  }
  If \code{leaveoneout=TRUE} (the default), then the sum in the equation
  is taken over all \eqn{j} not equal to \eqn{i},
  so that the intensity value at a
  data point is the sum of kernel contributions from
  all \emph{other} data points.
  If \code{leaveoneout=FALSE} then the sum is taken over all \eqn{j},
  so that the intensity value at a data point includes a contribution
  from the same point.
}
\section{Weights}{
  If \code{weights} is a matrix with more than one column, then the
  calculation is effectively repeated for each column of weights. The
  result is a list of images (if \code{at="pixels"}) or a matrix of
  numerical values (if \code{at="points"}).
  
  The argument \code{weights} can also be an \code{expression}.
  It will be evaluated in the data frame \code{as.data.frame(x)}
  to obtain a vector or matrix of weights. The expression may involve
  the symbols \code{x} and \code{y} representing the Cartesian
  coordinates, the symbol \code{marks} representing the mark values
  if there is only one column of marks, and the names of the columns of
  marks if there are several columns.  

  The argument \code{weights} can also be a pixel image
  (object of class \code{"im"}). numerical weights for the data points
  will be extracted from this image (by looking up the pixel values
  at the locations of the data points in \code{x}).
}
\section{Standard error}{
  If \code{se=TRUE}, the standard error of the estimate will also be
  calculated. The calculation assumes a Poisson point process. 

  If \code{weights} are given, then the calculation of standard error
  depends on the interpretation of the weights. This is controlled by
  the argument \code{wtype}.
  \itemize{
    \item
    If \code{wtype="value"} (the default),
    the weights are interpreted as numerical values observed
    at the data locations. Roughly speaking,
    standard errors are proportional to the absolute
    values of the weights.
    \item
    If \code{wtype="multiplicity"} the weights are interpreted as
    multiplicities so that a weight of 2 is equivalent to having a pair
    of duplicated points at the data location. Roughly speaking,
    standard errors are proportional
    to the square roots of the weights. Negative weights are not
    permitted.
  }
  The default rule is now \code{wtype="value"} but previous versions
  of \code{density.ppp} (in \pkg{spatstat.explore} versions
  \code{3.1-0} and earlier) effectively used \code{wtype="multiplicity"}.
}
\section{The meaning of \code{density.ppp}}{
  This function is often misunderstood.

  The result of \code{density.ppp} is not a spatial smoothing 
  of the marks or weights attached to the point pattern.
  To perform spatial interpolation of values that were observed
  at the points of a point pattern, use \code{\link{Smooth.ppp}}.

  The result of \code{density.ppp} is not a probability density.
  It is an estimate of the \emph{intensity function} of the
  point process that generated the point pattern data.
  Intensity is the expected number of random points
  per unit area.
  The units of intensity are \dQuote{points per unit area}.
  Intensity is usually a function of spatial location,
  and it is this function which is estimated by \code{density.ppp}.
  The integral of the intensity function over a spatial region gives the
  expected number of points falling in this region.

  Inspecting an estimate of the intensity function is usually the
  first step in exploring a spatial point pattern dataset.
  For more explanation, see Baddeley, Rubak and Turner (2015)
  or Diggle (2003, 2010).

  If you have two (or more) types of points, and you want a
  probability map or relative risk surface (the spatially-varying
  probability of a given type), use \code{\link{relrisk}}.
}
\section{Technical issue: Negative Values}{
  Negative and zero values of the density estimate are possible
  when \code{at="pixels"} because of numerical errors in finite-precision
  arithmetic.

  By default, \code{density.ppp} does not try to repair such errors.
  This would take more computation time and is not always needed.
  (Also it would not be appropriate if \code{weights} include negative values.)

  To ensure that the resulting density values are always positive,
  set \code{positive=TRUE}.
}
\seealso{
  To select the bandwidth \code{sigma} automatically by
  cross-validation, use
  \code{\link{bw.diggle}},
  \code{\link{bw.CvL}},
  \code{\link{bw.scott}}
  or
  \code{\link{bw.ppl}}.
  
  To perform spatial interpolation of values that were observed
  at the points of a point pattern, use \code{\link{Smooth.ppp}}.

  For adaptive nonparametric estimation, see
  \code{\link{adaptive.density}}.
  For data sharpening, see \code{\link{sharpen.ppp}}.

  To compute a relative risk surface or probability map for
  two (or more) types of points, use \code{\link{relrisk}}.

  For information about the data structures, see
  \code{\link[spatstat.geom]{ppp.object}},
  \code{\link[spatstat.geom]{im.object}}.
}
\examples{
  if(interactive()) {
    opa <- par(mfrow=c(1,2))
    plot(density(cells, 0.05))
    plot(density(cells, 0.05, diggle=TRUE))
    par(opa)
    v <- diag(c(0.05, 0.07)^2)
    plot(density(cells, varcov=v))
  }
  # automatic bandwidth selection
  plot(density(cells, sigma=bw.diggle(cells)))
  # equivalent:
  plot(density(cells, bw.diggle))
  # evaluate intensity at points
  density(cells, 0.05, at="points")

  # non-Gaussian kernel
  plot(density(cells, sigma=0.4, kernel="epanechnikov"))

  if(interactive()) {
    # see effect of changing pixel resolution
    opa <- par(mfrow=c(1,2))
    plot(density(cells, sigma=0.4))
    plot(density(cells, sigma=0.4, eps=0.05))
    par(opa)
  }

  # relative risk calculation by hand (see relrisk.ppp)
  lung <- split(chorley)$lung
  larynx <- split(chorley)$larynx
  D <- density(lung, sigma=2)
  plot(density(larynx, sigma=2, weights=1/D))
}
\references{
  \baddrubaturnbook
  
  Bithell, J.F. (1990)
  An application of density estimation to geographical epidemiology.
  \emph{Statistics in Medicine} \bold{9}, 691--701.
  
  Diggle, P.J. (1985)
  A kernel method for smoothing point process data.
  \emph{Applied Statistics} (Journal of the Royal Statistical Society,
  Series C) \bold{34} (1985) 138--147.

  Diggle, P.J. (2003)
  \emph{Statistical analysis of spatial point patterns},
  Second edition. Arnold.

  Diggle, P.J. (2010)
  Nonparametric methods.
  Chapter 18, pp. 299--316 in
  A.E. Gelfand, P.J. Diggle, M. Fuentes and P. Guttorp (eds.)
  \emph{Handbook of Spatial Statistics},
  CRC Press, Boca Raton, FL.

  Jones, M.C. (1993)
  Simple boundary corrections for kernel density estimation.
  \emph{Statistics and Computing} \bold{3}, 135--146.
}

\author{
  \spatstatAuthors
}
\keyword{spatial}
\keyword{methods}
\keyword{smooth}
