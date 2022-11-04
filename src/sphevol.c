#include <math.h>
#include <R.h>
#include "geom3.h"
/*

	$Revision: 1.3 $ 	$Date: 2022/10/22 02:32:10 $

	Routine for calculating ABSOLUTE volume of intersection 
	between sphere and box

	Arbitrary positions: point is allowed to be inside or outside box.

# /////////////////////////////////////////////
# AUTHOR: Adrian Baddeley, CWI, Amsterdam, 1991.
# 
# MODIFIED BY: Adrian Baddeley, Perth 2009
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


#ifdef DEBUG
#define DBG(X,Y) Rprintf("%s: %f\n", (X), (Y));
#else
#define DBG(X,Y) 
#endif

#include "yesno.h"
#define ABS(X) ((X >= 0.0) ? (X) : -(X))

static	double	rcubed, spherevol;

double
sphevol(
  Point *point,
  Box *box,
  double r
) {
	double sum, p[4], q[4];
	int i, j;

	double v1(double a, int s, double r);
	double v2(double a, int sa, double b, int sb, double r);
	double v3(double a, int sa, double b, int sb, double c, int sc, double r);

	rcubed = r * r * r;
	spherevol = (4.0/3.0) * PI * rcubed;

	p[1] = box->x0 - point->x;
	p[2] = box->y0 - point->y;
	p[3] = box->z0 - point->z;

	q[1] = box->x1 - point->x;
	q[2] = box->y1 - point->y;
	q[3] = box->z1 - point->z;

	sum = 0;

	for(i = 1; i <= 3; i++)
	{
		sum += v1(p[i], -1, r) + v1(q[i], 1, r);
#ifdef DEBUG
		Rprintf("i = %d, v1 = %f, v1 = %f\n", i, v1(p[i], -1, r), v1(q[i], 1, r));
#endif
	}
	DBG("Past v1", sum)
	
	for(i = 1; i < 3; i++)
		for(j = i+1; j <= 3; j++)
		{
			sum -= v2(p[i], -1, p[j], -1, r) + v2(p[i], -1, q[j], 1, r)
			 + v2(q[i], 1, p[j], -1, r) + v2(q[i], 1, q[j], 1, r);
#ifdef DEBUG
			Rprintf("i = %d, j = %d, sum = %f\n", i, j, sum);
#endif
		}
	DBG("Past v2", sum)

	sum += v3(p[1], -1, p[2], -1, p[3], -1, r) 
		+ v3(p[1], -1, p[2], -1, q[3], 1, r);

	DBG("sum", sum)

	sum += v3(p[1], -1, q[2], 1, p[3], -1, r) 
		+ v3(p[1], -1, q[2], 1, q[3], 1, r);

	DBG("sum", sum)

	sum += v3(q[1], 1, p[2], -1, p[3], -1, r) 
		+ v3(q[1], 1, p[2], -1, q[3], 1, r);

	DBG("sum", sum)

	sum += v3(q[1], 1, q[2], 1, p[3], -1, r) 
		+ v3(q[1], 1, q[2], 1, q[3], 1, r);

	DBG("Past v3", sum)
	DBG("sphere volume", spherevol)

	return(spherevol - sum);
}

double
v1(double a, int s, double r)
{
	double value;
	short sign;

	double u(double a, double b, double c);
  
	value = 4.0 * rcubed * u(ABS(a)/r, 0.0, 0.0);

	sign = (a >= 0.0) ? 1 : -1;

	if(sign == s)
		return(value);
	else
		return(spherevol - value);
}
		
double
v2(double a, int sa, double b, int sb, double r)
{
	short sign;
	double u(double a, double b, double c);
	
	sign = (b >= 0.0) ? 1 : -1;

	if(sign != sb )
		return(v1(a, sa, r) - v2(a, sa, ABS(b), 1, r));

	b = ABS(b);
	sb = 1;

	sign = (a >= 0.0) ? 1 : -1;
	
	if(sign != sa)
		return(v1(b, sb, r) - v2(ABS(a), 1, b, sb, r));

	a = ABS(a);

	return(2.0 * rcubed * u(a/r, b/r, 0.0));
}
	
double
v3(double a, int sa, double b, int sb, double c, int sc, double r)
{
	short sign;
	double u(double a, double b, double c);
	
	sign = (c >= 0.0) ? 1 : -1;

	if(sign != sc)
		return(v2(a,sa,b,sb,r) - v3(a,sa,b,sb, ABS(c), 1, r));

	c = ABS(c);
	sc = 1;

	sign = (b >= 0.0) ? 1 : -1;

	if(sign != sb)
		return(v2(a,sa,c,sc,r) - v3(a,sa,ABS(b),1,c,sc,r));

	b = ABS(b);
	sb = 1;

	sign = (a >= 0.0) ? 1 : -1;

	if(sign != sa)
		return(v2(b,sb, c, sc, r) - v3(ABS(a),1, b, sb, c, sc, r));

	a = ABS(a);

	return(rcubed * u(a/r, b/r, c/r));
}
	
double
u(double a, double b, double c)
{
	double w(double x, double y);
	
	if(a * a + b * b + c * c >= 1.0)
		return(0.0);

	return(
		(PI/12.0) * (2.0 - 3.0 * (a + b + c)
			  	+ (a * a * a + b * b * b + c * c * c))

		+ w(a,b) + w(b,c) + w(a,c)
		- a * b * c
	);
}
	

double 
w(double x, double y) 	/* Arguments assumed >= 0 */
{
	double z;

	z = sqrt(1 - x * x - y * y);

	return(
	  (x / 2.0 - x * x * x / 6.0) * atan2(y, z)
	+ (y / 2.0 - y * y * y / 6.0) * atan2(x, z)
	- ( atan2(x * y , z) - x * y * z )/3.0
	);
}