//
//  KFHLSWriter.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/16/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import "KFHLSWriter.h"
#import "FFOutputFile.h"
#import "FFmpegWrapper.h"
#import "libavformat/avformat.h"
#import "libavcodec/avcodec.h"
#import "libavutil/opt.h"

@interface KFHLSWriter()
@property (nonatomic, strong) FFOutputFile *outputFile;
@property (nonatomic, strong) FFOutputStream *videoStream;
@property (nonatomic, strong) FFOutputStream *audioStream;
@property (nonatomic) AVPacket *packet;
@property (nonatomic) AVRational videoTimeBase;
@property (nonatomic) AVRational audioTimeBase;
@property (nonatomic) NSUInteger segmentDurationSeconds;
@end

@implementation KFHLSWriter
{
    bool    bKeyComed;
    int64_t beginTimeVale;
    bool    bWriting;
}

- (id) initWithDirectoryPath:(NSString *)directoryPath {
    if (self = [super init]) {
        av_register_all();
        avformat_network_init();
        avcodec_register_all();
        
        bKeyComed = false;
        
#if DEBUG
        av_log_set_level(AV_LOG_VERBOSE);
#else
        av_log_set_level(AV_LOG_QUIET);
#endif
        
        _directoryPath = directoryPath;
        _packet = av_malloc(sizeof(AVPacket));
        _videoTimeBase.num = 1;
        _videoTimeBase.den = 1000000000;//1000000;//
        _audioTimeBase.num = 1;
        _audioTimeBase.den = 1000000000;//1000000;//
        _segmentDurationSeconds = 2;
        [self setupOutputFile];
        _conversionQueue = dispatch_queue_create("HLS Write queue", DISPATCH_QUEUE_SERIAL);
        _uuid = [[NSUUID UUID] UUIDString];
        bWriting = false;
    }
    return self;
}

- (void) setupOutputFile {
    NSString *outputPath = [_directoryPath stringByAppendingPathComponent:@"index.m3u8"];
    
    _outputFile = [[FFOutputFile alloc] initWithPath:outputPath options:@{kFFmpegOutputFormatKey: @"hls"}];
    
    FFBitstreamFilter *bitstreamFilter = [[FFBitstreamFilter alloc] initWithFilterName:@"h264_mp4toannexb"];
    [_outputFile addBitstreamFilter:bitstreamFilter];
}

- (void) addVideoStreamWithWidth:(int)width height:(int)height {
    _videoStream = [[FFOutputStream alloc] initWithOutputFile:_outputFile outputCodec:@"h264"];
    [_videoStream setupVideoContextWithWidth:width height:height];
    int ret = av_opt_set_int(_outputFile.formatContext->priv_data, "hls_time", _segmentDurationSeconds, 0);
    NSLog(@"hls_time ret:%d", ret);
    
    ret = av_opt_set(_outputFile.formatContext->priv_data, "hls_playlist_type", "vod", 0);
    NSLog(@"hls_playlist_type ret:%d", ret);
    if(ret < 0) {
        char buf[1024];
        av_strerror(ret, buf, 1024);
        NSLog(@"err: %d(%s)\n", ret, buf);     //moov_size
    }
//    ret = av_opt_set(_outputFile.formatContext->priv_data, "moov_size", 1000*1000, 0);
}

- (void) addAudioStreamWithSampleRate:(int)sampleRate {
    _audioStream = [[FFOutputStream alloc] initWithOutputFile:_outputFile outputCodec:@"aac"];
    [_audioStream setupAudioContextWithSampleRate:sampleRate];
}

- (BOOL) prepareForWriting:(NSError *__autoreleasing *)error {
    // Open the output file for writing and write header
    if (![_outputFile openFileForWritingWithError:error]) {
        return NO;
    }
    if (![_outputFile writeHeaderWithError:error]) {
        return NO;
    }
    
    bWriting = true;
    return YES;
}


- (void) processEncodedData:(NSData*)data presentationTimestamp:(CMTime)pts streamIndex:(NSUInteger)streamIndex isKeyFrame:(BOOL)isKeyFrame {
    if (data.length == 0) {
        return;
    }
    dispatch_async(_conversionQueue, ^{
        if(!bWriting){
            return ;
        }
        
        av_init_packet(_packet);
        
        uint64_t originalPTS = pts.value;
        
        // This lets the muxer know about H264 keyframes
        if (streamIndex == 0 && isKeyFrame) { // this is hardcoded to video right now
            _packet->flags |= AV_PKT_FLAG_KEY;
        }
        
        _packet->data = (uint8_t*)data.bytes;
        _packet->size = (int)data.length;
        _packet->stream_index = (unsigned int)streamIndex;
        AVRational temp ;
        if(streamIndex == 0){
            temp = _outputFile.formatContext->streams[_packet->stream_index]->time_base;
        }
        else{
            temp = _outputFile.formatContext->streams[_packet->stream_index]->time_base;
        }
        //NSLog(@"\nstreamIndex:%d\n", (unsigned int)streamIndex);
        uint64_t scaledPTS = av_rescale_q(originalPTS, _videoTimeBase, _outputFile.formatContext->streams[_packet->stream_index]->time_base);
        //DDLogInfo(@"*** Scaled PTS: %lld", scaledPTS);
        
        if(streamIndex == 0){
            //NSLog(@"\n scaledPTS :%lld, orgPts:%lld\n", scaledPTS, originalPTS/1000000 + beginTimeVale);
        }
        
        _packet->pts = scaledPTS;
        _packet->dts = scaledPTS;
        NSError *error = nil;
        [_outputFile writePacket:_packet error:&error];
        if (error) {
            NSLog(@"Error writing packet at streamIndex %d and PTS %lld: %@", (unsigned int)streamIndex, originalPTS, error.description);
        } else {
            //DDLogVerbose(@"Wrote packet of length %d at streamIndex %d and \t oPTS %lld \t scaledPTS %lld", data.length, streamIndex, originalPTS, scaledPTS);
        }
    });
}


- (BOOL) finishWriting:(NSError *__autoreleasing *)error {
    bWriting = false;
    NSLog(@"finishWriting begin.");
    
    dispatch_sync(_conversionQueue, ^
    {
        if(_outputFile != nil ){
            NSLog(@"finishWriting _conversionQueue  writeTrailerWith.");
            
            [_outputFile writeTrailerWithError:error];
            _outputFile = nil;
        }
        NSLog(@"_conversionQueue bWriting:%d.", bWriting);
        
    });
    
    dispatch_sync(_conversionQueue, ^{});
    NSLog(@"finishWriting end.");
    
    return true;
}

@end
