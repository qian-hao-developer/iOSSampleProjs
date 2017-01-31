//
//  fft4g.c
//  Decode
//
//  Created by nekonosukiyaki on 14/11/27.
//  Copyright (c) 2014年 nekonosukiyaki. All rights reserved.
//

#include "fft4g.h"

/*
 Fast Fourier/Cosine/Sine Transform
 dimension   :one
 data length :power of 2
 decimation  :frequency
 radix       :4, 2
 data        :inplace
 table       :use
 functions
 cdft: Complex Discrete Fourier Transform
 rdft: Real Discrete Fourier Transform
 ddct: Discrete Cosine Transform
 ddst: Discrete Sine Transform
 dfct: Cosine Transform of RDFT (Real Symmetric DFT)
 dfst: Sine Transform of RDFT (Real Anti-symmetric DFT)
 function prototypes
 void cdft(int, int, double *, int *, double *);
 void rdft(int, int, double *, int *, double *);
 void ddct(int, int, double *, int *, double *);
 void ddst(int, int, double *, int *, double *);
 void dfct(int, double *, double *, int *, double *);
 void dfst(int, double *, double *, int *, double *);
 
 
 -------- Complex DFT (Discrete Fourier Transform) --------
 [definition]
 <case1>
 X[k] = sum_j=0^n-1 x[j]*exp(2*pi*i*j*k/n), 0<=k<n
 <case2>
 X[k] = sum_j=0^n-1 x[j]*exp(-2*pi*i*j*k/n), 0<=k<n
 (notes: sum_j=0^n-1 is a summation from j=0 to n-1)
 [usage]
 <case1>
 ip[0] = 0; // first time only
 cdft(2*n, 1, a, ip, w);
 <case2>
 ip[0] = 0; // first time only
 cdft(2*n, -1, a, ip, w);
 [parameters]
 2*n            :data length (int)
 n >= 1, n = power of 2
 a[0...2*n-1]   :input/output data (double *)
 input data
 a[2*j] = Re(x[j]),
 a[2*j+1] = Im(x[j]), 0<=j<n
 output data
 a[2*k] = Re(X[k]),
 a[2*k+1] = Im(X[k]), 0<=k<n
 ip[0...*]      :work area for bit reversal (int *)
 length of ip >= 2+sqrt(n)
 strictly,
 length of ip >=
 2+(1<<(int)(log(n+0.5)/log(2))/2).
 ip[0],ip[1] are pointers of the cos/sin table.
 w[0...n/2-1]   :cos/sin table (double *)
 w[],ip[] are initialized if ip[0] == 0.
 [remark]
 Inverse of
 cdft(2*n, -1, a, ip, w);
 is
 cdft(2*n, 1, a, ip, w);
 for (j = 0; j <= 2 * n - 1; j++) {
 a[j] *= 1.0 / n;
 }
 .
 
 
 -------- Real DFT / Inverse of Real DFT --------
 [definition]
 <case1> RDFT
 R[k] = sum_j=0^n-1 a[j]*cos(2*pi*j*k/n), 0<=k<=n/2
 I[k] = sum_j=0^n-1 a[j]*sin(2*pi*j*k/n), 0<k<n/2
 <case2> IRDFT (excluding scale)
 a[k] = (R[0] + R[n/2]*cos(pi*k))/2 +
 sum_j=1^n/2-1 R[j]*cos(2*pi*j*k/n) +
 sum_j=1^n/2-1 I[j]*sin(2*pi*j*k/n), 0<=k<n
 [usage]
 <case1>
 ip[0] = 0; // first time only
 rdft(n, 1, a, ip, w);
 <case2>
 ip[0] = 0; // first time only
 rdft(n, -1, a, ip, w);
 [parameters]
 n              :data length (int)
 n >= 2, n = power of 2
 a[0...n-1]     :input/output data (double *)
 <case1>
 output data
 a[2*k] = R[k], 0<=k<n/2
 a[2*k+1] = I[k], 0<k<n/2
 a[1] = R[n/2]
 <case2>
 input data
 a[2*j] = R[j], 0<=j<n/2
 a[2*j+1] = I[j], 0<j<n/2
 a[1] = R[n/2]
 ip[0...*]      :work area for bit reversal (int *)
 length of ip >= 2+sqrt(n/2)
 strictly,
 length of ip >=
 2+(1<<(int)(log(n/2+0.5)/log(2))/2).
 ip[0],ip[1] are pointers of the cos/sin table.
 w[0...n/2-1]   :cos/sin table (double *)
 w[],ip[] are initialized if ip[0] == 0.
 [remark]
 Inverse of
 rdft(n, 1, a, ip, w);
 is
 rdft(n, -1, a, ip, w);
 for (j = 0; j <= n - 1; j++) {
 a[j] *= 2.0 / n;
 }
 .
 
 
 -------- DCT (Discrete Cosine Transform) / Inverse of DCT --------
 [definition]
 <case1> IDCT (excluding scale)
 C[k] = sum_j=0^n-1 a[j]*cos(pi*j*(k+1/2)/n), 0<=k<n
 <case2> DCT
 C[k] = sum_j=0^n-1 a[j]*cos(pi*(j+1/2)*k/n), 0<=k<n
 [usage]
 <case1>
 ip[0] = 0; // first time only
 ddct(n, 1, a, ip, w);
 <case2>
 ip[0] = 0; // first time only
 ddct(n, -1, a, ip, w);
 [parameters]
 n              :data length (int)
 n >= 2, n = power of 2
 a[0...n-1]     :input/output data (double *)
 output data
 a[k] = C[k], 0<=k<n
 ip[0...*]      :work area for bit reversal (int *)
 length of ip >= 2+sqrt(n/2)
 strictly,
 length of ip >=
 2+(1<<(int)(log(n/2+0.5)/log(2))/2).
 ip[0],ip[1] are pointers of the cos/sin table.
 w[0...n*5/4-1] :cos/sin table (double *)
 w[],ip[] are initialized if ip[0] == 0.
 [remark]
 Inverse of
 ddct(n, -1, a, ip, w);
 is
 a[0] *= 0.5;
 ddct(n, 1, a, ip, w);
 for (j = 0; j <= n - 1; j++) {
 a[j] *= 2.0 / n;
 }
 .
 
 
 -------- DST (Discrete Sine Transform) / Inverse of DST --------
 [definition]
 <case1> IDST (excluding scale)
 S[k] = sum_j=1^n A[j]*sin(pi*j*(k+1/2)/n), 0<=k<n
 <case2> DST
 S[k] = sum_j=0^n-1 a[j]*sin(pi*(j+1/2)*k/n), 0<k<=n
 [usage]
 <case1>
 ip[0] = 0; // first time only
 ddst(n, 1, a, ip, w);
 <case2>
 ip[0] = 0; // first time only
 ddst(n, -1, a, ip, w);
 [parameters]
 n              :data length (int)
 n >= 2, n = power of 2
 a[0...n-1]     :input/output data (double *)
 <case1>
 input data
 a[j] = A[j], 0<j<n
 a[0] = A[n]
 output data
 a[k] = S[k], 0<=k<n
 <case2>
 output data
 a[k] = S[k], 0<k<n
 a[0] = S[n]
 ip[0...*]      :work area for bit reversal (int *)
 length of ip >= 2+sqrt(n/2)
 strictly,
 length of ip >=
 2+(1<<(int)(log(n/2+0.5)/log(2))/2).
 ip[0],ip[1] are pointers of the cos/sin table.
 w[0...n*5/4-1] :cos/sin table (double *)
 w[],ip[] are initialized if ip[0] == 0.
 [remark]
 Inverse of
 ddst(n, -1, a, ip, w);
 is
 a[0] *= 0.5;
 ddst(n, 1, a, ip, w);
 for (j = 0; j <= n - 1; j++) {
 a[j] *= 2.0 / n;
 }
 .
 
 
 -------- Cosine Transform of RDFT (Real Symmetric DFT) --------
 [definition]
 C[k] = sum_j=0^n a[j]*cos(pi*j*k/n), 0<=k<=n
 [usage]
 ip[0] = 0; // first time only
 dfct(n, a, t, ip, w);
 [parameters]
 n              :data length - 1 (int)
 n >= 2, n = power of 2
 a[0...n]       :input/output data (double *)
 output data
 a[k] = C[k], 0<=k<=n
 t[0...n/2]     :work area (double *)
 ip[0...*]      :work area for bit reversal (int *)
 length of ip >= 2+sqrt(n/4)
 strictly,
 length of ip >=
 2+(1<<(int)(log(n/4+0.5)/log(2))/2).
 ip[0],ip[1] are pointers of the cos/sin table.
 w[0...n*5/8-1] :cos/sin table (double *)
 w[],ip[] are initialized if ip[0] == 0.
 [remark]
 Inverse of
 a[0] *= 0.5;
 a[n] *= 0.5;
 dfct(n, a, t, ip, w);
 is
 a[0] *= 0.5;
 a[n] *= 0.5;
 dfct(n, a, t, ip, w);
 for (j = 0; j <= n; j++) {
 a[j] *= 2.0 / n;
 }
 .
 
 
 -------- Sine Transform of RDFT (Real Anti-symmetric DFT) --------
 [definition]
 S[k] = sum_j=1^n-1 a[j]*sin(pi*j*k/n), 0<k<n
 [usage]
 ip[0] = 0; // first time only
 dfst(n, a, t, ip, w);
 [parameters]
 n              :data length + 1 (int)
 n >= 2, n = power of 2
 a[0...n-1]     :input/output data (double *)
 output data
 a[k] = S[k], 0<k<n
 (a[0] is used for work area)
 t[0...n/2-1]   :work area (double *)
 ip[0...*]      :work area for bit reversal (int *)
 length of ip >= 2+sqrt(n/4)
 strictly,
 length of ip >=
 2+(1<<(int)(log(n/4+0.5)/log(2))/2).
 ip[0],ip[1] are pointers of the cos/sin table.
 w[0...n*5/8-1] :cos/sin table (double *)
 w[],ip[] are initialized if ip[0] == 0.
 [remark]
 Inverse of
 dfst(n, a, t, ip, w);
 is
 dfst(n, a, t, ip, w);
 for (j = 1; j <= n - 1; j++) {
 a[j] *= 2.0 / n;
 }
 .
 
 
 Appendix :
 The cos/sin table is recalculated when the larger table required.
 w[] and ip[] are compatible with all routines.
 */


