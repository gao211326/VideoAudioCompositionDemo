//
//  VideoManager.m
//  VideoAudioCompositionDemo
//
//  Created by 高磊 on 2018/2/1.
//  Copyright © 2018年 高磊. All rights reserved.
//

/*
 AVMutableVideoCompositionLayerInstruction 用于裁剪 旋转 透明度等改变
 */

#import "VideoAudioEdit.h"
#import "GLFolderManager.h"
#import "UIImage+buffer.h"
#import <UIKit/UIKit.h>

static NSString *const kVideoPath = @"GLVideo";

@interface VideoAudioEdit()

@property (nonatomic,assign) dispatch_group_t m_dispatchGroup;
@property (nonatomic,assign) dispatch_queue_t m_queue;

@end

@implementation VideoAudioEdit

- (NSString *)videoPath
{
    return [GLFolderManager createCacheFilePath:kVideoPath];
}
#pragma mark == 获取视频帧

- (void)getThumbImageOfVideo:(NSURL *)videoUrl forTimes:(NSArray<NSValue *> *)requestedTimes complete:(CompleteBlock)complete
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    AVAssetImageGenerator *assetImage = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    //精确截取时间
    assetImage.requestedTimeToleranceAfter = kCMTimeZero;
    assetImage.requestedTimeToleranceBefore = kCMTimeZero;
    assetImage.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    //设置最大尺寸
    assetImage.maximumSize = CGSizeMake(640, 400);

    //requestedTime 请求时间 actualTime实际截取画面的时间
    [assetImage generateCGImagesAsynchronouslyForTimes:requestedTimes completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        
        if (AVAssetImageGeneratorSucceeded == result) {
            if (image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImage *result_image = [[UIImage alloc] initWithCGImage:image];
                                        
                    complete(result_image,nil);
                    //需要释放
                    CGImageRelease(image);
                });
            }
            //展示时间
            CMTimeShow(requestedTime);
            CMTimeShow(actualTime);

        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(nil,error);
            });
        }

    }];
}


#pragma mark == 图片合成为视频
- (void)compositionVideoWithImage:(NSArray<UIImage *> *)images videoName:(NSString *)videoName success:(SuccessBlcok _Nullable)successBlcok
{
    
    NSCAssert(videoName.length > 0, @"请输入转换后的名字");
    NSString *outPutFilePath = [[self videoPath] stringByAppendingPathComponent:videoName];
    
    //存在该文件
    if ([GLFolderManager fileExistsAtPath:outPutFilePath]) {
        [GLFolderManager clearCachesWithFilePath:outPutFilePath];
    }
    
    NSError *outError;
    AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:outPutFilePath] fileType:AVFileTypeQuickTimeMovie error:&outError];
    BOOL success = (assetWriter != nil);
    
    //视频尺寸
    CGSize size = CGSizeMake(320, 480);
    //meaning that it must contain AVVideoCodecKey, AVVideoWidthKey, and AVVideoHeightKey.
    //视频信息设置
    NSDictionary *outPutSettingDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                      AVVideoCodecTypeH264,AVVideoCodecKey,
                                      [NSNumber numberWithInt:size.width],AVVideoWidthKey,
                                      [NSNumber numberWithInt:size.height],AVVideoHeightKey, nil];

    if (success) {
        AVAssetWriterInput *videoWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:outPutSettingDic];
        //每个AVAssetWriterInput期望以CMSampleBufferRef对象形式接收数据，但如果你想要将CVPixelBufferRef类型对象添加到assetwriterinput，就使用AVAssetWriterInputPixelBufferAdaptor类。

        //像素缓冲区属性，这些属性最接近于被附加的视频帧的源格式。
        //To specify the pixel format type, the pixelBufferAttributes dictionary should contain a value for kCVPixelBufferPixelFormatTypeKey
        NSDictionary *sourcePixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],kCVPixelBufferPixelFormatTypeKey, nil];
        
        AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributes];
        
        if ([assetWriter canAddInput:videoWriterInput]) {
            [assetWriter addInput:videoWriterInput];
            [assetWriter startWriting];
            [assetWriter startSessionAtSourceTime:kCMTimeZero];
        }
        
        //开一个队列
        dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaQueue", NULL);
        NSInteger  __block index = 0;
        
        [videoWriterInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
            while ([videoWriterInput isReadyForMoreMediaData])
            {
                if (++index >= images.count * 30) {
                    [videoWriterInput markAsFinished];
                    [assetWriter finishWritingWithCompletionHandler:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            successBlcok([NSURL fileURLWithPath:outPutFilePath]);
                        });
                    }];
                    break;
                }
                long idx = index / 30;
                NSLog(@" 打印信息:%ld",idx);
                //先将图片转换成CVPixelBufferRef
                UIImage *image = images[idx];
                CVPixelBufferRef pixelBuffer = [image pixelBufferRefWithSize:size];
                if (pixelBuffer) {
                    CMTime time = CMTimeMake(index, 30);
                    if ([adaptor appendPixelBuffer:pixelBuffer withPresentationTime:time]) {
                    
                        NSLog(@"OK++%f",CMTimeGetSeconds(time));
                    }else{
                        NSLog(@"Fail");
                    }
                    CFRelease(pixelBuffer);
                }
            }
        }];
    }
}


