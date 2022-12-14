#
#     eval.fv.R
#
#
#        eval.fv()             Evaluate expressions involving fv objects
#
#        compatible.fv()       Check whether two fv objects are compatible
#
#     $Revision: 1.42 $     $Date: 2022/01/04 05:30:06 $
#

eval.fv <- local({

  # main function
  eval.fv <- function(expr, envir, dotonly=TRUE, equiv=NULL, relabel=TRUE) {
    # convert syntactic expression to 'expression' object
    e <- as.expression(substitute(expr))
    # convert syntactic expression to call
    elang <- substitute(expr)
    # find names of all variables in the expression
    varnames <- all.vars(e)
    if(length(varnames) == 0)
      stop("No variables in this expression")
    # get the actual variables
    if(missing(envir)) {
      envir <- parent.frame()
    } else if(is.list(envir)) {
      envir <- list2env(envir, parent=parent.frame())
    }
    vars <- lapply(as.list(varnames), get, envir=envir)
    names(vars) <- varnames
    # find out which ones are fv objects
    fvs <- unlist(lapply(vars, is.fv))
    nfuns <- sum(fvs)
    if(nfuns == 0)
      stop("No fv objects in this expression")
    # extract them
    funs <- vars[fvs]
    # restrict to columns identified by 'dotnames'
    if(dotonly) 
      funs <- lapply(funs, restrict.to.dot)
    # map names if instructed
    if(!is.null(equiv))
      funs <- lapply(funs, mapnames, map=equiv)
    # test whether the fv objects are compatible
    if(nfuns > 1L && !(do.call(compatible, unname(funs)))) {
      warning(paste(if(nfuns > 2) "some of" else NULL,
                    "the functions",
                    commasep(sQuote(names(funs))),
                    "were not compatible: enforcing compatibility"))
      funs <- do.call(harmonise, append(funs, list(strict=TRUE)))
    }
    # copy first object as template
    result <- funs[[1L]]
    ## ensure 'conservation' info is retained
    conserve <- unname(lapply(funs, attr, which="conserve"))
    if(any(present <- !sapply(conserve, is.null))) {
      conserve <- do.call(resolve.defaults, conserve[present])
      attr(result, "conserve") <- conserve
    }
    ## remove potential ratio info
    class(result) <- setdiff(class(result), "rat")
    attr(result, "numerator") <- attr(result, "denominator") <- NULL
    labl <- attr(result, "labl")
    origdotnames   <- fvnames(result, ".")
    origshadenames <- fvnames(result, ".s")
    # determine which function estimates are supplied
    argname <- fvnames(result, ".x")
    nam <- names(result)
    ynames <- nam[nam != argname]
    # for each function estimate, evaluate expression
    for(yn in ynames) {
      # extract corresponding estimates from each fv object
      funvalues <- lapply(funs, "[[", i=yn)
      # insert into list of argument values
      vars[fvs] <- funvalues
      # evaluate
      result[[yn]] <- eval(e, vars, enclos=envir)
    }
    if(!relabel)
      return(result)
    # determine mathematical labels.
    # 'yexp' determines y axis label
    # 'ylab' determines y label in printing and description
    # 'fname' is sprintf-ed into 'labl' for legend
    yexps <- lapply(funs, attr, which="yexp")
    ylabs <- lapply(funs, attr, which="ylab")
    fnames <- lapply(funs, getfname)
    # Repair 'fname' attributes if blank
    blank <- unlist(lapply(fnames, isblank))
    if(any(blank)) {
      # Set function names to be object names as used in the expression
      for(i in which(blank))
        attr(funs[[i]], "fname") <- fnames[[i]] <- names(funs)[i]
    }
    # Remove duplicated names
    # Typically occurs when combining several K functions, etc.
    # Tweak fv objects so their function names are their object names
    # as used in the expression
    if(anyDuplicated(fnames)) {
      newfnames <- names(funs)
      for(i in 1:nfuns)
        funs[[i]] <- rebadge.fv(funs[[i]], new.fname=newfnames[i])
      fnames <- newfnames
    }
    if(anyDuplicated(ylabs)) {
      flatnames <- lapply(funs, flatfname)
      for(i in 1:nfuns) {
        new.ylab <- substitute(f(r), list(f=flatnames[[i]]))
        funs[[i]] <- rebadge.fv(funs[[i]], new.ylab=new.ylab)
      }
      ylabs <- lapply(funs, attr, which="ylab")
    }
    if(anyDuplicated(yexps)) {
      newfnames <- names(funs)
      for(i in 1:nfuns) {
        new.yexp <- substitute(f(r), list(f=as.name(newfnames[i])))
        funs[[i]] <- rebadge.fv(funs[[i]], new.yexp=new.yexp)
      }
      yexps <- lapply(funs, attr, which="yexp")
    }
    # now compute y axis labels for the result
    attr(result, "yexp") <- eval(substitute(substitute(e, yexps),
                                            list(e=elang)))
    attr(result, "ylab") <- eval(substitute(substitute(e, ylabs),
                                            list(e=elang)))
    # compute fname equivalent to expression
    if(nfuns > 1L) {
      # take original expression
      the.fname <- paren(flatten(deparse(elang)))
    } else if(nzchar(oldname <- flatfname(funs[[1L]]))) {
      # replace object name in expression by its function name
      namemap <- list(as.name(oldname)) 
      names(namemap) <- names(funs)[1L]
      the.fname <- deparse(eval(substitute(substitute(e, namemap),
                                           list(e=elang))))
    } else the.fname <- names(funs)[1L]
    attr(result, "fname") <- the.fname
    # now compute the [modified] y labels
    labelmaps <- lapply(funs, fvlabelmap, dot=FALSE)
    for(yn in ynames) {
      # labels for corresponding columns of each argument
      funlabels <- lapply(labelmaps, "[[", i=yn)
      # form expression involving these columns
      labl[match(yn, names(result))] <-
        flatten(deparse(eval(substitute(substitute(e, f),
                                        list(e=elang, f=funlabels)))))
    }
    attr(result, "labl") <- labl
    # copy dotnames and shade names from template
    fvnames(result, ".") <- origdotnames[origdotnames %in% names(result)]
    if(!is.null(origshadenames) && all(origshadenames %in% names(result)))
      fvnames(result, ".s") <- origshadenames
    return(result)
  }

  # helper functions
  restrict.to.dot <- function(z) {
    argu <- fvnames(z, ".x")
    dotn <- fvnames(z, ".")
    shadn <- fvnames(z, ".s")
    ok <- colnames(z) %in% unique(c(argu, dotn, shadn))
    return(z[, ok])
  }
  getfname <- function(x) { if(!is.null(y <- attr(x, "fname"))) y else "" }
  flatten <- function(x) { paste(x, collapse=" ") }
  mapnames <- function(x, map=NULL) {
    colnames(x) <- mapstrings(colnames(x), map=map)
    fvnames(x, ".y") <- mapstrings(fvnames(x, ".y"), map=map)
    return(x)
  }
  isblank <-  function(z) { !any(nzchar(z)) }
  
  eval.fv
})
    