void cdft(int n, int isgn, double *a, int *ip, double *w)
{
    void makewt(int nw, int *ip, double *w);
    void bitrv2(int n, int *ip, double *a);
    void bitrv2conj(int n, int *ip, double *a);
    void cftfsub(int n, double *a, double *w);
    void cftbsub(int n, double *a, double *w);
    
    if (n > (ip[0] << 2)) {
        makewt(n >> 2, ip, w);
    }
    if (n > 4) {
        if (isgn >= 0) {
            bitrv2(n, ip + 2, a);
            cftfsub(n, a, w);
        } else {
            bitrv2conj(n, ip + 2, a);
            cftbsub(n, a, w);
        }
    } else if (n == 4) {
        cftfsub(n, a, w);
    }
}


void rdft(int n, int isgn, double *a, int *ip, double *w)
{
    void makewt(int nw, int *ip, double *w);
    void makect(int nc, int *ip, double *c);
    void bitrv2(int n, int *ip, double *a);
    void cftfsub(int n, double *a, double *w);
    void cftbsub(int n, double *a, double *w);
    void rftfsub(int n, double *a, int nc, double *c);
    void rftbsub(int n, double *a, int nc, double *c);
    int nw, nc;
    double xi;
    
    nw = ip[0];
    if (n > (nw << 2)) {
        nw = n >> 2;
        makewt(nw, ip, w);
    }
    nc = ip[1];
    if (n > (nc << 2)) {
        nc = n >> 2;
        makect(nc, ip, w + nw);
    }
    if (isgn >= 0) {
        if (n > 4) {
            bitrv2(n, ip + 2, a);
            cftfsub(n, a, w);
            rftfsub(n, a, nc, w + nw);
        } else if (n == 4) {
            cftfsub(n, a, w);
        }
        xi = a[0] - a[1];
        a[0] += a[1];
        a[1] = xi;
    } else {
        a[1] = 0.5 * (a[0] - a[1]);
        a[0] -= a[1];
        if (n > 4) {
            rftbsub(n, a, nc, w + nw);
            bitrv2(n, ip + 2, a);
            cftbsub(n, a, w);
        } else if (n == 4) {
            cftfsub(n, a, w);
        }
    }
}


