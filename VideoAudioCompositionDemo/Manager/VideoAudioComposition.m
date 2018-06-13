//
//  VideoAudioComposition.m
//  VideoAudioCompositionDemo
//
//  Created by 高磊 on 2018/1/22.
//  Copyright © 2018年 高磊. All rights reserved.
//

#import "VideoAudioComposition.h"
#import "GLFolderManager.h"
#import <UIKit/UIKit.h>

static NSString *const kCompositionPath = @"GLComposition";

@implementation VideoAudioComposition


- (NSString *)compositionPath
{
    return [GLFolderManager createCacheFilePath:kCompositionPath];
}

- (void)compositionVideoUrl:(NSURL *)videoUrl videoTimeRange:(CMTimeRange)videoTimeRange audioUrl:(NSURL *)audioUrl audioTimeRange:(CMTimeRange)audioTimeRange success:(SuccessBlcok)successBlcok
{
    NSCAssert(_compositionName.length > 0, @"请输入转换后的名字");
    NSString *outPutFilePath = [[self compositionPath] stringByAppendingPathComponent:_compositionName];
    
    //存在该文件
    if ([GLFolderManager fileExistsAtPath:outPutFilePath]) {
        [GLFolderManager clearCachesWithFilePath:outPutFilePath];
    }
    
    // 创建可变的音视频组合
    AVMutableComposition *composition = [AVMutableComposition composition];
    // 音频通道
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    // 视频通道 枚举 kCMPersistentTrackID_Invalid = 0
    AVMutableCompositionTrack *videoTrack = nil;
    
    
    // 视频采集
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    videoTimeRange = [self fitTimeRange:videoTimeRange avUrlAsset:videoAsset];
    
    // 音频采集
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
    
    audioTimeRange = [self fitTimeRange:audioTimeRange avUrlAsset:audioAsset];

    
    if (_compositionType == VideoAudioToVideo) {
        //以视频时间为标准 若视频时间小于音频时间 则让音频时间和视频时间保持一致
        if (CMTimeCompare(videoTimeRange.duration,audioTimeRange.duration))
        {
            audioTimeRange.duration = videoTimeRange.duration;
        }
        //在测试中发现 VideoAudioToAudio如果不用 视频通道  就不要去创建 否则会失败
        videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    }

    

    // 音频采集通道
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    // 加入合成轨道之中
    [audioTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];

    
    switch (_compositionType) {
        case VideoAudioToAudio:
        {
            //  音频采集通道
            AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            //  把采集轨道数据加入到可变轨道之中
            [audioTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:audioTimeRange.duration error:nil];
        }
            break;
        case VideoAudioToVideo:{

            //  视频采集通道
            AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
            //  把采集轨道数据加入到可变轨道之中
            [videoTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
        }
            break;
        default:
            break;
    }

    [self composition:composition storePath:outPutFilePath success:successBlcok];
}

- (void)compositionVideoUrl:(NSURL *)videoUrl videoTimeRange:(CMTimeRange)videoTimeRange mergeVideoUrl:(NSURL *)mergeVideoUrl mergeVideoTimeRange:(CMTimeRange)mergeVideoTimeRange success:(SuccessBlcok)successBlcok
{
    switch (_compositionType) {
        case VideoToVideo:
        {
            NSArray *timeRanges = [NSArray arrayWithObjects:[NSValue valueWithCMTimeRange:videoTimeRange],[NSValue valueWithCMTimeRange:mergeVideoTimeRange] ,nil];
            [self compositionVideos:@[videoUrl,mergeVideoUrl] timeRanges:timeRanges success:successBlcok];
        }
            break;
        case VideoToAudio:{
            NSArray *timeRanges = [NSArray arrayWithObjects:[NSValue valueWithCMTimeRange:videoTimeRange],[NSValue valueWithCMTimeRange:mergeVideoTimeRange] ,nil];
            [self compositionAudios:@[videoUrl,mergeVideoUrl] timeRanges:timeRanges success:successBlcok];
        }
            break;
        default:
            break;
    }
}

- (void)compositionVideos:(NSArray<NSURL *> *)videos timeRanges:(NSArray<NSValue *> *)timeRanges success:(SuccessBlcok)successBlcok
{
    [self compositionMedia:videos timeRanges:timeRanges type:0 success:successBlcok];
}

- (void)compositionAudios:(NSArray<NSURL *> *)audios timeRanges:(NSArray<NSValue *> *)timeRanges success:(SuccessBlcok)successBlcok
{
    [self compositionMedia:audios timeRanges:timeRanges type:1 success:successBlcok];
}


#pragma mark == private method
- (void)compositionMedia:(NSArray<NSURL *> *)media timeRanges:(NSArray<NSValue *> *)timeRanges type:(NSInteger)type success:(SuccessBlcok)successBlcok
{
    NSCAssert(_compositionName.length > 0, @"请输入转换后的名字");
    NSCAssert((timeRanges.count == 0 || timeRanges.count == media.count), @"请输入正确的timeRange");
    NSString *outPutFilePath = [[self compositionPath] stringByAppendingPathComponent:_compositionName];
   
    //存在该文件
    if ([GLFolderManager fileExistsAtPath:outPutFilePath]) {
        [GLFolderManager clearCachesWithFilePath:outPutFilePath];
    }

    // 创建可变的音视频组合
    AVMutableComposition *composition = [AVMutableComposition composition];
    if (type == 0) {
        // 视频通道
        AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        // 音频通道
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        CMTime atTime = kCMTimeZero;
        
        for (int i = 0;i < media.count;i ++) {
            NSURL *url = media[i];
            CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, kCMTimeZero);
            if (timeRanges.count > 0) {
                timeRange = [timeRanges[i] CMTimeRangeValue];
            }
            
            // 视频采集
            AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
            timeRange = [self fitTimeRange:timeRange avUrlAsset:videoAsset];
            
            // 视频采集通道
            AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
            // 把采集轨道数据加入到可变轨道之中
            [videoTrack insertTimeRange:timeRange ofTrack:videoAssetTrack atTime:atTime error:nil];
            
            // 音频采集通道
            AVAssetTrack *audioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            // 加入合成轨道之中
            [audioTrack insertTimeRange:timeRange ofTrack:audioAssetTrack atTime:atTime error:nil];
            
            atTime = CMTimeAdd(atTime, timeRange.duration);
        }
    }else{
        // 音频通道
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        CMTime atTime = kCMTimeZero;
        
        for (int i = 0;i < media.count;i ++) {
            NSURL *url = media[i];
            CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, kCMTimeZero);
            if (timeRanges.count > 0) {
                timeRange = [timeRanges[i] CMTimeRangeValue];
            }
            
            // 音频采集
            AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
            timeRange = [self fitTimeRange:timeRange avUrlAsset:audioAsset];
            
            // 音频采集通道
            AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
            // 加入合成轨道之中
            [audioTrack insertTimeRange:timeRange ofTrack:audioAssetTrack atTime:atTime error:nil];
            
            atTime = CMTimeAdd(atTime, timeRange.duration);
        }
    }
    [self composition:composition storePath:outPutFilePath success:successBlcok];
}


