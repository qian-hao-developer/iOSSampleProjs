//
//  ViewController.m
//  Decode_noNetCode
//
//  Created by nekonosukiyaki on 14/12/5.
//  Copyright (c) 2014年 nekonosukiyaki. All rights reserved.
//

#import "ViewController.h"
#define mul 0.7


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _window = [[Window alloc]init];
    _simulator = [[Simulator alloc]init];
    
    _frameData = (double *)calloc(2048, sizeof(double));
    _jointData = (double *)calloc(2048, sizeof(double));
    _spectrum = (double *)calloc(512, sizeof(double));
    
    _isFirstTime = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pushStartBTN:(UIButton *)sender {
    self.audioEngine = [AudioEngine audioEngine];
    [self.audioEngine setInputBlock:^(SInt16 *data, UInt32 numFrames, UInt32 numChannels) {
        
        int *ip = (int *)malloc(sizeof(int) * (2 + sqrt((double)(numFrames*2))));
        double *w = (double *)malloc(sizeof(double) * numFrames);
        ip[0] = 0;
        
        for (int i=0; i<numFrames; i++) {
            _frameData[i<<1] = (double)(data[i] * _window.win[i]);
            _frameData[(i<<1)+1] = 0;
        }
        
        if (_isFirstTime) {
            for (int i=0; i<512; i++) {
                _jointData[i<<1] = (double)(data[i+512] * _window.win[i]);
                _jointData[(i<<1)+1] = 0;
            }
            
            rdft(2048, 1, _frameData, ip, w);
            for (int i=400; i<470; i++) {
                _spectrum[i] = 10*log10(pow(_frameData[i<<1], 2)+pow(_frameData[(i<<1)+1], 2));
            }
            Threshold *thresSim = [[Threshold alloc]initWithTrig:_spectrum[450] :_spectrum[454] :mul];
            [thresSim retain];
            [thresSim calThresByT12];
            
//            NSLog(@"frame");
//            NSLog(@"trig1: %f, trig2: %f, trig3: %f, devia: %f",thresSim.trig1,thresSim.trig2,_spectrum[458],thresSim.deviation);
            
            if (thresSim.isJoint || thresSim.isWhiteNoise || thresSim.isWrongTrig) {
                //
                //thresSim.isWrongTrig
                //do nothing = skip
//                NSLog(@"frame do nothing term");
            }
            else {
                
//                NSLog(@"frame Threshold: %f",thresSim.threshold);
                [_simulator judge:_spectrum :thresSim.threshold];
                if (_simulator.canPrintOut) {
                    NSLog(@"%@",_simulator.text);
                    _simulator.canPrintOut = NO;
                }
            }
            
            [thresSim release];
            thresSim = nil;
            _isFirstTime = NO;
        }
        else {
            for (int i=0; i<512; i++) {
                _jointData[(i+512)<<1] = (double)(data[i] * _window.win[i+512]);
                _jointData[((i+512)<<1)+1] = 0;
            }
            
            // joint part analyze
            rdft(2048, 1, _jointData, ip, w);
            for (int i=400; i<470; i++) {
                _spectrum[i] = 10*log10(pow(_jointData[i<<1], 2)+pow(_jointData[(i<<1)+1], 2));
            }
            Threshold *thresSim = [[Threshold alloc]initWithTrig:_spectrum[450] :_spectrum[454] :mul];
            [thresSim retain];
            [thresSim calThresByT12];
            
//            NSLog(@"joint");
//            NSLog(@"trig1: %f, trig2: %f, trig3: %f, devia: %f",thresSim.trig1,thresSim.trig2,_spectrum[458],thresSim.deviation);
            
            if (thresSim.isJoint || thresSim.isWrongTrig || thresSim.isWhiteNoise) {
                //
                //thresSim.isWrongTrig
                //do nothing
//                NSLog(@"joint do nothing term");
            }
            else {
                
//                NSLog(@"joint Threshold: %f",thresSim.threshold);
                [_simulator judge:_spectrum :thresSim.threshold];
                if (_simulator.canPrintOut) {
                    NSLog(@"%@",_simulator.text);
                    _simulator.canPrintOut = NO;
                }
            }
            
            // frame of 1024 analyze
            ip[0] = 0;
            rdft(2048, 1, _frameData, ip, w);
            for (int i=400; i<470; i++) {
                _spectrum[i] = 10*log10(pow(_frameData[i<<1], 2)+pow(_frameData[(i<<1)+1], 2));
            }
            thresSim = [[Threshold alloc]initWithTrig:_spectrum[450] :_spectrum[454] :mul];
            [thresSim retain];
            [thresSim calThresByT12];
            
//            NSLog(@"frame");
//            NSLog(@"trig1: %f, trig2: %f, trig3: %f, devia: %f",thresSim.trig1,thresSim.trig2,_spectrum[458],thresSim.deviation);
            
            if (thresSim.isJoint || thresSim.isWhiteNoise || thresSim.isWrongTrig) {
                //
                //thresSim.isWrongTrig
                //do nothing = skip
//                NSLog(@"frame do nothing term");
            }
            else {
//                NSLog(@"frame Threshold: %f",thresSim.threshold);
                [_simulator judge:_spectrum :thresSim.threshold];
                if (_simulator.canPrintOut) {
                    NSLog(@"%@",_simulator.text);
                    _simulator.canPrintOut = NO;
                }
            }
            
            [thresSim release];
            thresSim = nil;
            //            [thresSim dealloc];
            
            
            for (int i=0; i<512; i++) {
                _jointData[i<<1] = (double)(data[i+512] * _window.win[i]);
                _jointData[(i<<1)+1] = 0;
            }
        }
        // free
        free(ip);
        free(w);
        
    }];
    
    [self.audioEngine play];
    NSLog(@"start!");
}

- (IBAction)pushStopBTN:(UIButton *)sender {
    if (self.audioEngine.playing) {
        NSLog(@"stop");
        [self.audioEngine pause];
    }
}
@end