void ddct(int n, int isgn, double *a, int *ip, double *w)
{
    void makewt(int nw, int *ip, double *w);
    void makect(int nc, int *ip, double *c);
    void bitrv2(int n, int *ip, double *a);
    void cftfsub(int n, double *a, double *w);
    void cftbsub(int n, double *a, double *w);
    void rftfsub(int n, double *a, int nc, double *c);
    void rftbsub(int n, double *a, int nc, double *c);
    void dctsub(int n, double *a, int nc, double *c);
    int j, nw, nc;
    double xr;
    
    nw = ip[0];
    if (n > (nw << 2)) {
        nw = n >> 2;
        makewt(nw, ip, w);
    }
    nc = ip[1];
    if (n > nc) {
        nc = n;
        makect(nc, ip, w + nw);
    }
    if (isgn < 0) {
        xr = a[n - 1];
        for (j = n - 2; j >= 2; j -= 2) {
            a[j + 1] = a[j] - a[j - 1];
            a[j] += a[j - 1];
        }
        a[1] = a[0] - xr;
        a[0] += xr;
        if (n > 4) {
            rftbsub(n, a, nc, w + nw);
            bitrv2(n, ip + 2, a);
            cftbsub(n, a, w);
        } else if (n == 4) {
            cftfsub(n, a, w);
        }
    }
    dctsub(n, a, nc, w + nw);
    if (isgn >= 0) {
        if (n > 4) {
            bitrv2(n, ip + 2, a);
            cftfsub(n, a, w);
            rftfsub(n, a, nc, w + nw);
        } else if (n == 4) {
            cftfsub(n, a, w);
        }
        xr = a[0] - a[1];
        a[0] += a[1];
        for (j = 2; j < n; j += 2) {
            a[j - 1] = a[j] - a[j + 1];
            a[j] += a[j + 1];
        }
        a[n - 1] = xr;
    }
}


