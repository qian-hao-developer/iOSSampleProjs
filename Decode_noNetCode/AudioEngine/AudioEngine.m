//
//  AudioEngine.m
//  Decode_noNetCode
//
//  Created by nekonosukiyaki on 14/12/18.
//  Copyright (c) 2014年 nekonosukiyaki. All rights reserved.
//

#import "AudioEngine.h"

#define kInputBus 1
#define kOutputBus 0

#pragma mark define a C funtion
#ifdef __cplusplus
extern "C" {
#endif
    
    void CheckError(OSStatus error, const char *operation)
    {
        if (error == noErr) return;
        
        char str[20];
        // see if it appears to be a 4-char-code
        *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
        if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
            str[0] = str[5] = '\'';
            str[6] = '\0';
        } else
            // no, format it as an integer
            sprintf(str, "%d", (int)error);
        
        fprintf(stderr, "Error: %s (%s)\n", operation, str);
        
        exit(1);
    }
    
    OSStatus inputCallback(void *userData,
                           AudioUnitRenderActionFlags *actionFlags,
                           const AudioTimeStamp *audioTimeStamp,
                           UInt32 busNumber,
                           UInt32 numFrames,
                           AudioBufferList *buffers);
    
#ifdef __cplusplus
}
#endif

static AudioEngine *audioEngine = nil;

@interface AudioEngine()

// redeclare redwrite for class continuation
@property (nonatomic, assign, readwrite) AudioUnit inputUnit;
@property (nonatomic, assign, readwrite) AudioBufferList *inputBuffer;
@property (nonatomic, assign, readwrite) BOOL inputAvailable;
@property (nonatomic, assign, readwrite) UInt32 numInputChannels;
@property (nonatomic, assign, readwrite) Float64 samplingRate;
@property (nonatomic, assign, readwrite) BOOL isInterleaved;
@property (nonatomic, assign, readwrite) UInt32 numBytesPerSample;
@property (nonatomic, assign, readwrite) AudioStreamBasicDescription inputFormat;
@property (nonatomic, assign, readwrite) AudioStreamBasicDescription outputFormat;
@property (nonatomic, assign, readwrite) BOOL playing;
@property (nonatomic, assign, readwrite) SInt16 *inData;

// private
//@property (nonatomic, assign, readwrite) float *inData;

- (void)setupAudioSession;
- (void)setupAudioUnits;

- (void)freeBuffers;

@end

@implementation AudioEngine

+ (AudioEngine *)audioEngine {
    @synchronized(self)
    {
        if (audioEngine == nil) {
            audioEngine = [[AudioEngine alloc] init];
        }
    }
    return audioEngine;
}

- (id)init {
    if (self == [super init]) {
        self.inData = (SInt16 *)calloc(8192, sizeof(SInt16));
        
        self.inputBlock = nil;
        
        self.playing = NO;
        
        [self setupAudioSession];
        [self setupAudioUnits];
        
        return self;
    }
    
    return nil;
}

- (void)dealloc {
    free(self.inData);
    [self freeBuffers];
    [super dealloc];
}

- (void)freeBuffers {
    if (self.inputBuffer) {
        for (UInt32 i = 0; i < self.inputBuffer->mNumberBuffers; i++) {
            if (self.inputBuffer->mBuffers[i].mData) {
                free(self.inputBuffer->mBuffers[i].mData);
            }
        }
        
        free(self.inputBuffer);
        self.inputBuffer = NULL;
    }
}

#pragma mark - Audio Methods

- (void)setupAudioSession {
    NSError *err = nil;
    if (![[AVAudioSession sharedInstance] setActive:YES error:&err]) {
        NSLog(@"Couldn't activate audio session: %@", err);
    }
    [self checkAudioSource];
}

