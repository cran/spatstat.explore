#
#   quadrattest.R
#
#   $Revision: 1.70 $  $Date: 2023/07/17 07:38:30 $
#


quadrat.test <- function(X, ...) {
   UseMethod("quadrat.test")
}

quadrat.test.ppp <-
  function(X, nx=5, ny=nx,
           alternative = c("two.sided", "regular", "clustered"),
           method = c("Chisq", "MonteCarlo"),
           conditional=TRUE, CR=1,
           lambda=NULL, df.est=NULL,
           ...,
           xbreaks=NULL, ybreaks=NULL,
           tess=NULL, nsim=1999)
{
   Xname <- short.deparse(substitute(X))
   method <- match.arg(method)
   alternative <- match.arg(alternative)
   do.call(quadrat.testEngine,
          resolve.defaults(list(quote(X), nx=nx, ny=ny,
                                alternative=alternative,
                                method=method,
                                conditional=conditional,
                                CR=CR,
                                fit=lambda,
                                df.est=df.est,
                                xbreaks=xbreaks, ybreaks=ybreaks,
                                tess=tess,
                                nsim=nsim),
                           list(...), 
                           list(Xname=Xname, fitname="CSR")))
}

quadrat.test.splitppp <- function(X, ..., df=NULL, df.est=NULL, Xname=NULL)
{
  if(is.null(Xname))
    Xname <- short.deparse(substitute(X))
  pool.quadrattest(lapply(X, quadrat.test.ppp, ...),
                   df=df, df.est=df.est, Xname=Xname)
}



## Code for quadrat.test.ppm and quadrat.test.slrm is moved to spatstat.model


quadrat.test.quadratcount <-
  function(X,
           alternative = c("two.sided", "regular", "clustered"),
           method=c("Chisq", "MonteCarlo"),
           conditional=TRUE, CR=1,
           lambda=NULL, df.est=NULL,
           ...,
           nsim=1999) {
   trap.extra.arguments(...)
   method <- match.arg(method)
   alternative <- match.arg(alternative)
   quadrat.testEngine(Xcount=X,
                      alternative=alternative,
                      fit=lambda, df.est=df.est,
                      method=method, conditional=conditional, CR=CR, nsim=nsim)
}

quadrat.testEngine <- function(X, nx, ny,
                               alternative = c("two.sided",
                                                "regular", "clustered"),
                               method=c("Chisq", "MonteCarlo"),
                               conditional=TRUE, CR=1, ...,
                               nsim=1999,
                               Xcount=NULL,
                               xbreaks=NULL, ybreaks=NULL, tess=NULL,
                               fit=NULL, df.est=NULL,
                               Xname=NULL, fitname=NULL) {
  trap.extra.arguments(...)
  method <- match.arg(method)
  alternative <- match.arg(alternative)
  if(method == "MonteCarlo") {
    check.1.real(nsim)
    explain.ifnot(nsim > 0)
  }
  if(!is.null(df.est)) check.1.integer(df.est)
  if(is.null(Xcount))
    Xcount <- quadratcount(X, nx=nx, ny=ny, xbreaks=xbreaks, ybreaks=ybreaks,
                           tess=tess)
  tess <- attr(Xcount, "tess")
  
  ## determine expected values under model
  normalised <- FALSE
  df.est.implied <- 0
  if(is.null(fit)) {
    nullname <- "CSR"
    if(tess$type == "rect") 
      areas <- outer(diff(tess$xgrid), diff(tess$ygrid), "*")
    else 
      areas <- unlist(lapply(tiles(tess), area))
    fitmeans <- sum(Xcount) * areas/sum(areas)
    normalised <- TRUE
    df.est.implied <- 1
  } else if(is.im(fit) || inherits(fit, "funxy")) {
    nullname <- "Poisson process with given intensity"
    lambda <- as.im(fit, W=Window(tess))
    means <- integral(lambda, tess)
    fitmeans <- sum(Xcount) * means/sum(means)
    normalised <- TRUE
    df.est.implied <- 1
  } else if(inherits(fit, "ppm")) {
    if(!requireNamespace("spatstat.model")) 
      stop("To predict a fitted model, the package spatstat.model is required",
           call.=FALSE)
    if(!is.poisson(fit))
      stop("Quadrat test only supported for Poisson point process models")
    if(is.marked(fit))
      stop("Sorry, not yet implemented for marked point process models")
    nullname <- paste("fitted Poisson model", sQuote(fitname))
    lambda <- predict(fit, locations=Window(tess), type="intensity")
    means <- integral(lambda, tess)
    fitmeans <- sum(Xcount) * means/sum(means)
    normalised <- FALSE
    df.est.implied <- length(coef(fit))
  } else if(inherits(fit, "slrm")) {
    if(!requireNamespace("spatstat.model")) 
      stop("To predict a fitted model, the package spatstat.model is required",
           call.=FALSE)
    nullname <- paste("fitted spatial logistic regression", sQuote(fitname))
    probs <- predict(fit, type="probabilities")
    ## usual case
    xy <- raster.xy(probs, drop=TRUE)
    masses <- as.numeric(probs[])
    V <- tileindex(xy, Z=tess)
    fitmeans <- tapplysum(masses, list(tile=V))
    normalised <- FALSE
    df.est.implied <- length(coef(fit))
  } else
    stop("fit should be a point process model (ppm or slrm) or pixel image")
  
  df <- switch(method,
               Chisq      = length(fitmeans) - df.est %orifnull% df.est.implied,
               MonteCarlo = NULL)    

  ## assemble data for test
  
  OBS <- as.vector(t(as.table(Xcount)))
  EXP <- as.vector(fitmeans)

  if(!normalised)
    EXP <- EXP * sum(OBS)/sum(EXP)

  ## label it
  switch(method,
         Chisq = {
           if(CR == 1) {
             testname <- "Chi-squared test"
             reference <- statname <- NULL
           } else {
             testname <- CressieReadTestName(CR)
             statname <- paste("Test statistic:", CressieReadName(CR))
             reference <- "(p-value obtained from chi-squared distribution)"
           }
         },
         MonteCarlo = {
           testname <- paste(if(conditional) "Conditional" else "Unconditional",
                             "Monte Carlo test")
           statname <- paste("Test statistic:", CressieReadName(CR))
           reference <- NULL
         })
  testblurb <- paste(testname, "of", nullname, "using quadrat counts")
  testblurb <- c(testblurb, statname, reference)

  #' perform test
  result <- X2testEngine(OBS, EXP,
                         method=method, df=df, nsim=nsim,
                         conditional=conditional, CR=CR,
                         alternative=alternative,
                         testname=testblurb, dataname=Xname)

  class(result) <- c("quadrattest", class(result))
  attr(result, "quadratcount") <- Xcount
  return(result)
}

