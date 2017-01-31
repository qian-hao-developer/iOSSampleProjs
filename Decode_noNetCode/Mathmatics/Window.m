//
//  Window.m
//  Decode
//
//  Created by nekonosukiyaki on 14/11/27.
//  Copyright (c) 2014年 nekonosukiyaki. All rights reserved.
//

#import "Window.h"

#define PI 3.1415926

@implementation Window

- (id)init {
    if (self == [super init]) {
        [self calculate];
        return self;
    }
    return nil;
}

- (void)calculate {
    float *w = (float *)calloc(1024, sizeof(float));
    for (int i=0; i<1024; i++) {
        w[i] = 0.54 - 0.46 * cos(2 * PI * i / 1023);
    }
    self.win = w;
}

@end
