#
#   pairs.im.R
#
#   $Revision: 1.24 $   $Date: 2025/07/03 00:55:53 $
#

pairs.listof <- pairs.solist <- function(..., plot=TRUE) {
  argh <- expandSpecialLists(list(...), special=c("solist", "listof"))
  names(argh) <- good.names(names(argh), "V", seq_along(argh))
  haslines <- any(sapply(argh, inherits, what="linim"))
  if(haslines) {
    if(!requireNamespace("spatstat.linnet")) {
      warning(paste("the pairs() plot for images on a linear network",
                    "requires the package 'spatstat.linnet'"),
              call.=FALSE)
      return(NULL)
    }
    do.call(spatstat.linnet::pairs.linim, append(argh, list(plot=plot)))
  } else {
    do.call(pairs.im, append(argh, list(plot=plot)))
  }
}

pairs.im <- local({

  allpixelvalues <- function(Z) { as.numeric(as.matrix(Z)) }
  
  pairs.im <- function(..., plot=TRUE, drop=TRUE) {
    argh <- list(...)
    cl <- match.call()
    ## unpack single argument which is a list of images
    if(length(argh) == 1) {
      arg1 <- argh[[1]]
      if(is.list(arg1) && all(unlist(lapply(arg1, is.im))))
        argh <- arg1
    }
    ## identify which arguments are images
    isim <- unlist(lapply(argh, is.im))
    nim <- sum(isim)
    if(nim == 0) 
      stop("No images provided")
    ## separate image arguments from others
    imlist <- argh[isim]
    rest   <- argh[!isim]
    ## determine image names for plotting
    imnames <- argh$labels %orifnull% names(imlist)
    if(length(imnames) != nim || !all(nzchar(imnames))) {
      #' names not given explicitly
      callednames <- paste(cl)[c(FALSE, isim, FALSE)]
      backupnames <- paste0("V", seq_len(nim))
      if(length(callednames) != nim) {
        callednames <- backupnames
      } else if(any(toolong <- (nchar(callednames) > 15))) {
        callednames[toolong] <- backupnames[toolong]
      }
      imnames <- good.names(imnames, good.names(callednames, backupnames))
    }
    ## 
    if(nim == 1) {
      ## one image: plot histogram
      Z <- imlist[[1L]]
      xname <- imnames[1L]
      do.call(hist,
              resolve.defaults(list(x=quote(Z), plot=plot),
                               rest, 
                               list(xlab=xname,
                                    main=paste("Histogram of", xname))))
      ## save pixel values
      pixvals <- list(allpixelvalues(Z))
      names(pixvals) <- xname
    } else {
      ## extract pixel rasters and reconcile them
      imwins <- solapply(imlist, as.owin)
      names(imwins) <- NULL
      rasta    <- do.call(intersect.owin, imwins)
      ## convert images to common raster
      imlist <- lapply(imlist, "[.im", i=rasta, raster=rasta, drop=FALSE)
      ## extract pixel values
      pixvals <- lapply(imlist, allpixelvalues)
    }
    ## combine into data frame
    pixdf <- do.call(data.frame, pixvals)
    ## remove NA's
    if(drop) 
      pixdf <- pixdf[complete.cases(pixdf), , drop=FALSE]
    ## pairs plot
    if(plot && nim > 1)
      do.call(pairs, resolve.defaults(list(x=quote(pixdf)),
                                      rest,
                                      list(labels=imnames, pch=".")))
    labels <- resolve.defaults(rest, list(labels=imnames))$labels
    colnames(pixdf) <- labels
    class(pixdf) <- c("plotpairsim", class(pixdf))
    return(invisible(pixdf))
  }

  pairs.im
})


plot.plotpairsim <- function(x, ...) {
  xname <- short.deparse(substitute(x))
  x <- as.data.frame(x)
  if(ncol(x) == 1) {
    x <- x[,1L]
    do.call(hist.default,
            resolve.defaults(list(x=quote(x)),
                             list(...),
                             list(main=xname, xlab=xname)))
  } else {
    do.call(pairs.default,
            resolve.defaults(list(x=quote(x)),
                             list(...),
                             list(pch=".")))
  }
  return(invisible(NULL))
}

print.plotpairsim <- function(x, ...) {
  cat("Object of class plotpairsim\n")
  cat(paste("contains pixel data for", commasep(sQuote(colnames(x))), "\n"))
  return(invisible(NULL))
}

panel.image <- function(x, y, ..., sigma=NULL) {
  opa <- par(usr = c(0, 1, 0, 1))
  on.exit(par(opa))
  xx <- scaletointerval(x)
  yy <- scaletointerval(y)
  p <- ppp(xx, yy, window=square(1), check=FALSE)
  plot(density(p, sigma=sigma), add=TRUE, ...)
}

panel.contour <- function(x, y, ..., sigma=NULL) {
  opa <- par(usr = c(0, 1, 0, 1))
  on.exit(par(opa))
  xx <- scaletointerval(x)
  yy <- scaletointerval(y)
  p <- ppp(xx, yy, window=square(1), check=FALSE)
  Z <- density(p, sigma=sigma)
  dont.complain.about(Z)
  do.call(contour,
          resolve.defaults(list(x=quote(Z), add=TRUE),
                           list(...),
                           list(drawlabels=FALSE)))
}

panel.histogram <- function(x, ...) {
  usr <- par("usr")
  opa <- par(usr = c(usr[1:2], 0, 1.5) )
  on.exit(par(opa))
  h <- hist(x, plot = FALSE)
  breaks <- h$breaks; nB <- length(breaks)
  y <- h$counts; y <- y/max(y)
  do.call(rect,
          resolve.defaults(list(xleft   = breaks[-nB],
                                ybottom = 0,
                                xright  = breaks[-1],
                                ytop    = y),
                           list(...),
                           list(col="grey")))
}


## pairwise things like correlations

cov.im <- function(..., use = "complete.obs",
                   method = c("pearson", "kendall", "spearman")) {
  df <- pairs.im(..., plot=FALSE, drop=FALSE)
  V <- cov(df, use=use, method=method)
  return(V)
}  

cor.im <- function(..., use = "complete.obs",
                   method = c("pearson", "kendall", "spearman")) {
  df <- pairs.im(..., plot=FALSE, drop=FALSE)
  R <- cor(df, use=use, method=method)
  return(R)
}  
