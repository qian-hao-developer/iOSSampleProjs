//
//  Simulator.h
//  Decode
//
//  Created by nekonosukiyaki on 14/11/27.
//  Copyright (c) 2014年 nekonosukiyaki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Simulator : NSObject

@property (nonatomic,copy)      NSString    *text;
@property (nonatomic,assign)    Byte        start_bin;
@property (nonatomic,assign)    Byte        end_bin;
@property (nonatomic,assign)    Byte        *text_bin;
@property (nonatomic,assign)    double      pre_trigger;
@property (nonatomic,assign)    double      pre_trigger1;
@property (nonatomic,assign)    double      pre_trigger2;
@property (nonatomic,assign)    int         s_loop;
@property (nonatomic,assign)    int         t1_loop;
@property (nonatomic,assign)    int         t2_loop;
@property (nonatomic,assign)    int         e_loop;
@property (nonatomic,assign)    int         c_trigger;
@property (nonatomic,assign)    int         n_trigger;
@property (nonatomic,assign)    int         bit;
@property (nonatomic,assign)    BOOL        isParaStart;
@property (nonatomic,assign)    BOOL        canPrintOut;

- (id)init;

- (void)judge:(double *)spectrum :(double)threshold;
- (int *)changeBit:(double *)spectrum :(double)threshold;
- (Byte)exChangeBit:(int *)data;

- (NSString *)textBox:(Byte *)text_bin :(int)bit;

- (void)dealloc;

@end
