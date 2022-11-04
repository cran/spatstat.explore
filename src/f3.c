#include <math.h>
#include <R.h>
#include <R_ext/Utils.h>
#include "geom3.h"
#include "functable.h"

#ifdef DEBUG
#define DEBUGMESSAGE(S) Rprintf(S);
#else
#define DEBUGMESSAGE(S) 
#endif

/*
	$Revision: 1.4 $	$Date: 2016/10/23 04:24:03 $

	3D distance transform

# /////////////////////////////////////////////
# AUTHOR: Adrian Baddeley, CWI, Amsterdam, 1991.
# 
# MODIFIED BY: Adrian Baddeley, Perth 2009, 2022
# 
# This software is distributed free
# under the conditions that
# 	(1) it shall not be incorporated
# 	in software that is subsequently sold
# 	(2) the authorship of the software shall
# 	be acknowledged in any publication that 
# 	uses results generated by the software
# 	(3) this notice shall remain in place
# 	in each file.
# //////////////////////////////////////////////

*/

	/* step lengths in distance transform */
#define	STEP1 41
#define	STEP2 58
#define	STEP3 71
	/* (41,58,71)/41 is a good rational approximation
	   to (1, sqrt(2), sqrt(3))	 */


#define MIN(X,Y) (((X) < (Y)) ? (X) : (Y))
#define MAX(X,Y) (((X) > (Y)) ? (X) : (Y))

typedef struct IntImage {
	int	*data;
	int	Mx, My, Mz;	/* dimensions */
	int	length;
} IntImage;

typedef struct BinaryImage {
	unsigned char *data;
	int	Mx, My, Mz;	/* dimensions */
	int	length;
} BinaryImage;
	
#define VALUE(I,X,Y,Z) \
	((I).data)[ (Z) * ((I).Mx) * ((I).My) + (Y) * ((I).Mx)  + (X) ]


void
allocBinImage(
  BinaryImage	*b,
  int		*ok
) {
  b->length = b->Mx * b->My * b->Mz;
  b->data = (unsigned char *) 
    R_alloc(b->length, sizeof(unsigned char));

  if(b->data == 0) {
    Rprintf("Can't allocate memory for %d binary voxels\n", b->length);
    *ok = 0;
  }
  *ok = 1;
}

void
allocIntImage(
  IntImage *v,
  int	  *ok
) {
  v->length = v->Mx * v->My * v->Mz;
  v->data = (int *) R_alloc(v->length, sizeof(int));

  if(v->data == 0) {
    Rprintf("Can't allocate memory for %d integer voxels\n", v->length);
    *ok = 0;
  }
  *ok = 1;
}

void freeBinImage(BinaryImage *b) { }
void freeIntImage(IntImage *v) { }

void
cts2bin(
  /* convert a list of points inside a box
     into a 3D binary image */
  Point	*p,
  int	n,
  Box	*box,
  double vside,	 /* side of a (cubic) voxel */
  BinaryImage *b,
  int	*ok
) {
  int	i, lx, ly, lz;
  unsigned char	*cp;

  b->Mx = (int) ceil((box->x1 - box->x0)/vside) + 1;
  b->My = (int) ceil((box->y1 - box->y0)/vside) + 1;
  b->Mz = (int) ceil((box->z1 - box->z0)/vside) + 1;

  allocBinImage(b, ok);

  if(! (*ok)) return;

  for(i = b->length, cp = b->data; i ; i--, cp++)
    *cp = 1;

  for(i=0;i<n;i++) {
    lx = (int) ceil((p[i].x - box->x0)/vside)-1;
    ly = (int) ceil((p[i].y - box->y0)/vside)-1;
    lz = (int) ceil((p[i].z - box->z0)/vside)-1;
    
    if( lx >= 0 && lx < b->Mx 
	&& ly >= 0 && ly < b->My 
	&& lz >= 0 && lz < b->Mz 
	) 
      VALUE((*b),lx,ly,lz) = 0;
  }
}

