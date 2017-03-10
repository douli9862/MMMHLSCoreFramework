//
//  VideoEncoder.m
//  Encoder Demo
//
//  Created by Geraint Davies on 14/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "VideoEncoder.h"

@implementation VideoEncoder
{
    void*                  m_pixelBuffers;
}

@synthesize path = _path;

+ (VideoEncoder*) encoderForPath:(NSString*) path Height:(int) height andWidth:(int) width bitrate:(int)bitrate
{
    VideoEncoder* enc = [VideoEncoder alloc];
    [enc initPath:path Height:height andWidth:width bitrate:bitrate];
    return enc;
}


- (void) initPath:(NSString*)path Height:(int) height andWidth:(int) width bitrate:(int)bitrate
{
    self.path = path;
    _bitrate = bitrate;
    
    [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
    NSURL* url = [NSURL fileURLWithPath:self.path];
    
    _writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeQuickTimeMovie error:nil];
    NSDictionary* settings = @{
        AVVideoCodecKey: AVVideoCodecH264,
        AVVideoWidthKey: @(width),
        AVVideoHeightKey: @(height),
        AVVideoCompressionPropertiesKey: @{
             AVVideoAverageBitRateKey: @(self.bitrate),
             AVVideoMaxKeyFrameIntervalKey: @(50),//@(150),
             AVVideoProfileLevelKey: AVVideoProfileLevelH264Baseline31,//AVVideoProfileLevelH264BaselineAutoLevel,
             AVVideoAllowFrameReorderingKey: @NO,
             //AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCAVLC,
             //AVVideoExpectedSourceFrameRateKey: @(30),
             //AVVideoAverageNonDroppableFrameRateKey: @(30)
        }
    };
    _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
    _writerInput.expectsMediaDataInRealTime = YES;
    [_writer addInput:_writerInput];
}

- (void) finishWithCompletionHandler:(void (^)(void))handler
{
    if (_writer.status == AVAssetWriterStatusWriting) {
        [_writer finishWritingWithCompletionHandler: handler];
    }
}

- (BOOL) encodeFrame:(CMSampleBufferRef) sampleBuffer withPresentationTime:(CMTime)pts
{
    CMTime pts1 = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);

    if (CMSampleBufferDataIsReady(sampleBuffer))
    {
        if (_writer.status == AVAssetWriterStatusUnknown)
        {
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [_writer startWriting];
            [_writer startSessionAtSourceTime:startTime];
        }
        if (_writer.status == AVAssetWriterStatusFailed)
        {
            NSLog(@"writer error %@", _writer.error.localizedDescription);
            return NO;
        }
        if (_writerInput.readyForMoreMediaData == YES)
        {
            //[_writerInput appendSampleBuffer:sampleBuffer];
            
            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            
            AVAssetWriterInputPixelBufferAdaptor* adaptor = (__bridge AVAssetWriterInputPixelBufferAdaptor*)m_pixelBuffers;
            BOOL ready = adaptor.assetWriterInput.readyForMoreMediaData;
            
            if(!ready) {
                return false;
            }
            
            //- (BOOL)appendPixelBuffer:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)presentationTime;
            CVPixelBufferRef pixelBuffer = imageBuffer;
            
            CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
            @try {
                //[adaptor appendPixelBuffer:pb withPresentationTime:presentationTime];
                [adaptor appendPixelBuffer:pixelBuffer withPresentationTime:pts1];

            } @catch (NSException* e) {
                NSLog(@"%@", e);
//                m_queue.enqueue_sync([]{});
//                swapWriters(true);
                return false;
            } @finally {
                CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
            }

            
            return YES;
        }
    }
    return NO;
}

- (BOOL) encodeFrame:(CMSampleBufferRef) sampleBuffer
{
    if (CMSampleBufferDataIsReady(sampleBuffer))
    {
        if (_writer.status == AVAssetWriterStatusUnknown)
        {
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [_writer startWriting];
            [_writer startSessionAtSourceTime:startTime];
        }
        if (_writer.status == AVAssetWriterStatusFailed)
        {
            NSLog(@"writer error %@", _writer.error.localizedDescription);
            return NO;
        }
        if (_writerInput.readyForMoreMediaData == YES &&
            _writer.status == AVAssetWriterStatusWriting)
        {
            [_writerInput appendSampleBuffer:sampleBuffer];
            return YES;
        }
    }
    return NO;
}

@end