CressieReadStatistic <- function(OBS, EXP, lambda=1,
                                 normalise=FALSE, named=TRUE) {
  if(normalise) EXP <- sum(OBS) * EXP/sum(EXP)
  y <- if(lambda == 1) sum((OBS - EXP)^2/EXP) else
       if(lambda == 0) 2 * sum(ifelse(OBS > 0, OBS * log(OBS/EXP), 0)) else
       if(lambda == -1) 2 * sum(EXP * log(EXP/OBS)) else
       (2/(lambda * (lambda + 1))) * sum(ifelse(OBS > 0,
                                                OBS * ((OBS/EXP)^lambda - 1),
                                                0))
  names(y) <- if(named) CressieReadSymbol(lambda) else NULL
  return(y)
}

CressieReadSymbol <- function(lambda) {
  if(lambda == 1) "X2" else
  if(lambda == 0) "G2" else
  if(lambda == -1/2) "T2" else
  if(lambda == -1) "GM2" else
  if(lambda == -2) "NM2" else "CR"
}

CressieReadName <- function(lambda) {
  if(lambda == 1) "Pearson X2 statistic" else
  if(lambda == 0) "likelihood ratio test statistic G2" else
  if(lambda == -1/2) "Freeman-Tukey statistic T2" else
  if(lambda == -1) "modified likelihood ratio test statistic GM2" else
  if(lambda == -2) "Neyman modified X2 statistic NM2" else
  paste("Cressie-Read statistic",
        paren(paste("lambda =",
                    if(abs(lambda - 2/3) < 1e-7) "2/3" else lambda)
              )
        )
}

CressieReadTestName <- function(lambda) {
  if(lambda == 1) "Chi-squared test" else
  if(lambda == 0) "Likelihood ratio test" else
  if(lambda == -1/2) "Freeman-Tukey test" else
  if(lambda == -1) "Modified likelihood ratio test" else
  if(lambda == -2) "Neyman modified chi-squared test" else
  paste("Cressie-Read power divergence test",
        paren(paste("lambda =",
                    if(abs(lambda - 2/3) < 1e-7) "2/3" else lambda)
              )
        )
}