- (void)setupAudioUnits {
    
    // ---- Audio Session Setup ----
    // -----------------------------
    
    UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
    CheckError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory), "Couldn't set audio category");
    
    // take 1024 samples every 1 sec , samplingRate is 44100
    Float32 preferredBufferSize = 0.0232;
    CheckError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize), "Couldn't set the preferred buffer duration");
    
    UInt32 overrideCategory = 1;
    CheckError(AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(UInt32), &overrideCategory), "Couldn't override to speaker");
    
    [self checkSessionProperties];
    
    // -----------------------------
    
    
    // ---- Audio Unit Setup ----
    // --------------------------
    
    AudioComponentDescription inputDescription = {0};
    inputDescription.componentType = kAudioUnitType_Output;
    inputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    inputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    inputDescription.componentFlags = 0;
    inputDescription.componentFlagsMask = 0;
    
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &inputDescription);
    CheckError(AudioComponentInstanceNew(inputComponent, &_inputUnit), "Couldn't create the output audio unit");
    
    // Enable input
    UInt32 enable = 1;
    CheckError(AudioUnitSetProperty(_inputUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, kInputBus, &enable, sizeof(enable)), "Couldn't enable IO on the input scope of output unit");
    
    UInt32 size = sizeof(AudioStreamBasicDescription);
    
    // set format to 1 element's input side
    _inputFormat.mSampleRate = 44100;
    _inputFormat.mFormatID = kAudioFormatLinearPCM;
    
//    _inputFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    
    _inputFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
    // signed integer,  sample bits fill with the full channel, non interleaved(2 buffers, each mono), default little endian
    
    _inputFormat.mBitsPerChannel = 16; // linearPCM 16
    _inputFormat.mChannelsPerFrame = 1; // mono
    _inputFormat.mFramesPerPacket = 1; // 1 packet = 1 frame
    _inputFormat.mBytesPerFrame = _inputFormat.mBitsPerChannel / 8 * _inputFormat.mChannelsPerFrame;
    _inputFormat.mBytesPerPacket = _inputFormat.mBytesPerFrame * _inputFormat.mFramesPerPacket;
    _inputFormat.mReserved = 0;
    
    self.samplingRate = _inputFormat.mSampleRate;
    self.numBytesPerSample = _inputFormat.mBitsPerChannel / 8;
    
    
    // 1. try set inputFormat into kInputBus's input side and get outputFormat from kInputBus's output side
    // it should be the same
    // then try to use outputFormat which got recently to pre-malloc inputBuffer and set inputCallback with setting global scope
    //
    // 2. try set outputFormat into kInputBus's output side and set inputFormat into kOutputBus's input side
    // then try to pre-malloc buffer with renderFunction's paramater(numFrame)
    // then use renderCallback with input scope which in kOutputBus
    
    // try 1  remember to disuncomment the try 1 's callback part
    _outputFormat = _inputFormat;
    CheckError(AudioUnitSetProperty(_inputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, kInputBus, &_outputFormat, size), "Couldn't get streamFormat from outputScope of inputBus");
    UInt32 numFramesPerBuffer;
    size = sizeof(UInt32);
    CheckError(AudioUnitGetProperty(_inputUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, kOutputBus, &numFramesPerBuffer, &size), "Couldn't get the number of frames per callback");
    UInt32 bufferSizeBytes = _outputFormat.mBytesPerFrame * _outputFormat.mFramesPerPacket * numFramesPerBuffer;
    if (_outputFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved) {
        printf("Not interleaved!\n");
        self.isInterleaved = NO;
        
        UInt32 propsize = offsetof(AudioBufferList, mBuffers[0]) + (sizeof(AudioBuffer) * _outputFormat.mChannelsPerFrame);
        
        self.inputBuffer = (AudioBufferList *)malloc(propsize);
        self.inputBuffer->mNumberBuffers = _outputFormat.mChannelsPerFrame;
        
        for (UInt32 i=0; i < self.inputBuffer->mNumberBuffers; i++) {
            self.inputBuffer->mBuffers[i].mNumberChannels = 1;
            self.inputBuffer->mBuffers[i].mDataByteSize = bufferSizeBytes;
            self.inputBuffer->mBuffers[i].mData = malloc(bufferSizeBytes);
            memset(self.inputBuffer->mBuffers[i].mData, 0, bufferSizeBytes);
        }
    } else {
        printf("Format is interleaved\n");
        self.isInterleaved = YES;
        
        UInt32 propsize = offsetof(AudioBufferList, mBuffers[0]) + (sizeof(AudioBuffer) * 1);
        
        self.inputBuffer = (AudioBufferList *)malloc(propsize);
        self.inputBuffer->mNumberBuffers = 1;
        
        self.inputBuffer->mBuffers[0].mNumberChannels = _outputFormat.mChannelsPerFrame;
        self.inputBuffer->mBuffers[0].mDataByteSize = bufferSizeBytes;
        self.inputBuffer->mBuffers[0].mData = malloc(bufferSizeBytes);
        memset(self.inputBuffer->mBuffers[0].mData, 0, bufferSizeBytes);
    }
    
    
    // try 2  remember to disuncomment try 2 's callback part