#pragma mark == 将图片合成为视频 并加上音乐

- (void)compositionVideoWithImage:(NSArray<UIImage *> *)images videoName:(NSString *)videoName audio:(NSURL *)audioUrl success:(SuccessBlcok)successBlcok
{
    if (!audioUrl) {
        [self compositionVideoWithImage:images videoName:videoName success:successBlcok];
    }else{
        NSCAssert(videoName.length > 0, @"请输入转换后的名字");
        NSString *outPutFilePath = [[self videoPath] stringByAppendingPathComponent:videoName];
        
        // 音频采集
        AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
        
        NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];
        
        // Create the main serialization queue.
        dispatch_queue_t mainSerializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], NULL);
        _m_queue = mainSerializationQueue;

        [audioAsset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
            dispatch_async(mainSerializationQueue, ^{
                BOOL success = YES;
                NSError *localError = nil;
                // Check for success of loading the assets tracks.
                success = ([audioAsset statusOfValueForKey:@"tracks" error:&localError] == AVKeyValueStatusLoaded);
                
                // If the tracks loaded successfully, make sure that no file exists at the output path for the asset writer.
                if (success) {
                    //存在该文件
                    if ([GLFolderManager fileExistsAtPath:outPutFilePath]) {
                        [GLFolderManager clearCachesWithFilePath:outPutFilePath];
                    }
                    
                    AVAssetTrack *assetAudioTrack = nil;
                    NSArray *audioTracks = [audioAsset tracksWithMediaType:AVMediaTypeAudio];
                    if (audioTracks.count > 0) {
                        assetAudioTrack = [audioTracks objectAtIndex:0];
                    }
                    
                    //音频通道是否存在
                    if (assetAudioTrack)
                    {
                        NSError *error;
                        //创建读出
                        AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset:audioAsset error:&error];
                        BOOL success = (assetReader != nil);
                        
                        AVAssetWriter *assetWriter = nil;
                        //创建写入
                        if (success) {
                            NSError *outError;
                            assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:outPutFilePath] fileType:AVFileTypeQuickTimeMovie error:&outError];
                            success = (assetWriter != nil);
                        }
                        if (success) {
                            //将track里的数据 读取出来
                            // If there is an audio track to read, set the decompression settings to Linear PCM and create the asset reader output.
                            NSDictionary *decompressionAudioSettings = @{AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM]};
                            AVAssetReaderTrackOutput *assetReaderAudioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetAudioTrack outputSettings:decompressionAudioSettings];
                            if ([assetReader canAddOutput:assetReaderAudioOutput]) {
                                [assetReader addOutput:assetReaderAudioOutput];
                            }
                            
                            // Then, set the compression settings to 128kbps AAC and create the asset writer input.
                            AudioChannelLayout stereoChannelLayout = {
                                .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
                                .mChannelBitmap = 0,
                                .mNumberChannelDescriptions = 0
                            };
                            NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
                            NSDictionary *compressionAudioSettings = @{
                                                                       AVFormatIDKey         : [NSNumber numberWithUnsignedInt:kAudioFormatMPEG4AAC],
                                                                       AVEncoderBitRateKey   : [NSNumber numberWithInteger:128000],
                                                                       AVSampleRateKey       : [NSNumber numberWithInteger:44100],
                                                                       AVChannelLayoutKey    : channelLayoutAsData,
                                                                       AVNumberOfChannelsKey : [NSNumber numberWithUnsignedInteger:2]
                                                                       };
                            
                            //将读取的内容写入
                            AVAssetWriterInput *assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:[assetAudioTrack mediaType] outputSettings:compressionAudioSettings];
                            
                            if ([assetWriter canAddInput:assetWriterAudioInput]) {
                                [assetWriter addInput:assetWriterAudioInput];
                            }
                            
                            
                            //--------------图片写入视频设置
                            //视频尺寸
                            CGSize size = CGSizeMake(320, 480);
                            //meaning that it must contain AVVideoCodecKey, AVVideoWidthKey, and AVVideoHeightKey.
                            //视频信息设置
                            NSDictionary *outPutSettingDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                                              AVVideoCodecTypeH264,AVVideoCodecKey,
                                                              [NSNumber numberWithInt:size.width],AVVideoWidthKey,
                                                              [NSNumber numberWithInt:size.height],AVVideoHeightKey, nil];
                            
                            AVAssetWriterInput *videoWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:outPutSettingDic];
                            //每个AVAssetWriterInput期望以CMSampleBufferRef对象形式接收数据，但如果你想要将CVPixelBufferRef类型对象添加到assetwriterinput，就使用AVAssetWriterInputPixelBufferAdaptor类。
                            
                            //像素缓冲区属性，这些属性最接近于被附加的视频帧的源格式。
                            //To specify the pixel format type, the pixelBufferAttributes dictionary should contain a value for kCVPixelBufferPixelFormatTypeKey
                            NSDictionary *sourcePixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],kCVPixelBufferPixelFormatTypeKey, nil];
                            
                            AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributes];
                            
                            if ([assetWriter canAddInput:videoWriterInput]) {
                                [assetWriter addInput:videoWriterInput];
                            }
                            
                            //--------上面为设置部分  下面为开始执行读取和写入
                            
                            BOOL readSuccess = YES;
                            BOOL writeSuccess = YES;
                            readSuccess = [assetReader startReading];
                            if (!readSuccess) {
                                NSError *readError = assetReader.error;
                                NSLog(@" 打印信息:%@",readError);
                            }
                            if (readSuccess) {
                                writeSuccess = [assetWriter startWriting];
                            }
                            
                            if (!writeSuccess)
                            {
                                NSError *writeError = [assetWriter error];
                                NSLog(@" 打印信息:%@",writeError);
                            }
                            if (writeSuccess)
                            {
                                NSLog(@" 打印信息:+++++");
                                BOOL __block audioFinished = NO;
                                BOOL __block videoFinished = NO;
                                
                                // If the asset reader and writer both started successfully, create the dispatch group where the reencoding will take place and start a sample-writing session.
                                dispatch_group_t dispatchGroup = dispatch_group_create();
                                [assetWriter startSessionAtSourceTime:kCMTimeZero];
                                
                                if (assetWriterAudioInput) {
                                    //加入第一个任务
                                    // If there is audio to reencode, enter the dispatch group before beginning the work.
                                    dispatch_group_enter(dispatchGroup);
                                    
                                    //开一个队列
                                    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaAudioQueue", NULL);
                                    
                                    [assetWriterAudioInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
                                        // Because the block is called asynchronously, check to see whether its task is complete.
                                        if (audioFinished) {
                                            return ;
                                        }
                                        BOOL completedOrFailed = NO;
                                        while ([assetWriterAudioInput isReadyForMoreMediaData] && !completedOrFailed)
                                        {
                                            // Get the next audio sample buffer, and append it to the output file.
                                            CMSampleBufferRef sampleBuffer = [assetReaderAudioOutput copyNextSampleBuffer];
                                            
                                            //特别备注。。。找了几百年的bug  居然是 必须要引用assetReader.status 否则会crash
                                            if ((assetReader.status == AVAssetReaderStatusReading) && sampleBuffer != NULL)
                                            {
                                                BOOL success = [assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                                                CFRelease(sampleBuffer);
                                                sampleBuffer = NULL;
                                                completedOrFailed = !success;
                                            }
                                            else
                                            {
                                                if (assetReader.status == AVAssetReaderStatusCompleted) {
                                                    completedOrFailed = YES;
                                                }else{
                                                    NSLog(@" 打印信息:%@",assetReader.error);
                                                    completedOrFailed = YES;
                                                }
                                            }
                                            
                                            
                                        }
                                        
                                        if (completedOrFailed)
                                        {
                                            // Mark the input as finished, but only if we haven't already done so, and then leave the dispatch group (since the audio work has finished).
                                            BOOL oldFinished = audioFinished;
                                            audioFinished = YES;
                                            if (oldFinished == NO)
                                            {
                                                [assetWriterAudioInput markAsFinished];
                                            }
                                            //和dispatch_group_enter成对出现 出队列
                                            dispatch_group_leave(dispatchGroup);
                                        }
                                    }];
                                }
                                
                                if (videoWriterInput) {
                                    dispatch_group_enter(dispatchGroup);
                                    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaQueue", NULL);
                                    NSInteger  __block index = 0;
                                    [videoWriterInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
                                        if (videoFinished) {
                                            return;
                                        }
                                        while ([videoWriterInput isReadyForMoreMediaData])
                                        {
                                            if (++index >= images.count * 100) {
                                                [videoWriterInput markAsFinished];
                                                dispatch_group_leave(dispatchGroup);
                                                break;
                                            }
                                            long idx = index / 100;
                                            //先将图片转换成CVPixelBufferRef
                                            UIImage *image = images[idx];
                                            CVPixelBufferRef pixelBuffer = [image pixelBufferRefWithSize:size];
                                            if (pixelBuffer) {
                                                CMTime time = CMTimeMake(index, 30);
                                                if ([adaptor appendPixelBuffer:pixelBuffer withPresentationTime:time]) {
//                                                    NSLog(@"OK++%f",CMTimeGetSeconds(time));
                                                }else{
                                                    NSLog(@"Fail");
                                                }
                                                CFRelease(pixelBuffer);
                                            }
                                        }
                                    }];
                                }

                                dispatch_notify(dispatchGroup,mainSerializationQueue, ^{
                                        NSLog(@" 打印信息:+++++++");
                                    [assetWriter finishWritingWithCompletionHandler:^{
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            successBlcok([NSURL fileURLWithPath:outPutFilePath]);
                                        });
                                    }];
                                });
                            }
                        }
                    }
                }
            });
        }];
    }
}