void
distrans3(
  /* Distance transform in 3D */
  BinaryImage *b,		/* input */
  IntImage    *v,		/* output */
  int	    *ok
) {
  register int x, y, z;
  int infinity, q;

  /* allocate v same size as b */
  v->Mx = b->Mx;
  v->My = b->My;
  v->Mz = b->Mz;

  allocIntImage(v, ok);
  if(! (*ok)) return;

  /* compute largest possible distance */
  infinity = (int) ceil( ((double) STEP3) * 
			 sqrt(
			      ((double) b->Mx) * b->Mx 
			      + ((double) b->My) * b->My 
			      + ((double) b->Mz) * b->Mz));

  /* Forward pass: Top to Bottom; Back to Front; Left to Right. */

  for(z=0;z<b->Mz;z++) {
    R_CheckUserInterrupt();
    for(y=0;y<b->My;y++) {
      for(x=0;x<b->Mx;x++) {
	if(VALUE((*b),x,y,z) == 0)
	  VALUE((*v),x,y,z) = 0;
	else {
	  q = infinity;

#define INTERVAL(W, DW, MW) \
	((DW == 0) || (DW == -1 && W > 0) || (DW == 1 && W < MW - 1))
#define BOX(X,Y,Z,DX,DY,DZ) \
	(INTERVAL(X,DX,v->Mx) && INTERVAL(Y,DY,v->My) && INTERVAL(Z,DZ,v->Mz))
#define TEST(DX,DY,DZ,DV) \
	if(BOX(x,y,z,DX,DY,DZ) && q > VALUE((*v),x+DX,y+DY,z+DZ) + DV) \
		q = VALUE((*v),x+DX,y+DY,z+DZ) + DV 

	  /* same row */
	  TEST(-1, 0, 0, STEP1);

	  /* same plane */
	  TEST(-1,-1, 0, STEP2);
	  TEST( 0,-1, 0, STEP1);
	  TEST( 1,-1, 0, STEP2);

	  /* previous plane */
	  TEST( 1, 1,-1, STEP3);
	  TEST( 0, 1,-1, STEP2);
	  TEST(-1, 1,-1, STEP3);

	  TEST( 1, 0,-1, STEP2);
	  TEST( 0, 0,-1, STEP1);
	  TEST(-1, 0,-1, STEP2);

	  TEST( 1,-1,-1, STEP3);
	  TEST( 0,-1,-1, STEP2);
	  TEST(-1,-1,-1, STEP3);

	  VALUE((*v),x,y,z) = q;
	}
      }
    }
  }


	/* Backward pass: Bottom to Top; Front to Back; Right to Left. */

  for(z = b->Mz - 1; z >= 0; z--) {
    R_CheckUserInterrupt();
    for(y = b->My - 1; y >= 0; y--) {
      for(x = b->Mx - 1; x >= 0; x--) {
	if((q = VALUE((*v),x,y,z)) != 0)
	{
	  /* same row */
	  TEST(1, 0, 0, STEP1);

	  /* same plane */
	  TEST(-1, 1, 0, STEP2);
	  TEST( 0, 1, 0, STEP1);
	  TEST( 1, 1, 0, STEP2);

	  /* plane below */
	  TEST( 1, 1, 1, STEP3);
	  TEST( 0, 1, 1, STEP2);
	  TEST(-1, 1, 1, STEP3);

	  TEST( 1, 0, 1, STEP2);
	  TEST( 0, 0, 1, STEP1);
	  TEST(-1, 0, 1, STEP2);

	  TEST( 1,-1, 1, STEP3);
	  TEST( 0,-1, 1, STEP2);
	  TEST(-1,-1, 1, STEP3);

	  VALUE((*v),x,y,z) = q;
	}
      }
    }
  }
}

void
hist3d(
 /* compute histogram of all values in *v
    using count->n histogram cells 
    ranging from count->t0 to count->t1 
    and put results in count->num
 */
  IntImage *v,
  double   vside,
  Itable  *count
) {
  register int i, j, k; 
  register int *ip;
  register double scale, width;

  /* relationship between distance transform units
     and physical units */
  scale = vside/STEP1;
  width = (count->t1 - count->t0)/(count->n - 1);

  for(i = 0; i < count->n ; i++) {
    (count->num)[i] = 0;
    (count->denom)[i] = v->length;
  }

  for(i = v->length, ip = v->data; i; i--, ip++) {
    
    k = (int) ceil((*ip * scale - count->t0)/width);
    k = MAX(k, 0);

    for(j = k; j < count->n; j++)
      (count->num)[j]++;
  }
}	

void
hist3dminus(	/* minus sampling */
  IntImage *v,
  double   vside,
  Itable   *count
) {
  register int x, y, z, val, border, bx, by, bz, byz, j, kbord, kval;
  register double scale, width;

  DEBUGMESSAGE("inside hist3dminus\n")

  scale = vside/STEP1;
  width = (count->t1 - count->t0)/(count->n - 1);

  /* table is assumed to have been initialised in MakeItable */

  for(z = 0; z < v->Mz; z++) {
    bz = MIN(z + 1, v->Mz - z);
    for(y = 0; y < v->My; y++) {
      by = MIN(y + 1, v->My - y);
      byz = MIN(by, bz);
      for(x = 0; x < v->Mx; x++) {
	bx = MIN(x + 1, v->My - x);
	border = MIN(bx, byz);

	kbord = (int) floor((vside * border - count->t0)/width);
	kbord = MIN(kbord, count->n - 1);

	/* denominator counts all voxels with 
	   distance to boundary >= r */
	if(kbord >= 0)
	  for(j = 0; j <= kbord; j++)
	    (count->denom)[j]++;

	val = VALUE((*v), x, y, z);
	kval = (int) ceil((val * scale - count->t0)/width);
	kval = MAX(kval, 0);

#ifdef DEBUG
	/*
	Rprintf("border=%lf\tkbord=%d\tval=%lf\tkval=%d\n", 
		vside * border, kbord, scale * val, kval);
	*/
#endif

	  /* numerator counts all voxels with
	     distance to boundary >= r
	     and distance to nearest point <= r
	  */
	if(kval <= kbord)
	  for(j = kval; j <= kbord; j++)
	    (count->num)[j]++;
	  
      }
    }
  }
  DEBUGMESSAGE("leaving hist3dminus\n")
}	

