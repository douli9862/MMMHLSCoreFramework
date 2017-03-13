//
//  Kickflip.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#include <mutex>

#import "Kickflip.h"
//#import "KFLog.h"
//#import "KFBroadcastViewController.h"
#import "KFRecorder.h"

@interface KFRecorderNode()
//@property (nonatomic, copy) NSString *apiKey;
//@property (nonatomic, copy) NSString *apiSecret;
@property (nonatomic) NSUInteger maxBitrate;
@property (nonatomic) BOOL useAdaptiveBitrate;
@end

//static Kickflip *_kickflip = nil;
//
@implementation KFRecorderNode
{
    KFRecorder *_recorderSession;
    std::atomic<bool> m_bCanInput;
    std::mutex        m_MainMutex;
}


- (id) init
{
    if (self = [super init]){
        _recorderSession = [[KFRecorder alloc] init];
    }
    m_bCanInput = false;
    return  self;
}

- (id) initDelegate:(id<KFRecorderDelegate>)delegate
{
    if (self = [super init]){
        _recorderSession = [[KFRecorder alloc] init];
        _recorderSession.delegate = delegate;
    }
    m_bCanInput = false;
    return self;
}

- (id) initWithDelegate:(id<KFRecorderDelegate>)delegate withVideoBirate:(int)videoBirate
                  withSize:(CGSize)videoSize
       withAudioSampleRate:(NSUInteger)audioSampleRate
{
    if (self = [super init]){
        _recorderSession = [[KFRecorder alloc] initWithBitrateSize:videoBirate withSize:videoSize withAudioSampleRate:audioSampleRate];
        _recorderSession.delegate = delegate;
    }
    m_bCanInput = false;
    return self;
}

- (void)startSession:(NSString*)hlsPath
{
    //std::unique_lock<std::mutex> mCAuto(m_MainMutex);
    bool bRet;
    if(_recorderSession){
        bRet = [_recorderSession startRecording:hlsPath];
        if(bRet){
            m_bCanInput = true;
            NSLog(@"m_bCanInput :%d", (int)m_bCanInput);
        }
    }
}

- (void)encodeAudioWithASBDEX:(AudioStreamBasicDescription)asbd buffer:(AudioBufferList *)audio
{
    if(_recorderSession){
       // [_recorderSession inputAudioFrame:asbd time:time numberOfFrames:frames buffer:audio];
    }
}


- (void)encodeAudioWithASBD:(AudioStreamBasicDescription)asbd time:(const AudioTimeStamp *)time numberOfFrames:(UInt32)frames buffer:(AudioBufferList *)audio
{
    //std::unique_lock<std::mutex> mCAuto(m_MainMutex);
//    if (m_bCanInput.load()) {
//        return;
//    }
    
    if(_recorderSession){
        [_recorderSession inputAudioFrame:asbd time:time numberOfFrames:frames buffer:audio];
    }
}

- (void)encodeVideoWithPixelBuffer:(CVPixelBufferRef)buffer time:(CMTime)time
{
    //std::unique_lock<std::mutex> mCAuto(m_MainMutex);
//    if (m_bCanInput.load()) {
//        return;
//    }
    
    if(_recorderSession){
        [_recorderSession intputPixelBufferRef:buffer];
    }
}

- (void)encodeVideoWithSample:(CMSampleBufferRef)sample
{
    //std::unique_lock<std::mutex> mCAuto(m_MainMutex);

//    if (!m_bCanInput.load()) {
//        return;
//    }
    
    if(_recorderSession){
        [_recorderSession intputVidoFrame:sample];
    }
}

- (void)endSession{
//    if (!m_bCanInput.load()) {
//        return;
//    }
    
    //std::unique_lock<std::mutex> mCAuto(m_MainMutex);
    m_bCanInput = false;
    if(_recorderSession){
        [_recorderSession stopRecording];
    }
}

@end
