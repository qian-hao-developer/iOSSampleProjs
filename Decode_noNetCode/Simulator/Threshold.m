//
//  Threshold.m
//  Decode
//
//  Created by nekonosukiyaki on 14/11/27.
//  Copyright (c) 2014年 nekonosukiyaki. All rights reserved.
//

#import "Threshold.h"

@implementation Threshold

#pragma mark 初期化
- (id)initWithTrig:(double)trig1 :(double)trig2 :(double)mul {
    if (self == [super init]) {
        _trig1 = trig1;
        _trig2 = trig2;
        _deviation = fabsf(trig1 - trig2);
        _mul = mul;
        return self;
    }
    return nil;
}

#pragma mark 閾値の計算
- (void)calThresByT12 {
    if (_trig1 > _trig2) {
        _threshold = _trig2 + _deviation * _mul;
    }
    else {
        _threshold = _trig1 + _deviation * _mul;
    }
}

- (void)calThresByIREF {
    if (_trig1 > _trig2) {
        _threshold = _trig1 * _mul;
    }
    else {
        _threshold = _trig2 * _mul;
    }
}

- (void)calThresByAvg:(double)spec1 :(double)spec2 :(double)spec3 :(double)db {
    _threshold = (spec1 + spec2 + spec3) / 3 + db;
}

#pragma mark 判断
- (BOOL)isJoint {
    if (_deviation < 25) {
        return YES;
    }
    return NO;
}

- (BOOL)isWhiteNoise {
    if (_threshold < 50) {
        return YES;
    }
    return NO;
}

- (BOOL)isWrongTrig {
    if (_trig1 > _threshold && _trig2 > _threshold) {
        return YES;
    }
    return NO;
}

- (void)dealloc {
    [super dealloc];
}

@end