void ddst(int n, int isgn, double *a, int *ip, double *w)
{
    void makewt(int nw, int *ip, double *w);
    void makect(int nc, int *ip, double *c);
    void bitrv2(int n, int *ip, double *a);
    void cftfsub(int n, double *a, double *w);
    void cftbsub(int n, double *a, double *w);
    void rftfsub(int n, double *a, int nc, double *c);
    void rftbsub(int n, double *a, int nc, double *c);
    void dstsub(int n, double *a, int nc, double *c);
    int j, nw, nc;
    double xr;
    
    nw = ip[0];
    if (n > (nw << 2)) {
        nw = n >> 2;
        makewt(nw, ip, w);
    }
    nc = ip[1];
    if (n > nc) {
        nc = n;
        makect(nc, ip, w + nw);
    }
    if (isgn < 0) {
        xr = a[n - 1];
        for (j = n - 2; j >= 2; j -= 2) {
            a[j + 1] = -a[j] - a[j - 1];
            a[j] -= a[j - 1];
        }
        a[1] = a[0] + xr;
        a[0] -= xr;
        if (n > 4) {
            rftbsub(n, a, nc, w + nw);
            bitrv2(n, ip + 2, a);
            cftbsub(n, a, w);
        } else if (n == 4) {
            cftfsub(n, a, w);
        }
    }
    dstsub(n, a, nc, w + nw);
    if (isgn >= 0) {
        if (n > 4) {
            bitrv2(n, ip + 2, a);
            cftfsub(n, a, w);
            rftfsub(n, a, nc, w + nw);
        } else if (n == 4) {
            cftfsub(n, a, w);
        }
        xr = a[0] - a[1];
        a[0] += a[1];
        for (j = 2; j < n; j += 2) {
            a[j - 1] = -a[j] - a[j + 1];
            a[j] -= a[j + 1];
        }
        a[n - 1] = -xr;
    }
}