//得到合适的时间
- (CMTimeRange)fitTimeRange:(CMTimeRange)timeRange avUrlAsset:(AVURLAsset *)avUrlAsset
{
    CMTimeRange fitTimeRange = timeRange;
    
    if (CMTimeCompare(avUrlAsset.duration,timeRange.duration))
    {
        fitTimeRange.duration = avUrlAsset.duration;
    }
    if (CMTimeCompare(timeRange.duration,kCMTimeZero))
    {
        fitTimeRange.duration = avUrlAsset.duration;
    }
    return fitTimeRange;
}

//输出
- (void)composition:(AVMutableComposition *)avComposition
          storePath:(NSString *)storePath
            success:(SuccessBlcok)successBlcok
{
    // 创建一个输出
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:avComposition presetName:AVAssetExportPresetHighestQuality];
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    // 输出地址
    assetExport.outputURL = [NSURL fileURLWithPath:storePath];
    // 优化
    assetExport.shouldOptimizeForNetworkUse = YES;
    
    __block NSTimer *timer = nil;

    timer = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSLog(@" 打印信息:%f",assetExport.progress);
        if (self.progressBlock) {
            self.progressBlock(assetExport.progress);
        }
    }];


    // 合成完毕
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        if (timer) {
            [timer invalidate];
            timer = nil;
        }
        // 回到主线程
        switch (assetExport.status) {
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"exporter Unknow");
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"exporter Canceled");
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"%@", [NSString stringWithFormat:@"exporter Failed%@",assetExport.error.description]);
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"exporter Waiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"exporter Exporting");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"exporter Completed");
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 调用播放方法
                    successBlcok([NSURL fileURLWithPath:storePath]);
                });
                break;
        }
    }];
}


//-(AVAudioMix *)buildAudioMixWithVideoTrack:(AVCompositionTrack *)videoTrack VideoVolume:(float)videoVolume BGMTrack:(AVCompositionTrack *)BGMTrack BGMVolume:(float)BGMVolume controlVolumeRange:(CMTime)volumeRange {
//    // 创建音频混合类
//    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
//
//    // 拿到视频声音轨道设置音量
//    AVMutableAudioMixInputParameters *Videoparameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:videoTrack];
//    [Videoparameters setVolume:videoVolume atTime:volumeRange];
//
//    // 设置背景音乐音量
//    AVMutableAudioMixInputParameters *BGMparameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:BGMTrack];
//    [BGMparameters setVolume:BGMVolume atTime:volumeRange];
//
//    // 加入混合数组
//    audioMix.inputParameters = @[Videoparameters,BGMparameters];
//
//    return audioMix;
//}

@end