X2testEngine <- function(OBS, EXP, ...,
                         method=c("Chisq", "MonteCarlo"),
                         CR=1,
                         df=NULL, nsim=NULL,
                         conditional, alternative, testname, dataname) {
  method <- match.arg(method)
  if(method == "Chisq" && any(EXP < 5)) 
    warning(paste("Some expected counts are small;",
                  "chi^2 approximation may be inaccurate"),
            call.=FALSE)
  X2 <- CressieReadStatistic(OBS, EXP, CR)
  # conduct test
  switch(method,
         Chisq = {
           if(!is.null(df))
             names(df) <- "df"
           pup <- pchisq(X2, df, lower.tail=FALSE)
           plo <- pchisq(X2, df, lower.tail=TRUE)
           PVAL <- switch(alternative,
                          regular   = plo,
                          clustered = pup,
                          two.sided = 2 * min(pup, plo))
         },
         MonteCarlo = {
           nsim <- as.integer(nsim)
           if(conditional) {
             npts <- sum(OBS)
             p <- EXP/sum(EXP)
             SIM <- rmultinom(n=nsim,size=npts,prob=p)
           } else {
             ne <- length(EXP)
             SIM  <- matrix(rpois(nsim*ne,EXP),nrow=ne)
           }
           simstats <- apply(SIM, 2, CressieReadStatistic,
                             EXP=EXP, lambda=CR, normalise=!conditional)
           if(anyDuplicated(simstats))
             simstats <- jitter(simstats)
           phi <- (1 + sum(simstats >= X2))/(1+nsim)
           plo <- (1 + sum(simstats <= X2))/(1+nsim)
           PVAL <- switch(alternative,
                          clustered = phi,
                          regular   = plo,
                          two.sided = min(1, 2 * min(phi,plo)))
         })
    result <- structure(list(statistic = X2,
                             parameter = df,
                             p.value = PVAL,
                             method = testname,
                             data.name = dataname,
                             alternative = alternative,
                             observed = OBS,
                             expected = EXP,
                             residuals = (OBS - EXP)/sqrt(EXP),
                             CR = CR,
                             method.key = method),
                        class = "htest")
  return(result)
}
                         
print.quadrattest <- function(x, ...) {
   NextMethod("print")
   single <- is.atomicQtest(x)
   if(!single)
     splat("Pooled test")
   if(waxlyrical('gory')) {
     if(single) {
       cat("Quadrats: ")
     } else {
       splat("Quadrats of component tests:")
     }
     x <- as.tess(x)
     x <- if(is.tess(x)) unmark(x) else solapply(x, unmark)
     do.call(print,
             resolve.defaults(list(x=quote(x)),
                              list(...),
                              list(brief=TRUE)))
   }
   return(invisible(NULL))
}

plot.quadrattest <- local({

  plot.quadrattest <- function(x, ..., textargs=list()) {
    xname <- short.deparse(substitute(x))

    if(!is.atomicQtest(x)) {
      # pooled test - plot the original tests
      tests <- extractAtomicQtests(x)
      dont.complain.about(tests)
      do.call(plot,
              resolve.defaults(list(x=quote(tests)),
                               list(...),
                               list(main=xname)))
      return(invisible(NULL))
    }
    Xcount <- attr(x, "quadratcount")

    # plot tessellation
    tess  <- as.tess(Xcount)
    do.call(plot.tess,
            resolve.defaults(list(quote(tess)),
                             list(...),
                             list(main=xname)))
    # compute locations for text
    til <- tiles(tess)
    ok <- sapply(til, haspositivearea)
    incircles <- lapply(til[ok], incircle)
    x0 <- sapply(incircles, getElement, name="x")
    y0 <- sapply(incircles, getElement, name="y")
    ra <- sapply(incircles, getElement, name="r")
    # plot observed counts
    cos30 <- sqrt(2)/2
    sin30 <- 1/2
    f <- 0.4
    dotext(-f * cos30, f * sin30,
           as.vector(t(as.table(Xcount)))[ok],
           x0, y0, ra, textargs, 
           adj=c(1,0), ...)
    # plot expected counts
    dotext(f * cos30, f * sin30,
           round(x$expected,1)[ok],
           x0, y0, ra, textargs,
           adj=c(0,0), ...)
    # plot Pearson residuals
    dotext(0, -f,  signif(x$residuals,2)[ok],
           x0, y0, ra, textargs,
           ...)
    return(invisible(NULL))
  }
 
  dotext <- function(dx, dy, values, x0, y0, ra, textargs, ...) {
    xx <- x0 + dx * ra
    yy <- y0 + dy * ra
    do.call.matched(text.default,
                    resolve.defaults(list(x=quote(xx), y = quote(yy)),
                                     list(labels=paste(as.vector(values))),
                                     textargs, 
                                     list(...)),
                    funargs=graphicsPars("text"))
  }

  haspositivearea <- function(x) { !is.null(x) && area(x) > 0 }
  
  plot.quadrattest
})

########  pooling multiple quadrat tests into a quadrat test

