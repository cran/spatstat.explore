#'
#' evidence.R
#'
#'   evaluate covariate values at data points and at pixels
#'   together with intensity of null/reference model
#'
#' $Revision: 1.55 $ $Date: 2025/06/02 07:00:33 $
#'


evalCovar <- function(model, covariate, ...) {
  .Deprecated("spatialCovariateEvidence", "spatstat.core")
  spatialCovariateEvidence(model, covariate, ...)
}

spatialCovariateEvidence <- function(model, covariate, ...) {
  UseMethod("spatialCovariateEvidence")
}


## Code for spatialCovariateEvidence.ppm() is moved to spatstat.model


spatialCovariateEvidence.ppp <- local({

  spatialCovariateEvidence.ppp <- function(model, covariate, ...,
                            lambdatype=c("cif", "trend", "intensity"),
                            dimyx=NULL, eps=NULL,
                            rule.eps=c("adjust.eps",
                                       "grow.frame", "shrink.frame"),
                            interpolate=TRUE,
                            jitter=TRUE, jitterfactor=1,
                            modelname=NULL, covname=NULL,
                            dataname=NULL, subset=NULL, clip.predict=TRUE,
                            raster.action) {
    lambdatype <- match.arg(lambdatype)
    dont.complain.about(raster.action)
    dont.complain.about(lambdatype)
    if(is.null(modelname)) modelname <- "CSR"
    if(is.null(dataname)) dataname <- "data"
    if(is.null(covname)) {
      if(is.character(covariate)) covname <- covariate else 
      covname <- singlestring(short.deparse(substitute(covariate)))
    }
    
    info <-  list(modelname=modelname, covname=covname,
                  dataname=dataname, csr=TRUE, ispois=TRUE,
                  spacename="two dimensions")
  
    X <- model
    W <- Window(X)

    LambdaBar <- intensity(X) ## numeric value or vector
    
    #' explicit control of pixel resolution
    if(!is.null(dimyx) || !is.null(eps)) {
      rule.eps <- match.arg(rule.eps)
      W <- as.mask(W, dimyx=dimyx, eps=eps, rule.eps=rule.eps)
    }

    Wfull <- Zfull <- NULL
    
    if(!is.null(subset)) {
      #' restrict to subset
      if(!clip.predict) {
        #' use original window for prediction
        Wfull <- W
      }
      X <- X[subset]
      W <- W[subset, drop=FALSE]
    }
    
    #' evaluate covariate 
    if(is.character(covariate)) {
      #' One of the characters 'x' or 'y'
      #' Turn it into a function.
      ns <- length(covariate)
      if(ns == 0) stop("covariate is empty")
      if(ns > 1) stop("more than one covariate specified")
      covname <- covariate
      covariate <- switch(covariate,
                          x=xcoordfun,
                          y=ycoordfun,
                          stop(paste("Unrecognised covariate",
                                     dQuote(covariate))))
    } 
  
    if(!is.marked(X)) {
      #' ...................  unmarked .......................
      if(is.im(covariate)) {
        type <- "im"
        if(!interpolate) {
          #' look up covariate values 
          ZX <- safelookup(covariate, X)
        } else {
          #' evaluate at data points by interpolation
          ZX <- interp.im(covariate, X$x, X$y)
          #' fix boundary glitches
          if(any(uhoh <- is.na(ZX)))
            ZX[uhoh] <- safelookup(covariate, X[uhoh])
        }
        #' covariate values for pixels inside window
        Z <- covariate[W, drop=FALSE]
        if(!is.null(Wfull)) Zfull <- covariate[Wfull, drop=FALSE]
        #' corresponding mask
        W <- as.owin(Z)
      } else if(is.function(covariate)) {
        type <- "function"
        #' evaluate exactly at data points
        ZX <- covariate(X$x, X$y)
        if(!all(is.finite(ZX)))
          warning("covariate function returned NA or Inf values")
        #' window
        W <- as.mask(W)
        #' covariate in window
        Z <- as.im(covariate, W=W)
        if(!is.null(Wfull)) Zfull <- as.im(covariate, W=Wfull)
        #' collapse function body to single string
        covname <- singlestring(covname)
      } else if(is.null(covariate)) {
        stop("The covariate is NULL", call.=FALSE)
      } else stop(paste("The covariate should be",
                        "an image, a function(x,y)",
                        "or one of the characters",
                        sQuote("x"), "or", sQuote("y")),
                  call.=FALSE)
      #' values of covariate in window
      Zvalues <- as.vector(Z[W, drop=TRUE])
      #' corresponding intensity values
      lambda <- rep.int(LambdaBar, length(Zvalues))
      #' pixel area (constant)
      pixelarea <- with(Z, xstep * ystep)
      #' lambda values at data points
      lambdaX <- rep.int(LambdaBar, npoints(X))
      #' lambda image
      lambdaimage <- as.im(LambdaBar, Wfull %orifnull% W)
    } else {
      #' ...................  marked .......................
      if(!is.multitype(X))
        stop("Only implemented for multitype patterns (factor marks)")
      marx <- marks(X, dfok=FALSE)
      possmarks <- levels(marx)
      npts <- npoints(X)
      #' single image: replicate 
      if(is.im(covariate)) {
        covariate <- rep(list(covariate), times=length(possmarks))
        names(covariate) <- as.character(possmarks)
      }
      #'
      if(is.list(covariate) && all(sapply(covariate, is.im))) {
        #' list of images
        type <- "im"
        if(length(covariate) != length(possmarks))
          stop("Number of images does not match number of possible marks")
        #' evaluate covariate at each data point 
        ZX <- numeric(npts)
        for(k in seq_along(possmarks)) {
          ii <- (marx == possmarks[k])
          covariate.k <- covariate[[k]]
          if(!interpolate) {
            #' look up covariate values 
            values <- safelookup(covariate, X)
          } else {
            #' interpolate
            values <- interp.im(covariate.k, x=X$x[ii], y=X$y[ii])
            #' fix boundary glitches
            if(any(uhoh <- is.na(values)))
              values[uhoh] <- safelookup(covariate.k, X[ii][uhoh])
          }
          ZX[ii] <- values
        }
        #' restrict covariate images to window 
        Z <- solapply(covariate, "[", i=W, drop=FALSE)
        if(!is.null(Wfull)) Z <- solapply(covariate, "[", i=Wfull, drop=FALSE)
        #' extract pixel locations and pixel values
        Zframes <- lapply(Z, as.data.frame)
        #' covariate values at each pixel inside window
        Zvalues <- unlist(lapply(Zframes, getElement, name="value"))
        #' pixel locations 
        locn <- lapply(Zframes, getxy)
        #' tack on mark values
        for(k in seq_along(possmarks))
          locn[[k]] <- cbind(locn[[k]], data.frame(marks=possmarks[k]))
        loc <- do.call(rbind, locn)
        #' corresponding fitted [conditional] intensity values
        lambda <- LambdaBar[as.integer(loc$marks)]
        #' pixel areas
        pixelarea <- rep(sapply(Z, pixarea), sapply(Z, npixdefined))
      } else if(is.function(covariate)) {
        type <- "function"
        #' evaluate exactly at data points
        ZX <- functioncaller(x=X$x, y=X$y, m=marx, f=covariate, ...)
        #' functioncaller: function(x,y,m,f,...) { f(x,y,m,...) }
        #' same window
        W <- as.mask(W)
        #' covariate in window
        Z <- list()
        for(k in seq_along(possmarks))
          Z[[k]] <- as.im(functioncaller, m=possmarks[k], f=covariate, W=W, ...)
        #' covariate in original window, for prediction
        if(!is.null(Wfull)) {
          Zfull <- list()
          for(k in seq_along(possmarks))
            Zfull[[k]] <- as.im(functioncaller, m=possmarks[k], f=covariate, W=Wfull, ...)
        }
        Zpixvalues <- lapply(Z, pixelvalues)
        Zvalues <- unlist(Zpixvalues)
        #' corresponding fitted [conditional] intensity values
        lambda <- rep(LambdaBar, lengths(Zpixvalues))
        if(length(lambda) != length(Zvalues))
          stop("Internal error: length(lambda) != length(Zvalues)")
        #' collapse function body to single string
        covname <- singlestring(covname)
        #' pixel areas
        pixelarea <- rep(sapply(Z, pixarea), sapply(Z, npixdefined))
      } else if(is.null(covariate)) {
        stop("The covariate is NULL", call.=FALSE)
      } else stop(paste("For a multitype point pattern,", 
                        "the covariate should be an image, a list of images,",
                        "a function(x,y,m)", 
                        "or one of the characters",
                        sQuote("x"), "or", sQuote("y")),
                  call.=FALSE)
      #' lambda values at data points
      lambdaX <- LambdaBar[as.integer(marks(X))]
      #' lambda images
      lambdaimage <- solapply(LambdaBar, as.im, W=Wfull %orifnull% W)
      names(lambdaimage) <- possmarks
    }    
    #' ..........................................................

    #' apply jittering to avoid ties
    if(jitter) {
      ZX <- jitter(ZX, factor=jitterfactor)
      Zvalues <- jitter(Zvalues, factor=jitterfactor)
    }

    lambdaname <- "the average intensity"
    check.finite(lambda, xname=lambdaname, usergiven=FALSE)
    check.finite(Zvalues, xname="the covariate", usergiven=TRUE)

    #' wrap up 
    values <- list(Zimage      = Zfull %orifnull% Z,
                   lambdaimage = lambdaimage,
                   Zvalues     = Zvalues,
                   lambda      = lambda,
                   lambdaX     = lambdaX,
                   weights     = pixelarea,
                   ZX          = ZX,
                   type        = type)
    return(list(values=values, info=info, X=X)) # X is possibly a subset of original
  }

  xcoordfun <- function(x,y,m){x}
  ycoordfun <- function(x,y,m){y}

  pixarea <- function(z) { z$xstep * z$ystep }
  npixdefined <- function(z) { sum(!is.na(z$v)) }
  pixelvalues <- function(z) { as.data.frame(z)[,3L] }
  getxy <- function(z) { z[,c("x","y")] }

  ## Function caller used for marked locations (x,y,m) only.
  functioncaller <- function(x,y,m,f,...) {
    nf <- length(names(formals(f)))
    if(nf < 2) stop("Covariate function must have at least 2 arguments")
    if(nf == 2) return(f(x,y))
    if(nf == 3) return(f(x,y,m))
    argh <- list(...)
    extra <- intersect(names(argh),
                       names(formals(f))[-(1:3)])
    value <- do.call(f, append(list(x,y,m), argh[extra]))
    return(value)
  }
            
  
  spatialCovariateEvidence.ppp
})