void
hist3dCen(      /* four censoring-related histograms */
  IntImage *v,
  double   vside,
  H4table  *count
) {
  register int x, y, z, val, border, bx, by, bz, byz, kbord, kval;
  register double scale, width, realborder, realval;

  DEBUGMESSAGE("inside hist3dCen\n")

  scale = vside/STEP1;
  width = (count->t1 - count->t0)/(count->n - 1);

  /* table is assumed to have been initialised in MakeH4table */

  for(z = 0; z < v->Mz; z++) {

    bz = MIN(z + 1, v->Mz - z);

    for(y = 0; y < v->My; y++) {

      by = MIN(y + 1, v->My - y);
      byz = MIN(by, bz);

      for(x = 0; x < v->Mx; x++) {

	bx = MIN(x + 1, v->My - x);
	border = MIN(bx, byz);
	realborder = vside * border;

	kbord = (int) floor((realborder - count->t0)/width);

	val = VALUE((*v), x, y, z);
	realval = scale * val;

	kval = (int) ceil((realval - count->t0)/width);
	/* this could exceed array limits; that will be detected below */

#ifdef DEBUG
	Rprintf("border=%lf\tkbord=%d\tval=%lf\tkval=%d\n", 
		realborder, kbord, realval, kval);
#endif

	if(realval <= realborder) {
	  /* observation is uncensored; 
             increment all four histograms */
	  if(kval >= count->n)
	    ++(count->upperobs);
	  else if(kval >= 0) {
	      (count->obs)[kval]++;
	      (count->nco)[kval]++;
	  }
	  if(kbord >= count->n)
	    ++(count->uppercen);
	  else if(kbord >= 0) {
	      (count->cen)[kbord]++;
	      (count->ncc)[kbord]++;
	  }
	} else {
	  /* observation is censored; 
             increment only two histograms */
	  kval = MIN(kval, kbord);
	  if(kval >= count->n)
	    ++(count->upperobs);
	  else if(kval >= 0) 
	    (count->obs)[kval]++;

	  if(kbord >= count->n)
	    ++(count->uppercen);
	  else if(kbord >= 0) 
	    (count->cen)[kbord]++;
	}
      }
    }
  }
  DEBUGMESSAGE("leaving hist3dCen\n")
}

/*
	CALLING ROUTINES 
*/

void
phatminus(
  Point	*p,
  int	n,
  Box	*box,
  double vside,
  Itable *count
) {
  BinaryImage	b;
  IntImage	v;
  int		ok;

  DEBUGMESSAGE("in phatminus\ncalling cts2bin...")
  cts2bin(p, n, box, vside, &b, &ok);
  DEBUGMESSAGE("out of cts2bin\ninto distrans3...")
  if(ok) 
    distrans3(&b, &v, &ok);

  if(ok) {
    freeBinImage(&b);
    DEBUGMESSAGE("out of distrans3\ninto hist3dminus...")
    hist3dminus(&v, vside, count);
    DEBUGMESSAGE("out of hist3dminus\n")
    freeIntImage(&v);
  }
}

void
phatnaive(
  Point	*p,
  int	n,
  Box	*box,
  double vside,
  Itable *count
) {
  BinaryImage	b;
  IntImage	v;
  int		ok;

  DEBUGMESSAGE("in phatnaive\ncalling cts2bin...")
  cts2bin(p, n, box, vside, &b, &ok);
  DEBUGMESSAGE("out of cts2bin\n into distrans3...")
  if(ok)
    distrans3(&b, &v, &ok);
  if(ok) {
    freeBinImage(&b);
    DEBUGMESSAGE("out of distrans3\ninto hist3d..."); 
    hist3d(&v, vside, count);
    DEBUGMESSAGE("out of hist3d\n")
    freeIntImage(&v);
  }
}

void
p3hat4(
  Point	*p,
  int	n,
  Box	*box,
  double vside,
  H4table *count
) {
  BinaryImage	b;
  IntImage	v;
  int		ok;

  DEBUGMESSAGE("in phatminus\ncalling cts2bin...")
  cts2bin(p, n, box, vside, &b, &ok);
  DEBUGMESSAGE("out of cts2bin\ninto distrans3...")
  if(ok) 
    distrans3(&b, &v, &ok);

  if(ok) {
    freeBinImage(&b);
    DEBUGMESSAGE("out of distrans3\ninto hist3dminus...")
    hist3dCen(&v, vside, count);
    DEBUGMESSAGE("out of hist3dminus\n")
    freeIntImage(&v);
  }
}