pool.quadrattest <- function(...,
                             df=NULL, df.est=NULL, nsim=1999, Xname=NULL,
                             CR=NULL) {
  argh <- list(...)
  if(!is.null(df) + !is.null(df.est))
    stop("Arguments df and df.est are incompatible")
  
  if(all(unlist(lapply(argh, inherits, what="quadrattest")))) {
    # Each argument is a quadrattest object
    tests <- argh
  } else if(length(argh) == 1 &&
            is.list(arg1 <- argh[[1]]) &&
            all(unlist(lapply(arg1, inherits, "quadrattest")))) {
    # There is just one argument, which is a list of quadrattests
    tests <- arg1
  } else stop("Each entry in the list must be a quadrat test")

  # data from all cells in all tests
  OBS <- unlist(lapply(tests, getElement, name="observed"))
  EXP <- unlist(lapply(tests, getElement, name="expected"))
  # RES <- unlist(lapply(tests, getElement, name="residuals"))
  # STA <- unlist(lapply(tests, getElement, name="statistic"))

  # information about each test
  Mkey <- unlist(lapply(tests, getElement, name="method.key"))
  Testname <- lapply(tests, getElement, name="method")
  Alternative <- unlist(lapply(tests, getElement, name="alternative"))
  Conditional <- unlist(lapply(tests, getElement, name="conditional"))
  
  # name of data
  if(is.null(Xname)) {
    Nam <-  unlist(lapply(tests, getElement, name="data.name"))
    Xname <- commasep(sQuote(Nam))
  }

  # name of test
  testname    <- unique(Testname)
  method.key <- unique(Mkey)
  if(length(testname) > 1)
    stop(paste("Cannot combine different types of tests:",
               commasep(sQuote(method.key))))
  testname <- testname[[1]]

  # alternative hypothesis
  alternative <- unique(Alternative)
  if(length(alternative) > 1)
    stop(paste("Cannot combine tests with different alternatives:",
               commasep(sQuote(alternative))))

  # conditional tests
  conditional <- any(Conditional)
  if(conditional)
    stop("Sorry, not implemented for conditional tests")

  # Cressie-Read exponent
  if(is.null(CR)) {
    CR <- unlist(lapply(tests, getElement, name="CR"))
    CR <- unique(CR)
    if(length(CR) > 1) {
      warning("Tests used different values of CR; assuming CR=1")
      CR <- 1
    }
  }
                 
  if(method.key == "Chisq") {
    # determine degrees of freedom
    if(is.null(df)) {
      if(!is.null(df.est)) {
        # total number of observations minus number of fitted parameters
        df <- length(OBS) - df.est
      } else {
        # total degrees of freedom of tests
        # implicitly assumes independence of tests
        PAR <- unlist(lapply(tests, getElement, name="parameter"))
        df <- sum(PAR)
      }
    }
    # validate df
    if(df < 1)
      stop(paste("Degrees of freedom = ", df))
    names(df) <- "df"
  }
    
  # perform test
  result <- X2testEngine(OBS, EXP,
                         method=method.key, df=df, nsim=nsim,
                         conditional=conditional, CR=CR,
                         alternative=alternative,
                         testname=testname, dataname=Xname)
  # add info
  class(result) <- c("quadrattest", class(result))
  attr(result, "tests") <- as.solist(tests)
  # there is no quadratcount attribute 
  return(result)
}

is.atomicQtest <- function(x) {
  inherits(x, "quadrattest") && is.null(attr(x, "tests"))
}

extractAtomicQtests <- function(x) {
  if(is.atomicQtest(x))
    return(list(x))
  stopifnot(inherits(x, "quadrattest"))
  tests <- attr(x, "tests")
  y <- lapply(tests, extractAtomicQtests)
  z <- do.call(c, y)
  return(as.solist(z))
}

as.tess.quadrattest <- function(X) {
  if(is.atomicQtest(X)) {
    Y <- attr(X, "quadratcount")
    return(as.tess(Y))
  }
  tests <- extractAtomicQtests(X)
  return(as.solist(lapply(tests, as.tess.quadrattest)))
}

as.owin.quadrattest <- function(W, ..., fatal=TRUE) {
  if(is.atomicQtest(W))
    return(as.owin(as.tess(W), ..., fatal=fatal))    
  gezeur <- paste("Cannot convert quadrat test result to a window;",
                  "it contains data for several windows")
  if(fatal) stop(gezeur) else warning(gezeur)
  return(NULL)
}

domain.quadrattest <- Window.quadrattest <- function(X, ...) { as.owin(X) }

## The shift method is undocumented.
## It is only needed in plot.listof etc

shift.quadrattest <- function(X, ...) {
  if(is.atomicQtest(X)) {
    attr(X, "quadratcount") <- qc <- shift(attr(X, "quadratcount"), ...)
    attr(X, "lastshift") <- getlastshift(qc)
  } else {
    tests <- extractAtomicQtests(X)
    attr(X, "tests") <- te <- lapply(tests, shift, ...)
    attr(X, "lastshift") <- getlastshift(te[[1]])
  }
  return(X)
}