void dfct(int n, double *a, double *t, int *ip, double *w)
{
    void makewt(int nw, int *ip, double *w);
    void makect(int nc, int *ip, double *c);
    void bitrv2(int n, int *ip, double *a);
    void cftfsub(int n, double *a, double *w);
    void rftfsub(int n, double *a, int nc, double *c);
    void dctsub(int n, double *a, int nc, double *c);
    int j, k, l, m, mh, nw, nc;
    double xr, xi, yr, yi;
    
    nw = ip[0];
    if (n > (nw << 3)) {
        nw = n >> 3;
        makewt(nw, ip, w);
    }
    nc = ip[1];
    if (n > (nc << 1)) {
        nc = n >> 1;
        makect(nc, ip, w + nw);
    }
    m = n >> 1;
    yi = a[m];
    xi = a[0] + a[n];
    a[0] -= a[n];
    t[0] = xi - yi;
    t[m] = xi + yi;
    if (n > 2) {
        mh = m >> 1;
        for (j = 1; j < mh; j++) {
            k = m - j;
            xr = a[j] - a[n - j];
            xi = a[j] + a[n - j];
            yr = a[k] - a[n - k];
            yi = a[k] + a[n - k];
            a[j] = xr;
            a[k] = yr;
            t[j] = xi - yi;
            t[k] = xi + yi;
        }
        t[mh] = a[mh] + a[n - mh];
        a[mh] -= a[n - mh];
        dctsub(m, a, nc, w + nw);
        if (m > 4) {
            bitrv2(m, ip + 2, a);
            cftfsub(m, a, w);
            rftfsub(m, a, nc, w + nw);
        } else if (m == 4) {
            cftfsub(m, a, w);
        }
        a[n - 1] = a[0] - a[1];
        a[1] = a[0] + a[1];
        for (j = m - 2; j >= 2; j -= 2) {
            a[2 * j + 1] = a[j] + a[j + 1];
            a[2 * j - 1] = a[j] - a[j + 1];
        }
        l = 2;
        m = mh;
        while (m >= 2) {
            dctsub(m, t, nc, w + nw);
            if (m > 4) {
                bitrv2(m, ip + 2, t);
                cftfsub(m, t, w);
                rftfsub(m, t, nc, w + nw);
            } else if (m == 4) {
                cftfsub(m, t, w);
            }
            a[n - l] = t[0] - t[1];
            a[l] = t[0] + t[1];
            k = 0;
            for (j = 2; j < m; j += 2) {
                k += l << 2;
                a[k - l] = t[j] - t[j + 1];
                a[k + l] = t[j] + t[j + 1];
            }
            l <<= 1;
            mh = m >> 1;
            for (j = 0; j < mh; j++) {
                k = m - j;
                t[j] = t[m + k] - t[m + j];
                t[k] = t[m + k] + t[m + j];
            }
            t[mh] = t[m + mh];
            m = mh;
        }
        a[l] = t[0];
        a[n] = t[2] - t[1];
        a[0] = t[2] + t[1];
    } else {
        a[1] = a[0];
        a[2] = t[0];
        a[0] = t[1];
    }
}


void dfst(int n, double *a, double *t, int *ip, double *w)
{
    void makewt(int nw, int *ip, double *w);
    void makect(int nc, int *ip, double *c);
    void bitrv2(int n, int *ip, double *a);
    void cftfsub(int n, double *a, double *w);
    void rftfsub(int n, double *a, int nc, double *c);
    void dstsub(int n, double *a, int nc, double *c);
    int j, k, l, m, mh, nw, nc;
    double xr, xi, yr, yi;
    
    nw = ip[0];
    if (n > (nw << 3)) {
        nw = n >> 3;
        makewt(nw, ip, w);
    }
    nc = ip[1];
    if (n > (nc << 1)) {
        nc = n >> 1;
        makect(nc, ip, w + nw);
    }
    if (n > 2) {
        m = n >> 1;
        mh = m >> 1;
        for (j = 1; j < mh; j++) {
            k = m - j;
            xr = a[j] + a[n - j];
            xi = a[j] - a[n - j];
            yr = a[k] + a[n - k];
            yi = a[k] - a[n - k];
            a[j] = xr;
            a[k] = yr;
            t[j] = xi + yi;
            t[k] = xi - yi;
        }
        t[0] = a[mh] - a[n - mh];
        a[mh] += a[n - mh];
        a[0] = a[m];
        dstsub(m, a, nc, w + nw);
        if (m > 4) {
            bitrv2(m, ip + 2, a);
            cftfsub(m, a, w);
            rftfsub(m, a, nc, w + nw);
        } else if (m == 4) {
            cftfsub(m, a, w);
        }
        a[n - 1] = a[1] - a[0];
        a[1] = a[0] + a[1];
        for (j = m - 2; j >= 2; j -= 2) {
            a[2 * j + 1] = a[j] - a[j + 1];
            a[2 * j - 1] = -a[j] - a[j + 1];
        }
        l = 2;
        m = mh;
        while (m >= 2) {
            dstsub(m, t, nc, w + nw);
            if (m > 4) {
                bitrv2(m, ip + 2, t);
                cftfsub(m, t, w);
                rftfsub(m, t, nc, w + nw);
            } else if (m == 4) {
                cftfsub(m, t, w);
            }
            a[n - l] = t[1] - t[0];
            a[l] = t[0] + t[1];
            k = 0;
            for (j = 2; j < m; j += 2) {
                k += l << 2;
                a[k - l] = -t[j] - t[j + 1];
                a[k + l] = t[j] - t[j + 1];
            }
            l <<= 1;
            mh = m >> 1;
            for (j = 1; j < mh; j++) {
                k = m - j;
                t[j] = t[m + k] + t[m + j];
                t[k] = t[m + k] - t[m + j];
            }
            t[0] = t[m + mh];
            m = mh;
        }
        a[l] = t[0];
    }
    a[0] = 0;
}