#pragma mark == 视频水印处理
- (void)watermarkForVideo:(NSURL *)videoUrl videoName:(NSString *)videoName success:(SuccessBlcok)successBlcok
{
    NSCAssert(videoName.length > 0, @"请输入转换后的名字");
    NSString *outPutFilePath = [[self videoPath] stringByAppendingPathComponent:videoName];
    //存在该文件
    if ([GLFolderManager fileExistsAtPath:outPutFilePath]) {
        [GLFolderManager clearCachesWithFilePath:outPutFilePath];
    }
    // 视频采集
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];

    //合成器（自我理解）
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    //合成轨道
    AVMutableCompositionTrack *videoCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //视频采集
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVAssetTrack *audioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    //加入合成轨道
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrack.timeRange.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    //创建合成指令
    AVMutableVideoCompositionInstruction *videoCompostionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    //设置时间范围
    videoCompostionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAssetTrack.timeRange.duration);
    //创建层指令，并将其与合成视频轨道相关联
    AVMutableVideoCompositionLayerInstruction *videoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];

    [videoLayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [videoLayerInstruction setOpacity:0.0 atTime:videoAssetTrack.timeRange.duration];
    videoCompostionInstruction.layerInstructions = @[videoLayerInstruction];
    
    
    BOOL isVideoAssetPortrait_  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        //        videoAssetOrientation_ = UIImageOrientationRight;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        //        videoAssetOrientation_ =  UIImageOrientationLeft;
        isVideoAssetPortrait_ = YES;
    }
    CGSize naturalSize;
    if(isVideoAssetPortrait_){
        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        naturalSize = videoAssetTrack.naturalSize;
    }
    
    //创建视频组合
    //Attach the video composition instructions to the video composition
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    //必须设置 下面的尺寸和时间
    mutableVideoComposition.renderSize = naturalSize;
    mutableVideoComposition.frameDuration = CMTimeMake(1, 25);//videoAssetTrack.timeRange.duration;
    mutableVideoComposition.instructions = @[videoCompostionInstruction];
    
    [self addWaterLayerWithAVMutableVideoComposition:mutableVideoComposition];
    
    //设置输出
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mutableComposition presetName:AVAssetExportPresetHighestQuality];
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    // 输出地址
    assetExport.outputURL = [NSURL fileURLWithPath:outPutFilePath];
    // 优化
    assetExport.shouldOptimizeForNetworkUse = YES;
    //设置视频合成
    assetExport.videoComposition = mutableVideoComposition;
    
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
                    successBlcok([NSURL fileURLWithPath:outPutFilePath]);
                });
                break;
        }
    }];

}