spatialCovariateEvidence.exactppm <- local({

  spatialCovariateEvidence.exactppm <- function(model, covariate, ...,
                                 lambdatype=c("cif", "trend", "intensity"),
                                 dimyx=NULL, eps=NULL,
                                 rule.eps=c("adjust.eps",
                                            "grow.frame", "shrink.frame"),
                                 interpolate=TRUE,
                                 jitter=TRUE, jitterfactor=1,
                                 modelname=NULL, covname=NULL,
                                 dataname=NULL, subset=NULL, clip.predict=TRUE,
                                 raster.action) {
    lambdatype <- match.arg(lambdatype)
    dont.complain.about(lambdatype, raster.action)
    #' evaluate covariate values at data points and at pixels
    ispois <- TRUE
    csr <- is.null(model$baseline)
    #' determine names
    if(is.null(modelname))
      modelname <- if(csr) "CSR" else "model with baseline"
    if(is.null(covname)) {
      if(is.character(covariate)) covname <- covariate else
      covname <- singlestring(short.deparse(substitute(covariate)))
    }
    if(is.null(dataname))
      dataname <- "X"
    
    info <-  list(modelname=modelname, covname=covname,
                  dataname=dataname, csr=csr, ispois=ispois,
                  spacename="two dimensions")
  
    X <- model$X
    W <- Window(X)

    #' explicit control of pixel resolution
    if(!is.null(dimyx) || !is.null(eps)) {
      rule.eps <- match.arg(rule.eps)
      W <- as.mask(W, dimyx=dimyx, eps=eps, rule.eps=rule.eps)
    }

    Wfull <- Zfull <- NULL
    
    if(!is.null(subset)) {
      #' restrict to subset
      if(!clip.predict) {
        ## use original window for prediction
        Wfull <- W
      }
      X <- X[subset]
      W <- W[subset, drop=FALSE]
    } 
    
    #' evaluate covariate 
    if(is.character(covariate)) {
      #' One of the characters 'x' or 'y'
      #' Turn it into a function.
      ns <- length(covariate)
      if(ns == 0) stop("covariate is empty")
      if(ns > 1) stop("more than one covariate specified")
      covname <- covariate
      covariate <- switch(covariate,
                          x=xcoordfun,
                          y=ycoordfun,
                          stop(paste("Unrecognised covariate",
                                     dQuote(covariate))))
    } 
  
    if(!is.marked(X)) {
      #' ...................  unmarked .......................
      if(is.im(covariate)) {
        type <- "im"
        if(!interpolate) {
          #' look up covariate values 
          ZX <- safelookup(covariate, X)
        } else {
          #' evaluate at data points by interpolation
          ZX <- interp.im(covariate, X$x, X$y)
          #' fix boundary glitches
          if(any(uhoh <- is.na(ZX)))
            ZX[uhoh] <- safelookup(covariate, X[uhoh])
        }
        #' covariate values for pixels inside window (for calculation)
        Z <- covariate[W, drop=FALSE]
        #' covariate values for pixels inside window (for prediction)
        if(!is.null(Wfull)) Zfull <- covariate[Wfull, drop=FALSE] 
        #' corresponding mask
        W <- as.owin(Z)
      } else if(is.function(covariate)) {
        type <- "function"
        #' evaluate exactly at data points
        ZX <- covariate(X$x, X$y)
        if(!all(is.finite(ZX)))
          warning("covariate function returned NA or Inf values")
        #' window
        W <- as.mask(W)
        #' covariate in window
        Z <- as.im(covariate, W=W)
        if(!is.null(Wfull)) Zfull <- as.im(covariate, W=Wfull)
        #' collapse function body to single string
        covname <- singlestring(covname)
      } else if(is.null(covariate)) {
        stop("The covariate is NULL", call.=FALSE)
      } else stop(paste("The covariate should be",
                        "an image, a function(x,y)",
                        "or one of the characters",
                        sQuote("x"), "or", sQuote("y")),
                  call.=FALSE)
      #' fitted [conditional] intensity image 
      Lambda <- predict(model, locations=W, type=lambdatype)
      #' restrict to W
      Lambda <- Lambda[W, drop=FALSE]
      Z <- Z[W, drop=FALSE]
      #' extract corresponding pixel values 
      df <- pairs.im(Lambda, Z, plot=FALSE, drop=TRUE)
      Zvalues <- df$Z
      lambda  <- df$Lambda
      #' pixel area (constant)
      pixelarea <- with(Z, xstep * ystep)
    } else {
      #' ...................  marked .......................
      if(!is.multitype(X))
        stop("Only implemented for multitype models (factor marks)")
      marx <- marks(X, dfok=FALSE)
      possmarks <- levels(marx)
      npts <- npoints(X)
      #' predicted intensity: may restrict domain
      LambdaImages <- predict(model, locations=W, type=lambdatype)
      W <- do.call(intersect.owin, unname(lapply(LambdaImages, as.owin)))
      lambda <- unlist(lapply(LambdaImages, pixelvalues))
      #' handle covariate
      #' single image: replicate 
      if(is.im(covariate)) {
        covariate <- rep(list(covariate), times=length(possmarks))
        names(covariate) <- as.character(possmarks)
      }
      if(is.list(covariate) && all(sapply(covariate, is.im))) {
        #' list of images
        type <- "im"
        if(length(covariate) != length(possmarks))
          stop("Number of images does not match number of possible marks")
        #' evaluate covariate at each data point 
        ZX <- numeric(npts)
        for(k in seq_along(possmarks)) {
          ii <- (marx == possmarks[k])
          covariate.k <- covariate[[k]]
          if(!interpolate) {
            #' look up covariate values 
            values <- safelookup(covariate, X)
          } else {
            #' interpolate
            values <- interp.im(covariate.k, x=X$x[ii], y=X$y[ii])
            #' fix boundary glitches
            if(any(uhoh <- is.na(values)))
              values[uhoh] <- safelookup(covariate.k, X[ii][uhoh])
          }
          ZX[ii] <- values
        }
        #' restrict covariate images to window 
        Z <- solapply(covariate, "[", i=W, drop=FALSE)
        if(!is.null(Wfull)) Zfull <- solapply(covariate, "[", i=Wfull, drop=FALSE)
        #' extract pixel locations and pixel values
        Zframes <- lapply(Z, as.data.frame)
        #' covariate values at each pixel inside window
        Zvalues <- unlist(lapply(Zframes, getElement, name="value"))
        #' pixel locations 
        locn <- lapply(Zframes, getxy)
        #' tack on mark values
        for(k in seq_along(possmarks))
          locn[[k]] <- cbind(locn[[k]], data.frame(marks=possmarks[k]))
        loc <- do.call(rbind, locn)
        #' pixel areas
        pixelarea <- rep(sapply(Z, pixarea), sapply(Z, npixdefined))
      } else if(is.function(covariate)) {
        type <- "function"
        #' evaluate exactly at data points
        ZX <- functioncaller(x=X$x, y=X$y, m=marx, f=covariate, ...)
        #' functioncaller: function(x,y,m,f,...) { f(x,y,m,...) }
        #' same window
        W <- as.mask(W)
        #' covariate in window
        Z <- list()
        for(k in seq_along(possmarks))
          Z[[k]] <- as.im(functioncaller, m=possmarks[k], f=covariate, W=W, ...)
        Zvalues <- unlist(lapply(Z, pixelvalues))
        #' covariate in original window, for prediction
        if(!is.null(Wfull)) {
          Zfull <- list()
          for(k in seq_along(possmarks))
            Zfull[[k]] <- as.im(functioncaller, m=possmarks[k], f=covariate, W=Wfull, ...)
        }
        #' collapse function body to single string
        covname <- singlestring(covname)
        #' pixel areas
        pixelarea <- rep(sapply(Z, pixarea), sapply(Z, npixdefined))
      } else if(is.null(covariate)) {
        stop("The covariate is NULL", call.=FALSE)
      } else stop(paste("For a multitype point process model,",
                        "the covariate should be an image, a list of images,",
                        "a function(x,y,m)", 
                        "or one of the characters",
                        sQuote("x"), "or", sQuote("y")),
                  call.=FALSE)
    }    
    #' ..........................................................

    #' apply jittering to avoid ties
    if(jitter) {
      ZX <- jitter(ZX, factor=jitterfactor)
      Zvalues <- jitter(Zvalues, factor=jitterfactor)
    }

    check.finite(lambda, xname="the fitted intensity", usergiven=FALSE)
    check.finite(Zvalues, xname="the covariate", usergiven=TRUE)
    if(length(lambda) != length(Zvalues))
      stop("Internal error: length(lambda) != length(Zvalues)")

    #' lambda values at data points
    lambdaX <- predict(model, locations=X)

    #' lambda image(s)
    lambdaimage <- predict(model, locations=Wfull %orifnull% W)
    
    #' wrap up 
    values <- list(Zimage      = Zfull %orifnull% Z,
                   lambdaimage = lambdaimage,
                   Zvalues     = Zvalues,
                   lambda      = lambda,
                   lambdaX     = lambdaX,
                   weights     = pixelarea,
                   ZX          = ZX,
                   type        = type)
    return(list(values=values, info=info, X=X)) # X is possibly a subset of original
  }

  xcoordfun <- function(x,y,m){x}
  ycoordfun <- function(x,y,m){y}

  pixarea <- function(z) { z$xstep * z$ystep }
  npixdefined <- function(z) { sum(!is.na(z$v)) }
  pixelvalues <- function(z) { as.data.frame(z)[,3L] }
  getxy <- function(z) { z[,c("x","y")] }

  ## Function caller used for marked locations (x,y,m) only.
  functioncaller <- function(x,y,m,f,...) {
    nf <- length(names(formals(f)))
    if(nf < 2) stop("Covariate function must have at least 2 arguments")
    if(nf == 2) return(f(x,y))
    if(nf == 3) return(f(x,y,m))
    argh <- list(...)
    extra <- intersect(names(argh),
                       names(formals(f))[-(1:3)])
    value <- do.call(f, append(list(x,y,m), argh[extra]))
    return(value)
  }
            
  spatialCovariateEvidence.exactppm
})