//    _outputFormat = _inputFormat;
//    CheckError(AudioUnitSetProperty(_inputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, kInputBus, &_outputFormat, size), "Couldn't set streamFormat into outputScope of inputBus");
//    CheckError(AudioUnitSetProperty(_inputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, kOutputBus, &_inputFormat, size), "Couldn't set streamFormat into inputScope of outputBus");
//    
//    UInt32 numFramesPerBuffer;
////    size = sizeof(UInt32);
////    CheckError(AudioUnitGetProperty(_inputUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Input, kOutputBus, &numFramesPerBuffer, &size), "Couldn't get the number of frames per callback");
//    numFramesPerBuffer = 1024;
//    
//    UInt32 bufferSizeBytes = _outputFormat.mBytesPerFrame * _outputFormat.mFramesPerPacket * numFramesPerBuffer;
//    
//    if (_inputFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved) {
//        printf("Not interleaved!\n");
//        self.isInterleaved = NO;
//        
//        UInt32 propsize = offsetof(AudioBufferList, mBuffers[0]) + (sizeof(AudioBuffer) * _inputFormat.mChannelsPerFrame);
//        
//        self.inputBuffer = (AudioBufferList *)malloc(propsize);
//        self.inputBuffer->mNumberBuffers = _inputFormat.mChannelsPerFrame;
//        
//        for (UInt32 i = 0; i < self.inputBuffer->mNumberBuffers; i++) {
//            self.inputBuffer->mBuffers[i].mNumberChannels = 1;
//            self.inputBuffer->mBuffers[i].mDataByteSize = bufferSizeBytes;
//            self.inputBuffer->mBuffers[i].mData = malloc(bufferSizeBytes);
//            memset(self.inputBuffer->mBuffers[i].mData, 0, bufferSizeBytes);
//        }
//    } else {
//        printf("Format is interleaved!\n");
//        self.isInterleaved = YES;
//        
//        UInt32 propsize = offsetof(AudioBufferList, mBuffers[0]) + (sizeof(AudioBuffer) * 1);
//        
//        self.inputBuffer = (AudioBufferList *)malloc(propsize);
//        self.inputBuffer->mNumberBuffers = 1;
//        
//        self.inputBuffer->mBuffers[0].mNumberChannels = _inputFormat.mChannelsPerFrame;
//        self.inputBuffer->mBuffers[0].mDataByteSize = bufferSizeBytes;
//        self.inputBuffer->mBuffers[0].mData = malloc(bufferSizeBytes);
//        memset(self.inputBuffer->mBuffers[0].mData, 0, bufferSizeBytes);
//    }
    
    // -------------------------------
    
    
    // ----- Callback Setup -----
    // --------------------------

    // try 1 -> inputCallback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = inputCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    CheckError(AudioUnitSetProperty(_inputUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, kOutputBus, &callbackStruct, sizeof(callbackStruct)), "Couldn't set render callback on the global scope");
    
    
    // try 2 -> renderCallback (can not use)
