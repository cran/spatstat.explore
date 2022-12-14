\name{eval.fv}
\alias{eval.fv}
\title{Evaluate Expression Involving Functions}
\description{
  Evaluates any expression involving one or more function value (fv) objects,
  and returns another object of the same kind.
}
\usage{
  eval.fv(expr, envir, dotonly=TRUE, equiv=NULL, relabel=TRUE)
}
\arguments{
  \item{expr}{An expression.}
  \item{envir}{
    Optional. The environment in which to evaluate the
    expression, or a named list containing \code{"fv"} objects to be
    used in the expression.
  }
  \item{dotonly}{Logical. See Details.}
  \item{equiv}{Mapping between column names of different objects
    that are deemed to be equivalent. See Details.}
  \item{relabel}{
    Logical value indicating whether to
    compute appropriate labels for the resulting function.
    This should normally be \code{TRUE} (the default).
    See Details.
  }
}
\details{
  This is a wrapper to make it easier to perform
  pointwise calculations with the summary functions
  used in spatial statistics.

  An object of class \code{"fv"} is essentially a data frame
  containing several different statistical estimates of the same
  function. Such objects are returned by \code{\link[spatstat.explore]{Kest}} and its
  relatives.

  For example, suppose \code{X} is an object of class \code{"fv"}
  containing several different estimates of the Ripley's K function \eqn{K(r)},
  evaluated at a sequence of values of \eqn{r}.
  Then \code{eval.fv(X+3)} effectively adds 3 to 
  each function estimate in \code{X}, and returns
  the resulting object. 

  Suppose \code{X} and \code{Y} are two objects of class \code{"fv"}
  which are compatible (in particular they have the same vector
  of \eqn{r} values). Then 
  \code{eval.im(X + Y)} will add the corresponding function values in
  \code{X} and \code{Y}, and return the resulting function.

  In general, \code{expr} can be any expression involving
  (a) the \emph{names} of objects of class \code{"fv"}, (b) scalar
  constants, and (c) functions which are vectorised.
  See the Examples.

  First \code{eval.fv} determines which of the \emph{variable names}
  in the expression \code{expr} refer to objects of class \code{"fv"}.
  Each such name is replaced by a vector containing the function values.
  The expression is then evaluated. The result should be a vector;
  it is taken as the new vector of function values.

  The expression \code{expr} must be vectorised.
  There must be at least one object of class \code{"fv"} in the expression.
  If the objects are not compatible, they will be made compatible
  by \code{\link{harmonise.fv}}.

  If \code{dotonly=TRUE} (the default), the expression will be
  evaluated only for those columns of an \code{"fv"} object
  that contain values of the function itself (rather than
  values of the derivative of the function, the hazard rate, etc).
  If \code{dotonly=FALSE}, the expression will be evaluated for all columns.

  For example the result of \code{\link[spatstat.explore]{Fest}} includes several columns
  containing estimates of the empty space function \eqn{F(r)},
  but also includes an estimate of the
  \emph{hazard} \eqn{h(r)} of \eqn{F(r)}. Transformations that are valid
  for \eqn{F} may not be valid for \eqn{h}. Accordingly, \eqn{h} would
  normally be omitted from the calculation.
  
  The columns of an object \code{x} that represent the function itself
  are identified by its \dQuote{dot} names, \code{fvnames(x, ".")}.
  They are the columns normally plotted by \code{\link{plot.fv}}
  and identified by the symbol \code{"."} in plot formulas
  in \code{\link{plot.fv}}.

  The argument \code{equiv} can be used to specify that 
  two different column names in different function objects
  are mathematically equivalent or cognate.
  It should be a list of \code{name=value} pairs, or a named vector of
  character strings, indicating the pairing of equivalent names.
  (Without this argument, these columns would be discarded.)
  See the Examples.

  The argument \code{relabel} should normally be \code{TRUE} (the default).
  It determines whether to compute appropriate mathematical labels and
  descriptions for the resulting function object
  (used when the object is printed or plotted).
  If \code{relabel=FALSE} then this does not occur,
  and the mathematical labels and descriptions
  in the result are taken from the function object
  that appears first in the expression. This reduces computation time
  slightly (for advanced use only).
}
\value{
  Another object of class \code{"fv"}.
}
\seealso{
  \code{\link{fv.object}},
  \code{\link[spatstat.explore]{Kest}}
}
\examples{
  # manipulating the K function
  X <- runifrect(42)
  Ks <- Kest(X)

  eval.fv(Ks + 3)
  Ls <- eval.fv(sqrt(Ks/pi))

  # manipulating two K functions
  Y <- runifrect(20)
  Kr <- Kest(Y)

  Kdif <- eval.fv(Ks - Kr)
  Z <- eval.fv(sqrt(Ks/pi) - sqrt(Kr/pi))

  ## Use of 'envir'
  U <- eval.fv(sqrt(K), list(K=Ks))

  ## Use of 'equiv'
  Fc <- Fest(cells)
  Gc <- Gest(cells)
  # Hanisch and Chiu-Stoyan estimators are cognate
  Dc <- eval.fv(Fc - Gc, equiv=list(cs="han"))
}
\author{
  \adrian
  and \rolf
}
\keyword{spatial}
\keyword{manip}
\keyword{programming}
