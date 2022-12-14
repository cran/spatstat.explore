#
#	Ksector.R	Estimation of 'sector K function'
#
#	$Revision: 1.7 $	$Date: 2022/06/27 07:37:57 $
#

Ksector <- function(X, begin=0, end=360, ...,
                    units=c("degrees", "radians"),
                    r=NULL, breaks=NULL, 
                    correction=c("border", "isotropic", "Ripley", "translate"),
                    domain = NULL,
                    ratio=FALSE, verbose=TRUE)
{
  verifyclass(X, "ppp")
#  rfixed <- !is.null(r) || !is.null(breaks)
  npts <- npoints(X)
  W <- Window(X)
  areaW <- area(W)
  lambda <- npts/areaW
  npairs <- npts * (npts - 1)
  lambda2 <- npairs/(areaW^2)
  rmaxdefault <- rmax.rule("K", W, lambda)        
  breaks <- handle.r.b.args(r, breaks, W, rmaxdefault=rmaxdefault)
  r <- breaks$r
  rmax <- breaks$max
  
  if(!is.null(domain)) {
    domain <- as.owin(domain)
    stopifnot(is.subset.owin(domain, Window(X)))
    areaW <- area(domain)
  }

  units <- match.arg(units)
  switch(units,
         radians = {
           if(missing(end)) end <- 2 * pi
           check.1.real(begin)
           check.1.real(end)
           check.in.range(begin, c(-pi, 2*pi))
           check.in.range(end, c(0, 2*pi))
           stopifnot(begin < end)
           stopifnot((end - begin) <= 2 * pi)
           BEGIN <- begin
           END   <- end
           Bname <- simplenumber(begin/pi, "pi") %orifnull% signif(begin, 3)
           Ename <- simplenumber(end/pi, "pi") %orifnull% signif(end, 3)
         },
         degrees = {
           check.1.real(begin)
           check.1.real(end)
           check.in.range(begin, c(-90, 360))
           check.in.range(end, c(0, 360))
           stopifnot(begin < end)
           stopifnot((end - begin) <= 360)
           if(verbose && (end - begin) <= 2 * pi)
             warning("Very small interval in degrees: did you mean radians?")
           BEGIN <- pi* (begin/180)
           END   <- pi * (end/180)
           Bname <- signif(begin, 3)
           Ename <- signif(end, 3)
         })
  ## choose correction(s)
  correction.given <- !missing(correction) && !is.null(correction)
  if(is.null(correction))
    correction <- c("border", "isotropic", "Ripley", "translate")
  correction <- pickoption("correction", correction,
                           c(none="none",
                             border="border",
                             "bord.modif"="bord.modif",
                             isotropic="isotropic",
                             Ripley="isotropic",
                             trans="translate",
                             translate="translate",
                             translation="translate",
                             good="good",
                             best="best"),
                           multi=TRUE)
#  best.wanted <- ("best" %in% correction)
  ## replace 'good' by the optimal choice for this size of dataset
  if("good" %in% correction)
    correction[correction == "good"] <- good.correction.K(X)
  ## retain only corrections that are implemented for the window
  correction <- implemented.for.K(correction, W$type, correction.given)
  
  ## recommended range of r values
  alim <- c(0, min(rmax, rmaxdefault))

  ## labels
  subscripts <- paste("sector", Bname, Ename, sep=",")
  ylabel <- paste("K[", subscripts, "]")
  ylab <-  eval(parse(text=paste("quote(", ylabel, ")")))
#  ylab <-  parse(text=paste("K[sector,", Bname, ",", Ename, "]"))
#  yexp <- substitute(K[list(sector,B,E)](r),
#                     list(B=Bname, E=Ename))
  yexp <-  parse(text=paste("K[list(", subscripts, ")]"))
  fname <- c("K", paste("list", paren(subscripts)))
  
  ## this will be the output data frame
  Kdf <- data.frame(r=r, theo = ((END-BEGIN)/2) * r^2)
  desc <- c("distance argument r", "theoretical Poisson %s")
  denom <- npairs
  K <- ratfv(Kdf, NULL, denom,
             "r",
             ylab = ylab,
             valu = "theo",
             fmla = NULL,
             alim = alim,
             labl = c("r","{%s[%s]^{pois}}(r)"),
             desc = desc,
             fname=fname, yexp=yexp, 
             ratio=ratio)
  
  ## identify all close pairs
  rmax <- max(r)
  close <- as.data.frame(closepairs(X, rmax))

  if(!is.null(domain)) {
    ## restrict to pairs with first point in 'domain'
    indom <- with(close, inside.owin(xi, yi, domain))
    close <- close[indom, , drop=FALSE]
  }

  ## select pairs in angular range
  ang <- with(close, atan2(dy, dx)) %% (2*pi)
  if(BEGIN >= 0) {
    ## 0 <= begin < end
    ok <- (BEGIN <= ang) & (ang <= END)
  } else {
    ## begin < 0 <= end
    ok <- (ang >= 2 * pi + BEGIN) | (ang <= END)
  }
  close <- close[ok, , drop=FALSE]

  ## pairwise distances
  DIJ <- close$d

  if(any(correction == "none")) {
    # uncorrected! For demonstration purposes only!
    wh <- whist(DIJ, breaks$val)  # no weights
    Kun <- cumsum(wh)/(lambda2 * areaW)
    # uncorrected estimate of K
    K <- bind.ratfv(K,
                    quotient    = data.frame(un=Kun),
                    denominator = npairs,
                    labl        = "{hat(%s)[%s]^{un}}(r)",
                    desc        = "uncorrected estimate of %s",
                    preferred   = "un",
                    ratio=ratio)
  }
  
  if(any(correction == "border" | correction == "bord.modif")) {
  # border method
  # Compute distances to boundary
    b <- bdist.points(X)
    I <- close$i
    bI <- b[I]
    if(!is.null(domain))
      b <- b[inside.owin(X, , w=domain)]
  # apply reduced sample algorithm
    RS <- Kount(DIJ, bI, b, breaks)
    if(any(correction == "bord.modif")) {
      # modified border correction
      denom.area <- eroded.areas(W, r, subset=domain)
      Kbm <- RS$numerator/(lambda2 * denom.area)
      K <- bind.ratfv(K,
                      quotient    = data.frame(bord.modif=Kbm),
                      denominator = lambda2 * areaW * denom.area,
                      labl        = "{hat(%s)[%s]^{bordm}}(r)",
                      desc        = "modified border-corrected estimate of %s",
                      preferred   = "bord.modif",
                      ratio=ratio)
    }
    if(any(correction == "border")) {
      Kb <- RS$numerator/(lambda * RS$denom.count)
      K <- bind.ratfv(K,
                      quotient    = data.frame(border=Kb), 
                      denominator = npts * RS$denom.count,
                      labl        = "{hat(%s)[%s]^{bord}}(r)",
                      desc        = "border-corrected estimate of %s",
                      preferred   = "border",
                      ratio=ratio)
    }
  }

  if(any(correction == "translate")) {
    ## Ohser-Stoyan translation correction
    edgewt <- edge.Trans(dx=close$dx, dy=close$dy, W=W, paired=TRUE)
    wh <- whist(DIJ, breaks$val, edgewt)
    Ktrans <- cumsum(wh)/(lambda2 * areaW)
    h <- diameter(as.rectangle(W))/2
    Ktrans[r >= h] <- NA
    K <- bind.ratfv(K,
                    quotient    = data.frame(trans=Ktrans),
                    denominator = npairs, 
                    labl        = "{hat(%s)[%s]^{trans}}(r)",
                    desc        = "translation-corrected estimate of %s",
                    preferred   = "trans",
                    ratio=ratio)
  }
  if(any(correction == "isotropic")) {
    ## Ripley isotropic correction
    XI <- ppp(close$xi, close$yi, window=W, check=FALSE)
    edgewt <- edge.Ripley(XI, matrix(DIJ, ncol=1))
    wh <- whist(DIJ, breaks$val, edgewt)
    Kiso <- cumsum(wh)/(lambda2 * areaW)
    h <- diameter(W)/2
    Kiso[r >= h] <- NA
    K <- bind.ratfv(K,
                    quotient    = data.frame(iso=Kiso),
                    denominator = npairs,
                    labl        = "{hat(%s)[%s]^{iso}}(r)",
                    desc        = "Ripley isotropic correction estimate of %s",
                    preferred   = "iso",
                    ratio=ratio)
  }
  #
  # default plot will display all edge corrections
  formula(K) <- . ~ r
  nama <- rev(colnames(K))
  nama <- nama[!(nama %in% c("r", "rip", "ls"))]
  fvnames(K, ".") <- nama
  unitname(K) <- unitname(X)
  # copy to other components
  if(ratio)
    K <- conform.ratfv(K)

  return(K)
}