//    AURenderCallbackStruct callbackStruct;
//    callbackStruct.inputProc = inputCallback;
//    callbackStruct.inputProcRefCon = NULL;
//    CheckError(AudioUnitSetProperty(_inputUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, kOutputBus, &callbackStruct, sizeof(callbackStruct)), "Couldn't set render callback on the output element");
    
    // --------------------------
    
    
    // ----- Initialize Unit -----
    // ---------------------------
    
    CheckError(AudioUnitInitialize(_inputUnit), "Couldn't initialize the input unit");
    
    // ---------------------------
    
}

- (void)play {
    
    UInt32 isInputAvailable = 0;
    UInt32 size = sizeof(isInputAvailable);
    CheckError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &isInputAvailable), "Couldn't check if input was available");
    
    self.inputAvailable = isInputAvailable;
    if (self.inputAvailable) {
        if (!self.playing) {
            CheckError(AudioOutputUnitStart(_inputUnit), "Couldn't start the input unit");
            self.playing = YES;
        }
    }
    
}

- (void)pause {
    
    if (self.playing) {
        CheckError(AudioOutputUnitStop(_inputUnit), "Couldn't stop the intput unit");
        self.playing = NO;
    }
    
}

- (void)checkAudioSource {
    
    // check which the incoming audio route is
    UInt32 propertySize = sizeof(CFStringRef);
    CFStringRef route;
    CheckError(AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &route), "Couldn't check the audio route");
    self.inputRoute = (__bridge NSString *)route;
    CFRelease(route);
    NSLog(@"AudioRoute: %@", self.inputRoute);
    
    // check if the input available
    UInt32 isInputAvailable = 0;
    UInt32 size = sizeof(isInputAvailable);
    CheckError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &isInputAvailable), "Couldn't check if input is available");
    self.inputAvailable = (BOOL)isInputAvailable;
    NSLog(@"Input available? %d", self.inputAvailable);
    
}

- (void)checkSessionProperties {
    
    // check input available and route
    [self checkAudioSource];
    
    // check the number of input channels
    UInt32 size = sizeof(self.numInputChannels);
    UInt32 newNumChannels;
    CheckError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareInputNumberChannels, &size, &newNumChannels), "Couldn't check number of input channels");
    self.numInputChannels = newNumChannels;
    NSLog(@"We've got %u input channels", (unsigned int)self.numInputChannels);
    
    // check sampling rate
    Float64 currentSamplingRate;
    size = sizeof(currentSamplingRate);
    CheckError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &currentSamplingRate), "Couldn't check hardware sampling rate");
    self.samplingRate = currentSamplingRate;
    NSLog(@"Current sampling rate: %f", self.samplingRate);
    
}


#pragma mark - render Callback function

@end

OSStatus inputCallback (void                        *inRefCon,
                        AudioUnitRenderActionFlags  *ioActionFlags,
                        const AudioTimeStamp        *inTimeStamp,
                        UInt32                      inOutputBusNumber,
                        UInt32                      inNumberFrames,
                        AudioBufferList             *ioData)
{
    @autoreleasepool {
        
        AudioEngine *engine = (__bridge AudioEngine *)inRefCon;
        
        if (!engine.playing) {
//            NSLog(@"into if playing");
            return noErr;
        }
        if (engine.inputBlock == nil) {
//            NSLog(@"into if nil inputblock");
            return noErr;
        }
        
        
        CheckError(AudioUnitRender(engine.inputUnit, ioActionFlags, inTimeStamp, inOutputBusNumber, inNumberFrames, engine.inputBuffer), "Couldn't render the input unit");
        engine.inputBlock((SInt16 *)(engine.inputBuffer->mBuffers[0].mData), inNumberFrames, engine.numInputChannels);
        
    }
    
    return noErr;
}
