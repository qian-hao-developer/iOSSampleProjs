//
//  Window.h
//  Decode
//
//  Created by nekonosukiyaki on 14/11/27.
//  Copyright (c) 2014年 nekonosukiyaki. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Window : NSObject

@property (nonatomic,assign) float *win;

- (id)init;
- (void)calculate;

@end

