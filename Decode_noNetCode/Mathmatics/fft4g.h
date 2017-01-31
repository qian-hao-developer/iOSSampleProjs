//
//  fft4g.h
//  Decode
//
//  Created by nekonosukiyaki on 14/11/27.
//  Copyright (c) 2014年 nekonosukiyaki. All rights reserved.
//

#ifndef __Decode__fft4g__
#define __Decode__fft4g__

#include <stdio.h>

#include "fftsg.h"


#ifdef __cplusplus
extern "C" {
#endif


void cdft(int n, int isgn, double *a, int *ip, double *w);
void rdft(int n, int isgn, double *a, int *ip, double *w);
void ddct(int n, int isgn, double *a, int *ip, double *w);
void ddst(int n, int isgn, double *a, int *ip, double *w);
void dfct(int n, double *a, double *t, int *ip, double *w);
void dfst(int n, double *a, double *t, int *ip, double *w);
    

#ifdef __cplusplus
}
#endif


#endif /* defined(__Decode__fft4g__) */