compatible.fv <- local({

  approx.equal <- function(x, y) { max(abs(x-y)) <= .Machine$double.eps }

  compatible.fv <- function(A, B, ..., samenames=TRUE) {
    verifyclass(A, "fv")
    if(missing(B)) {
      answer <- if(length(...) == 0) TRUE else compatible(A, ...)
      return(answer)
    }
    verifyclass(B, "fv")
    ## is the function argument the same?
    samearg <- (fvnames(A, ".x") == fvnames(B, ".x"))
    if(!samearg)
      return(FALSE)
    if(samenames) {
      ## are all columns the same, and in the same order?
      namesmatch <- isTRUE(all.equal(names(A),names(B))) &&
                    samearg &&
                    (fvnames(A, ".y") == fvnames(B, ".y"))
      if(!namesmatch)
        return(FALSE)
    }
    ## are 'r' values the same ?
    rA <- with(A, .x)
    rB <- with(B, .x)
    rmatch <- (length(rA) == length(rB)) && approx.equal(rA, rB)
    if(!rmatch)
      return(FALSE)
    ## A and B are compatible
    if(length(list(...)) == 0)
      return(TRUE)
    ## recursion
    return(compatible.fv(B, ...))
  }

  compatible.fv
})


# force a list of functions to be compatible with regard to 'x' values

harmonize.fv <- harmonise.fv <- local({

  harmonise.fv <- function(..., strict=FALSE) {
    argh <- list(...)
    n <- length(argh)
    if(n == 0) return(argh)
    if(n == 1) {
      a1 <- argh[[1L]]
      if(is.fv(a1)) return(argh)
      if(is.list(a1) && all(sapply(a1, is.fv))) {
        argh <- a1
        n <- length(argh)
      }
    }
    isfv <- sapply(argh, is.fv)
    if(!all(isfv))
      stop("All arguments must be fv objects")
    if(n == 1) return(argh[[1L]])
    ## determine range of argument
    ranges <- lapply(argh, argumentrange)
    xrange <- c(max(unlist(lapply(ranges, min))),
                min(unlist(lapply(ranges, max))))
    if(diff(xrange) < 0)
      stop("No overlap in ranges of argument")
    if(strict) {
      ## find common column names and keep these
      keepnames <- Reduce(intersect, lapply(argh, colnames))
      argh <- lapply(argh, "[", j=keepnames)
    }
    ## determine finest resolution
    xsteps <- sapply(argh, argumentstep)
    finest <- which.min(xsteps)
    ## extract argument values
    xx <- with(argh[[finest]], .x)
    xx <- xx[xrange[1L] <= xx & xx <= xrange[2L]]
    xrange <- range(xx)
    ## convert each fv object to a function
    funs <- lapply(argh, as.function, value="*")
    ## evaluate at common argument
    result <- vector(mode="list", length=n)
    for(i in 1:n) {
      ai <- argh[[i]]
      fi <- funs[[i]]
      xxval <- list(xx=xx)
      names(xxval) <- fvnames(ai, ".x")
      starnames <- fvnames(ai, "*")
      ## ensure they are given in same order as current columns
      starnames <- colnames(ai)[colnames(ai) %in% starnames]
      yyval <- lapply(starnames,
                      function(v,xx,fi) fi(xx, v),
                      xx=xx, fi=fi)
      names(yyval) <- starnames
      ri <- do.call(data.frame, append(xxval, yyval))
      fva <- .Spatstat.FvAttrib
      attributes(ri)[fva] <- attributes(ai)[fva]
      class(ri) <- c("fv", class(ri))
      attr(ri, "alim") <- intersect.ranges(attr(ai, "alim"), xrange)
      result[[i]] <- ri
    }
    names(result) <- names(argh)
    return(result)
  }

  argumentrange <- function(f) { range(with(f, .x)) }
  
  argumentstep <- function(f) { mean(diff(with(f, .x))) }
  
  harmonise.fv
})

