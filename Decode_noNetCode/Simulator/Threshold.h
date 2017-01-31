//
//  Threshold.h
//  Decode
//
//  Created by nekonosukiyaki on 14/11/27.
//  Copyright (c) 2014年 nekonosukiyaki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Threshold : NSObject

@property (nonatomic,assign) double threshold;
@property (nonatomic,assign) double deviation;
@property (nonatomic,assign) double trig1;
@property (nonatomic,assign) double trig2;
@property (nonatomic,assign) double mul;

- (id)initWithTrig:(double)trig1 :(double)trig2 :(double)mul;

- (void)calThresByT12;
- (void)calThresByIREF;
- (void)calThresByAvg:(double)spec1 :(double)spec2 :(double)spec3 :(double)db;

- (BOOL)isJoint;
- (BOOL)isWhiteNoise;
- (BOOL)isWrongTrig;

- (void)dealloc;

@end