- (void)addWaterLayerWithAVMutableVideoComposition:(AVMutableVideoComposition*)mutableVideoComposition
{
    //-------------------layer
    CALayer *watermarkLayer = [CALayer layer];
    [watermarkLayer setContents:(id)[UIImage imageNamed:@"白兔"].CGImage];
    watermarkLayer.bounds = CGRectMake(0, 0, 130, 130);
    watermarkLayer.position = CGPointMake(mutableVideoComposition.renderSize.width/2, mutableVideoComposition.renderSize.height/4);
    
    CALayer *sheepLayer = [CALayer layer];
    [sheepLayer setContents:(id)[UIImage imageNamed:@"绵阳"].CGImage];
    sheepLayer.bounds = CGRectMake(0, 0, 130, 130);
    sheepLayer.position = CGPointMake(mutableVideoComposition.renderSize.width/2, mutableVideoComposition.renderSize.height - 150);
    
    
    CALayer *mouseLayer = [CALayer layer];
    [mouseLayer setContents:(id)[UIImage imageNamed:@"老鼠"].CGImage];
    mouseLayer.bounds = CGRectMake(0, 0, 130, 130);
    mouseLayer.position = CGPointMake(mutableVideoComposition.renderSize.width/2, mutableVideoComposition.renderSize.height/2);

    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    
    parentLayer.frame = CGRectMake(0, 0, mutableVideoComposition.renderSize.width, mutableVideoComposition.renderSize.height);
    videoLayer.frame = CGRectMake(0, 0, mutableVideoComposition.renderSize.width, mutableVideoComposition.renderSize.height);

    [parentLayer addSublayer:videoLayer];
    
    [parentLayer addSublayer:watermarkLayer];
    [parentLayer addSublayer:sheepLayer];
    [parentLayer addSublayer:mouseLayer];
    
    
    //添加文字
    UIFont *font = [UIFont systemFontOfSize:30.0];
    NSString *text = @"加点水印看看效果";
    CATextLayer *textLayer = [[CATextLayer alloc] init];
    [textLayer setFontSize:30];
    [textLayer setString:text];
    [textLayer setAlignmentMode:kCAAlignmentLeft];
    [textLayer setForegroundColor:[[UIColor whiteColor] CGColor]];
    
    CGSize textSize = [text sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    CGFloat textH = textSize.height + 10;
    [textLayer setFrame:CGRectMake(100, mutableVideoComposition.renderSize.height-100, textSize.width + 20, textH)];
    
    [parentLayer addSublayer:textLayer];
    
    mutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    CABasicAnimation *rotationAnima = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnima.fromValue = @(0);
    rotationAnima.toValue = @(-M_PI * 2);
    rotationAnima.repeatCount = HUGE_VALF;
    rotationAnima.duration = 2.0f;  //5s之后消失
    [rotationAnima setRemovedOnCompletion:NO];
    [rotationAnima setFillMode:kCAFillModeForwards];
    rotationAnima.beginTime = AVCoreAnimationBeginTimeAtZero;
    [watermarkLayer addAnimation:rotationAnima forKey:@"Aniamtion"];
    
    
    CGPoint mousePoint = mouseLayer.position;
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    NSValue *key1 = [NSValue valueWithCGPoint:mouseLayer.position];
    NSValue *key2 = [NSValue valueWithCGPoint:CGPointMake(mousePoint.x + 60, mousePoint.y + 40)];
    NSValue *key3 = [NSValue valueWithCGPoint:CGPointMake(mousePoint.x + 120, mousePoint.y)];
    NSValue *key4 = [NSValue valueWithCGPoint:CGPointMake(mousePoint.x + 120, mousePoint.y)];
    animation.values = @[key1,key2,key3,key4];
    animation.duration = 5.0;
    animation.autoreverses = true;//是否按路径返回
    animation.repeatCount = HUGE_VALF;//是否重复执行
    animation.removedOnCompletion = NO;//执行后移除动画
    animation.fillMode = kCAFillModeForwards;
    animation.beginTime = AVCoreAnimationBeginTimeAtZero;
    [mouseLayer addAnimation:animation forKey:@"keyframeAnimation_fish"];
}


@end
