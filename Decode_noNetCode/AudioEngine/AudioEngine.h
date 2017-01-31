//
//  AudioEngine.h
//  Decode_noNetCode
//
//  Created by nekonosukiyaki on 14/12/18.
//  Copyright (c) 2014年 nekonosukiyaki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <Block.h>

FOUNDATION_EXTERN void CheckError(OSStatus error, const char *operation);

typedef void (^AudioEngineInputBlock)(SInt16 *data, UInt32 numFrames, UInt32 numChannels);

@interface AudioEngine : NSObject 

@property (nonatomic, copy) NSString *inputRoute;

@property (nonatomic, assign, readonly) AudioUnit inputUnit;
@property (nonatomic, assign, readonly) AudioBufferList *inputBuffer;
@property (nonatomic, assign, readonly) BOOL inputAvailable;
@property (nonatomic, assign, readonly) UInt32 numInputChannels;
@property (nonatomic, assign, readonly) Float64 samplingRate;
@property (nonatomic, assign, readonly) BOOL isInterleaved;
@property (nonatomic, assign, readonly) UInt32 numBytesPerSample;
@property (nonatomic, assign, readonly) AudioStreamBasicDescription inputFormat;
@property (nonatomic, assign, readonly) AudioStreamBasicDescription outputFormat;
@property (nonatomic, assign, readonly) BOOL playing;

// ---------------------- create block method ---------------------------------
// TODO: using block to output ioData to user interface

@property (nonatomic, copy) AudioEngineInputBlock inputBlock;
- (void)setInputBlock:(AudioEngineInputBlock)block;

// ----------------------------------------------------------------------------

+ (AudioEngine *)audioEngine;

- (void)play;
- (void)pause;

- (void)checkSessionProperties;
- (void)checkAudioSource;



@end
