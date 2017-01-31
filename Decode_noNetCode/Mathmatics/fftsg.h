//
//  fftsg.h
//  Decode
//
//  Created by nekonosukiyaki on 14/11/27.
//  Copyright (c) 2014年 nekonosukiyaki. All rights reserved.
//

#ifndef __Decode__fftsg__
#define __Decode__fftsg__

#include <stdio.h>
#include <math.h>

void makewt(int nw, int *ip, double *w);
void makect(int nc, int *ip, double *c);
void bitrv2(int n, int *ip, double *a);
void bitrv2conj(int n, int *ip, double *a);
void cftfsub(int n, double *a, double *w);
void cftbsub(int n, double *a, double *w);
void cft1st(int n, double *a, double *w);
void cftmdl(int n, int l, double *a, double *w);
void rftfsub(int n, double *a, int nc, double *c);
void rftbsub(int n, double *a, int nc, double *c);
void dctsub(int n, double *a, int nc, double *c);
void dstsub(int n, double *a, int nc, double *c);

#endif /* defined(__Decode__fftsg__) */
