\name{relrisk.ppp}
\alias{relrisk.ppp}
\title{
  Nonparametric Estimate of Spatially-Varying Relative Risk
}
\description{
  Given a multitype point pattern, this function estimates the
  spatially-varying probability of each type of point, or the ratios of
  such probabilities, using kernel smoothing.
  The default smoothing bandwidth is selected by
  cross-validation.
}
\usage{
\method{relrisk}{ppp}(X, sigma = NULL, ...,
           at = c("pixels", "points"),
           weights = NULL, varcov = NULL, 
           relative=FALSE, normalise=FALSE,
           adjust=1, edge=TRUE, diggle=FALSE,
           se=FALSE, wtype=c("value", "multiplicity"),
           casecontrol=TRUE, control=1, case, shrink=0, fudge=0)
}
\arguments{
  \item{X}{
    A multitype point pattern (object of class \code{"ppp"}
    which has factor valued marks).
  }
  \item{sigma}{
    Optional. The numeric value of the smoothing bandwidth
    (the standard deviation of isotropic
    Gaussian smoothing kernel).
    Alternatively \code{sigma} may be a function which can be used
    to select a different bandwidth for each type of point. See Details.
  }
  \item{\dots}{
    Arguments passed to \code{\link{bw.relrisk}} to select the
    bandwidth, or passed to \code{\link{density.ppp}} to control the
    pixel resolution.
  }
  \item{at}{
    Character string specifying whether to compute the probability values
    at a grid of pixel locations (\code{at="pixels"}) or
    only at the points of \code{X} (\code{at="points"}).
  }
  \item{weights}{
    Optional. Weights for the data points of \code{X}.
    A numeric vector, an \code{expression}, or a pixel image.
  }
  \item{varcov}{
    Optional. Variance-covariance matrix of anisotopic Gaussian
    smoothing kernel. Incompatible with \code{sigma}.
  }
  \item{relative}{
    Logical.
    If \code{FALSE} (the default) the algorithm
    computes the probabilities of each type of point.
    If \code{TRUE}, it computes the    
    \emph{relative risk}, the ratio of probabilities
    of each type relative to the probability of a control.
  }
  \item{normalise}{
    Logical value specifying whether the results should be normalised
    so that constant risk corresponds to the value 1.
  }
  \item{adjust}{
    Optional. Adjustment factor for the bandwidth \code{sigma}.
  }
  \item{edge}{
    Logical value indicating whether to apply edge correction.
  }
  \item{diggle}{
    Logical. If \code{TRUE}, use the Jones-Diggle improved edge correction,
    which is more accurate but slower to compute than the default
    correction.
  }
  \item{se}{
    Logical value indicating whether to compute standard errors
    as well.
  }
  \item{wtype}{
    Character string (partially matched) specifying how the weights
    should be interpreted for the calculation of standard error.
    See Details.
  }
  \item{casecontrol}{
    Logical. Whether to treat a bivariate point pattern
    as consisting of cases and controls, and return only the
    probability or relative risk of a case.
    Ignored if there are more than 2 types of points.
    See Details.
  }
  \item{control}{
    Integer, or character string, identifying which mark value
    corresponds to a control. 
  }
  \item{case}{
    Integer, or character string, identifying which mark value
    corresponds to a case (rather than a control)
    in a bivariate point pattern.
    This is an alternative to the argument \code{control}
    in a bivariate point pattern. 
    Ignored if there are more than 2 types of points.
  }
  \item{shrink,fudge}{
    Optional factors for shrinkage estimation as proposed by Bithell (1991).
    Numeric values, or numeric vectors with one entry for each type of
    point. See Details.
  }
}
\details{
  The command \code{\link{relrisk}} is generic and can be used to
  estimate relative risk in different ways.
  
  This function \code{relrisk.ppp} is the method for point pattern
  datasets. It computes \emph{nonparametric} estimates of relative risk
  by kernel smoothing (Bithell, 1990, 1991; Diggle, 2003; Baddeley,
  Rubak and Turner, 2015). 

  If \code{X}  is a bivariate point pattern
  (a multitype point pattern consisting of two types of points)
  then by default,
  the points of the first type (the first level of \code{marks(X)})
  are treated as controls or non-events, and points of the second type
  are treated as cases or events. Then by default this command computes
  the spatially-varying \emph{probability} of a case,
  i.e. the probability \eqn{p(u)}
  that a point at spatial location \eqn{u}
  will be a case. If \code{relative=TRUE}, it computes the
  spatially-varying \emph{relative risk} of a case relative to a
  control, \eqn{r(u) = p(u)/(1- p(u))}.

  If \code{X} is a multitype point pattern with \eqn{m > 2} types,
  or if \code{X} is a bivariate point pattern
  and \code{casecontrol=FALSE},
  then by default this command computes, for each type \eqn{j},
  a nonparametric estimate of
  the spatially-varying \emph{probability} of an event of type \eqn{j}.
  This is the probability \eqn{p_j(u)}{p[j](u)}
  that a point at spatial location \eqn{u}
  will belong to type \eqn{j}.
  If \code{relative=TRUE}, the command computes the
  \emph{relative risk} of an event of type \eqn{j}
  relative to a control,
  \eqn{r_j(u) = p_j(u)/p_k(u)}{r[j](u) = p[j](u)/p[k](u)},
  where events of type \eqn{k} are treated as controls.
  The argument \code{control} determines which type \eqn{k}
  is treated as a control.

  If \code{at = "pixels"} the calculation is performed for
  every spatial location \eqn{u} on a fine pixel grid, and the result
  is a pixel image representing the function \eqn{p(u)}
  or a list of pixel images representing the functions 
  \eqn{p_j(u)}{p[j](u)} or \eqn{r_j(u)}{r[j](u)}
  for \eqn{j = 1,\ldots,m}{j = 1,...,m}.
  An infinite value of relative risk (arising because the
  probability of a control is zero) will be returned as \code{NA}.

  If \code{at = "points"} the calculation is performed
  only at the data points \eqn{x_i}{x[i]}. By default
  the result is a vector of values
  \eqn{p(x_i)}{p(x[i])} giving the estimated probability of a case
  at each data point, or a matrix of values 
  \eqn{p_j(x_i)}{p[j](x[i])} giving the estimated probability of
  each possible type \eqn{j} at each data point.
  If \code{relative=TRUE} then the relative risks
  \eqn{r(x_i)}{r(x[i])} or \eqn{r_j(x_i)}{r[j](x[i])} are
  returned.
  An infinite value of relative risk (arising because the
  probability of a control is zero) will be returned as \code{Inf}.

  Estimation is performed by a simple Nadaraja-Watson type kernel
  smoother (Bithell, 1990, 1991; Diggle, 2003; Baddeley, Rubak and
  Turner, 2015, section 14.4).
  The smoothing bandwidth can be specified in any of the following ways:
  \itemize{
    \item \code{sigma} is a single numeric value, giving the standard
    deviation of the isotropic Gaussian kernel.
    \item \code{sigma} is a numeric vector of length 2, giving the
    standard deviations in the \eqn{x} and \eqn{y} directions of
    a Gaussian kernel.
    \item \code{varcov} is a 2 by 2 matrix giving the
    variance-covariance matrix of the Gaussian kernel.
    \item \code{sigma} is a \code{function} which selects
    the bandwidth. 
    Bandwidth selection will be applied
    \bold{separately to each type of point}.
    An example of such a function is \code{\link{bw.diggle}}.
    \item 
    \code{sigma} and \code{varcov}
    are both missing or null. Then a \bold{common}
    smoothing bandwidth \code{sigma}
    will be selected by cross-validation using \code{\link{bw.relrisk}}.
    \item
    An infinite smoothing bandwidth, \code{sigma=Inf}, is permitted
    and yields a constant estimate of relative risk.
  }

  If \code{se=TRUE} then standard errors will also be computed,
  based on asymptotic theory, \emph{assuming a Poisson process}.

  The optional argument \code{weights} may provide numerical weights
  for the points of \code{X}. It should be a numeric vector of length
  equal to \code{npoints(X)}.
  
  The argument \code{weights} can also be an \code{expression}.
  It will be evaluated in the data frame \code{as.data.frame(X)}
  to obtain a vector of weights. The expression may involve
  the symbols \code{x} and \code{y} representing the Cartesian
  coordinates, and the symbol \code{marks} representing the mark values.

  The argument \code{weights} can also be a pixel image
  (object of class \code{"im"}). numerical weights for the data points
  will be extracted from this image (by looking up the pixel values
  at the locations of the data points in \code{X}).
}
\value{
  If \code{se=FALSE} (the default), the format is described below.
  If \code{se=TRUE}, the result is a list of two entries,
  \code{estimate} and \code{SE}, each having the format described below.
  
  If \code{X} consists of only two types of points,
  and if \code{casecontrol=TRUE},
  the result is a pixel image (if \code{at="pixels"})
  or a vector (if \code{at="points"}).
  The pixel values or vector values
  are the probabilities of a case if \code{relative=FALSE},
  or the relative risk of a case (probability of a case divided by the
  probability of a control) if \code{relative=TRUE}.

  If \code{X} consists of more than two types of points,
  or if \code{casecontrol=FALSE}, the result is:
  \itemize{
    \item (if \code{at="pixels"})
    a list of pixel images, with one image for each possible type of point.
    The result also belongs to the class \code{"solist"} so that it can
    be printed and plotted.
    \item
    (if \code{at="points"})
    a matrix of probabilities, with rows corresponding to
    data points \eqn{x_i}{x[i]}, and columns corresponding
    to types \eqn{j}.
  }
  The pixel values or matrix entries
  are the probabilities of each type of point if \code{relative=FALSE},
  or the relative risk of each type (probability of each type divided by the
  probability of a control) if \code{relative=TRUE}.

  If \code{relative=FALSE}, the resulting values always lie between 0
  and 1. If \code{relative=TRUE}, the results are either non-negative
  numbers, or the values \code{Inf} or \code{NA}. 
}
\section{Shrinkage estimate}{
  If the argument \code{shrink} is given, the shrinkage
  estimate proposed by Bithell (1991) is calculated.
  In this method, a constant value is
  added to the estimated intensity of the points of each type, before
  the relative risk calculation is performed. 

  The argument \code{shrink} should be a numeric value, or a numeric vector
  with one entry for each type of point. All values should be
  non-negative.
  
  The constant added to the estimated intensity of the points of type
  \code{j} is \code{shrink * K0 * pbar[j]} if
  \code{relative=FALSE}
  and \code{shrink * K0} if \code{relative=TRUE},
  where \code{K0} is the value of the smoothing kernel
  at the origin, and \code{pbar[j]} is the fraction of points of type
  \code{j} in the data pattern \code{X}.
  Bithell's original proposal corresponds to 
  \code{shrink=4, relative=TRUE}.

  The argument \code{fudge} is rarely used,
  but is retained for research purposes.
  It is added to the estimate of the intensity without any rescaling,
  before the relative risk calculation.
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
  of \code{relrisk.ppp} (in \pkg{spatstat.explore} versions
  \code{3.1-0} and earlier) effectively used \code{wtype="multiplicity"}.
}
\seealso{
  There is another method \code{\link[spatstat.model]{relrisk.ppm}} for point process
  models which computes \emph{parametric}
  estimates of relative risk, using the fitted model.

  See also 
 \code{\link{bw.relrisk}},
 \code{\link{density.ppp}},
 \code{\link{Smooth.ppp}},
 \code{\link[spatstat.geom]{eval.im}}
}
\examples{
   p.oak <- relrisk(urkiola, 20)
   if(interactive()) {
      plot(p.oak, main="proportion of oak")
      plot(eval.im(p.oak > 0.3), main="More than 30 percent oak")
      plot(split(lansing), main="Lansing Woods")
      p.lan <- relrisk(lansing, 0.05, se=TRUE)
      plot(p.lan$estimate, main="Lansing Woods species probability")
      plot(p.lan$SE, main="Lansing Woods standard error")
      wh <- im.apply(p.lan$estimate, which.max)
      types <- levels(marks(lansing))
      wh <- eval.im(types[wh])
      plot(wh, main="Most common species")
   }
}
\references{
  \baddrubaturnbook
  
  Bithell, J.F. (1990)
  An application of density estimation to geographical epidemiology.
  \emph{Statistics in Medicine} \bold{9}, 691--701.
  
  Bithell, J.F. (1991)
  Estimation of relative risk functions.
  \emph{Statistics in Medicine} \bold{10}, 1745--1751.

  Diggle, P.J. (2003)
  \emph{Statistical analysis of spatial point patterns},
  Second edition. Arnold.

  Diggle, P.J., Zheng, P. and Durr, P. (2005)
  Non-parametric estimation of spatial segregation in a
  multivariate point process: bovine tuberculosis in
  Cornwall, UK. 
  \emph{Applied Statistics} \bold{54}, 645--658.
}
\author{
  \adrian
  and \rolf.
}
\keyword{spatial}
\keyword{methods}
\keyword{smooth}
