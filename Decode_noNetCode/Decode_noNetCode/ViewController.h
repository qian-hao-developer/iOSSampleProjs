//
//  ViewController.h
//  Decode_noNetCode
//
//  Created by nekonosukiyaki on 14/12/5.
//  Copyright (c) 2014年 nekonosukiyaki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "fft4g.h"
#import "Window.h"
#import "Simulator.h"
#import "Threshold.h"
#import "AudioEngine.h"

@interface ViewController : UIViewController

@property (nonatomic, assign) AudioEngine *audioEngine;
@property (nonatomic, assign)    double      *frameData;
@property (nonatomic, assign)    double      *jointData;
@property (nonatomic, assign)    double      *spectrum;
@property (nonatomic, assign)    BOOL        isFirstTime;

@property (nonatomic, assign) Window *window;
@property (nonatomic, assign) Simulator *simulator;


- (IBAction)pushStartBTN:(UIButton *)sender;
- (IBAction)pushStopBTN:(UIButton *)sender;

@end

