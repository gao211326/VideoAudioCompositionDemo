# VideoAudioCompositionDemo
iOS 音频视频图像合成那点事
> 人而无信不知其可

##### 前言
很久很久没有写点什么了，只因为最近事情太多了，这几天终于闲下来了，趁此机会，记录下几个月前写的一个关于视频音频图片合成方面的一个小例子

##### 入场
先来看看实现的大概功能吧~

![功能介绍.png](https://upload-images.jianshu.io/upload_images/2525768-03d262810a756a6e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

由于其它功能不好制作gif，这里就先展示一个简单的水印图片
![水印.gif](https://upload-images.jianshu.io/upload_images/2525768-cdebd3e14bb569f1.gif?imageMogr2/auto-orient/strip)
下面就让我们一点点来分析分析

##### 需要了解什么
先来看一个关系图，字写的丑，将就着看吧....
![IMG_8292.JPG](https://upload-images.jianshu.io/upload_images/2525768-12edbb419a2e96c1.JPG?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

看着上面的图，是有点凌乱的感觉，下面我们就一点点来剥开。

##### 代码实现
根据需要实现的功能，我这里建了一个类，来分别实现不同的功能
```
@interface VideoAudioComposition : NSObject


/**
 合成后的名字
 */
@property (nonatomic,copy) NSString *compositionName;

/**
 合成类型
 */
@property (nonatomic,assign) CompositionType compositionType;


/**
 转换后的格式
 */
@property (nonatomic, copy) AVFileType outputFileType;


/**
 进度block
 */
@property (nonatomic,copy)CompositionProgress progressBlock;

/**
 视频音频合成

 @param videoUrl 视频地址
 @param videoTimeRange 截取时间
 @param audioUrl 音频地址
 @param audioTimeRange 截取时间
 @param successBlcok 成功回调
 */
- (void)compositionVideoUrl:(NSURL *)videoUrl videoTimeRange:(CMTimeRange)videoTimeRange audioUrl:(NSURL *)audioUrl audioTimeRange:(CMTimeRange)audioTimeRange success:(SuccessBlcok)successBlcok;


/**
 视频和视频合成

 @param videoUrl 视频地址
 @param videoTimeRange 截取时间
 @param mergeVideoUrl 视频地址
 @param mergeVideoTimeRange 截取时间
 @param successBlcok 成功回调
 */
- (void)compositionVideoUrl:(NSURL *)videoUrl videoTimeRange:(CMTimeRange)videoTimeRange mergeVideoUrl:(NSURL *)mergeVideoUrl mergeVideoTimeRange:(CMTimeRange)mergeVideoTimeRange success:(SuccessBlcok)successBlcok;


/**
 多个音频合成

 @param audios 音频地址
 @param timeRanges 截取时间（数组可为空：默认视为音频的起止时间，若不为空，则必须传入与audios数量相等的time）CMTimeRangeMake(kCMTimeZero, kCMTimeZero) 默认为起止时间
 @param successBlcok 成功回调
 */
- (void)compositionAudios:(NSArray <NSURL*>*)audios timeRanges:(NSArray<NSValue *> *)timeRanges success:(SuccessBlcok)successBlcok;


/**
 多个视频合成

 @param videos 视频地址
 @param timeRanges 截取时间（数组可为空：默认视为视频的起止时间，若不为空，则必须传入与audios数量相等的time）CMTimeRangeMake(kCMTimeZero, kCMTimeZero) 默认为起止时间
 @param successBlcok 成功回调
 */
- (void)compositionVideos:(NSArray <NSURL*>*)videos timeRanges:(NSArray<NSValue *> *)timeRanges success:(SuccessBlcok)successBlcok;
@end
```
实现代码
```
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

```

在该类中涉及的都是一些简单的音频与视频的合成，代码其实并不负复杂，难点就在于对涉及的类的理解与运用上面。针对上面的代码，就简单分析下。

`AVAsset`：应该指对应资源的资源信息
`AVURLAsset`：继承自`AVAsset`，获取对应资源的资源信息，如获取视频或者音频的信息
`AVMutableComposition` ：继承自`AVComposition`，而`AVComposition`继承自`AVAsset`，应该是专门用来合成音视频的合成器
`AVMutableCompositionTrack` ：继承自`AVCompositionTrack`，而`AVCompositionTrack`继承自`AVAssetTrack`，表示资源文件中的轨道，有音频轨、视频轨等，里面可以插入各种对应的素材；
`AVAssetTrack`：素材资源的相关轨道 
`AVAssetExportSession `：配置相应的渲染并进行输出
1、我们先从输出端一步一步看：
```
- (nullable instancetype)initWithAsset:(AVAsset *)asset presetName:(NSString *)presetName
```
上面是`AVAssetExportSession `的初始化函数，走初始化函数中，我们可以看到必须要有一个`AVAsset`对象，`presetName`为输出的质量，如下这些
```
AVF_EXPORT NSString *const AVAssetExportPresetLowQuality         NS_AVAILABLE(10_11, 4_0);
AVF_EXPORT NSString *const AVAssetExportPresetMediumQuality      NS_AVAILABLE(10_11, 4_0);
AVF_EXPORT NSString *const AVAssetExportPresetHighestQuality     NS_AVAILABLE(10_11, 4_0);
```
`AVMutableComposition`则继承自`AVAsset`，并且是用来合成视频音频的，所以我们完全可以通过输入该对象来实现音视频的合成。

2、在合成器`AVMutableComposition`有了之后，我们就需要向其中添加我们需要合成的音频或者视频通道了。
```
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
```
其中`AVMediaTypeAudio`代表音频通道，`AVMediaTypeVideo`为视频通道。
3、在音视频通道有了之后，我们需要获取我们需要插入的音视频资源
```
    // 音频采集
    AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];

    // 音频采集通道
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
```
4、在资源采集后，我们需要将其插入我们的音频或者视频通道中
```
            //  把采集轨道数据加入到可变轨道之中
            [audioTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:audioTimeRange.duration error:nil];
```
5、输出
```
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
```
注：在合成中还涉及的有`time`，这里就不细讲了，为了规避我们自己设置的时间超出了音视频本身的时间长度，这里我稍微做了下处理，过滤了下时间
```
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
```
##### 分割线
上面是简单的音视频的合成，有走视频中提取音频然后和其它音频进行合成，也有音频与音频的合成，视频与视频的合成....大概如下
```
typedef NS_ENUM(NSInteger,CompositionType) {
    VideoToVideo = 0,//视频加视频频-视频（可细分）
    VideoToAudio,//视频加视频-音频
    VideoAudioToVideo,//视频加音频-视频
    VideoAudioToAudio,//视频加音频-音频
    AudioToAudio,//音频加音频-音频
};
```
由于思路都差不多，只是需要进行提取对应的音频通道或者视频通道，然后进行时间的设置和进行对应的合并，所以这里就不在多讲，下面让我们继续往下看，看看`视频水印`、`图片合成视频`、`视频截图`等稍微复杂点的功能。

##### 来，继续看
针对这些功能，我又建了一个类，来单独处理
```
@interface VideoAudioEdit : NSObject

/**
 进度block
 */
@property (nonatomic,copy)CompositionProgress progressBlock;

/**
 截取视频某时刻的画面

 @param videoUrl 视频地址
 @param requestedTimes cmtime 数组
 */
- (void)getThumbImageOfVideo:(NSURL *_Nonnull)videoUrl forTimes:(NSArray<NSValue *> *_Nonnull)requestedTimes complete:(CompleteBlock _Nullable )complete;


/**
 将图片合成为视频

 @param images 图片数组
 @param videoName 视频名字
 @param successBlcok 视频地址
 */
- (void)compositionVideoWithImage:(NSArray <UIImage *>*_Nonnull)images videoName:(NSString *_Nonnull)videoName success:(SuccessBlcok _Nullable )successBlcok;



/**
 将图片合成为视频 并加上音乐

 @param images 图片数组
 @param videoName 视频名字
 @param audioUrl 音频地砖
 @param successBlcok 返回视频地址
 */
- (void)compositionVideoWithImage:(NSArray <UIImage *>*_Nonnull)images videoName:(NSString *_Nonnull)videoName audio:(NSURL*_Nullable)audioUrl success:(SuccessBlcok _Nullable )successBlcok;


/**
 视频水印

 @param videoUrl 视频地址
 @param videoName 视频名字
 @param successBlcok 返回
 */
- (void)watermarkForVideo:(NSURL *_Nonnull)videoUrl videoName:(NSString *_Nonnull)videoName success:(SuccessBlcok _Nullable )successBlcok;

@end
```
##### 截取视频某时刻的画面
这个应该是最简单的，先直接上源码
```
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
```
首先我们需要用到的类为`AVAssetImageGenerator`
`AVAssetImageGenerator`： 是用来提供视频的缩略图或预览视频的帧的类.
通过该类，我们可以获取视频的所有帧，那么在获取你想要的帧，那肯定不是什么难事了。
这里有几个参数
`requestedTimeToleranceAfter`和`requestedTimeToleranceBefore `：应该是指截图图片帧真实时间的一个浮动值，当然为了达到我们想要的时间，建议设置为`0`.
`maximumSize`：设置图片的尺寸
在设置后完成后，就可以直接调用函数
```
- (void)generateCGImagesAsynchronouslyForTimes:(NSArray<NSValue *> *)requestedTimes completionHandler:(AVAssetImageGeneratorCompletionHandler)handler;
```

##### 图片合成为视频
###### 先上个图
![样图.jpg](https://upload-images.jianshu.io/upload_images/2525768-48338395550fc455.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

我们先来了解下`AVAssetWriter`类：
`AVAssetWriter`类将媒体数据从多个源写入指定文件格式的单个文件。不需要将`asset writer`对象与特定的`asset`相关联，但必须为要创建的每个输出文件使用单独的`asset writer`。由于`asset writer`可以从多个源写入媒体数据，因此必须要为写入文件的每个track创建一个`AVAssetWriterInput`对象，每个`AVAssetWriterInput`期望以`CMSampleBufferRef`对象形式接收数据，但如果你想要将`CVPixelBufferRef`类型对象添加到`asset writer input`，就需要使用`AVAssetWriterInputPixelBufferAdaptor`类。

`AVAssetWriter`用于对媒体资源进行编码并将其写入到容器文件中，比如一个`MPEG-4`文件或`QuickTime`文件。它由一个或多个`AVAssetWriterInput`对象配置，用于附加将包含要写入容器的媒体样本的`CMSampleBufferRef`对象。`AVAssetWriterInput`被配置为可以处理指定的媒体类型，比如音频或视频，并且附加在其后的样本会在最终输出时生成一个独立的`AVAssetTrack`。当使用一个配置了处理视频样本`AVAssetWriterInput`时，开发者会经常用到一个专门的适配器对象`AVAssetWriterInputPixelBufferAdaptor`。这个类在附加被包装为`CVPixelBufferRef`对象的视频样本是提供最优性能。输入信息也可以通过使用[AVAssetWriterInputGroup](https://developer.apple.com/documentation/avfoundation/avassetwriterinputgroup)组成互斥的参数。这就让开发者能够创建特定资源，其中包含在播放时使用[AVMediaSelectionGroup](https://developer.apple.com/documentation/avfoundation/avmediaselectiongroup)和[AVMediaSelectionOption](https://developer.apple.com/documentation/avfoundation/avmediaselectionoption)类选择的指定语言媒体轨道。

注意：与上面我们用到的`AVAssetExportSession`相比，`AVAssetWriter`明显的优势就是它对输出进行编码时能够进行更加细致的压缩设置控制。可以让开发者指定诸如关键帧间隔、视频比特率、H.264配置文件、像素宽高比和纯净光圈等设置

在有了上面的了解之后，我们就可以动手了。
1、创建`AVAssetWriter`对象
```
    AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:outPutFilePath] fileType:AVFileTypeQuickTimeMovie error:&outError];
```
2、设置输出视频相关信息
```
    //视频尺寸
    CGSize size = CGSizeMake(320, 480);
    //meaning that it must contain AVVideoCodecKey, AVVideoWidthKey, and AVVideoHeightKey.
    //视频信息设置
    NSDictionary *outPutSettingDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                      AVVideoCodecTypeH264,AVVideoCodecKey,
                                      [NSNumber numberWithInt:size.width],AVVideoWidthKey,
                                      [NSNumber numberWithInt:size.height],AVVideoHeightKey, nil];

    AVAssetWriterInput *videoWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:outPutSettingDic];
```
3、设置输入信息
```
        NSDictionary *sourcePixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],kCVPixelBufferPixelFormatTypeKey, nil];
        
        AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributes];

```
由于我们是图片合成为视频，所以这里采用的是`CVPixelBufferRef`添加到`asset writer input`，故使用`AVAssetWriterInputPixelBufferAdaptor`.
4、进行资源写入合成视频
```
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
```
在上述代码中，有这么个函数
```
- (BOOL)appendPixelBuffer:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)presentationTime
```
该函数的功能就是添加帧，`presentationTime`代表输出文件中帧的时间，可以根据自己的需求来设置该事件。
注：在完成合成后，需要在主线程中进行其它操作。

##### 将图片合成为视频 并加上音乐
先上代码
```
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
```
这个代码有点长，下面让我们一点点来了解
1、由于这已经不是单纯的视频音频的合并，而是涉及通过写入的方式来输出多媒体，所以我们不能再用最开始的提取音视频通道来进行简单的合并，而是需要通过写入的方式来进行
2、图片合成视频我们已经知道方法，如果需要将音频也写入，那么我们首先要将音频读出，所以就有了下面的方法
3、音频采集
```
        // 音频采集
        AVURLAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
```
4、由于多媒体文件一般比较大，获取或计算出`Asset`中的属性非常耗时，`apple`对`Asset`的属性采用了懒惰加载模式。在创建`AVAsset`的时候，只生成一个实例，并不初始化属性。只有当第一次访问属性时，系统才会根据多媒体中的数据初始化这个属性。
由于不用同时加载所有属性，耗时问题得到了一定缓解。但是属性加载在计算量比较大的时候仍旧可能会阻塞线程。为了解决这个问题，`AVFoundation`提供了`AVAsynchronousKeyValueLoading`协议，可以异步加载属性：
```
- (void)loadValuesAsynchronouslyForKeys:(NSArray<NSString *> *)keys completionHandler:(nullable void (^)(void))handler;
```
这里我们只需要知道`tracks`属性，所以
```
[audioAsset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{

}];
```
5、将`track`里的数据读取出来，先进行设置
```
       NSDictionary *decompressionAudioSettings = @{AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM]};
       AVAssetReaderTrackOutput *assetReaderAudioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetAudioTrack outputSettings:decompressionAudioSettings];
                            if ([assetReader canAddOutput:assetReaderAudioOutput]) {
                                [assetReader addOutput:assetReaderAudioOutput];
                            }
```
6、设置输入信息，并写入音频，先进行设置
```
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
```
7、视频输入信息设置，不再累赘说明，代码中有详细说明
8、在设置完上诉信息后，我们就该进行读取和写入了，为了提高合成效率，这里我们采用异步并行执行，为了保证再两个输入都完成，这里采用了线程组的方式`dispatch_group_t`，大体步骤如下
```
dispatch_group_t dispatchGroup = dispatch_group_create();
//加入音频写入
dispatch_group_enter(dispatchGroup);
...
//音频写入操作
...
//和dispatch_group_enter成对出现 出队列
dispatch_group_leave(dispatchGroup);

//加入视频写入
dispatch_group_enter(dispatchGroup);
...
//视频写入操作
...
//和dispatch_group_enter成对出现 出队列
dispatch_group_leave(dispatchGroup);


//获取结果 得到输出地址 记得在主线程中进行操作
    dispatch_notify(dispatchGroup,mainSerializationQueue, ^{
        NSLog(@" 打印信息:+++++++");
        [assetWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                successBlcok([NSURL fileURLWithPath:outPutFilePath]);
            });
        }];
    });

```
在上述音频读取中，用到了
```
CMSampleBufferRef sampleBuffer = [assetReaderAudioOutput copyNextSampleBuffer];
```
`API`中是这么描述的
`Copies the next sample buffer for the output synchronously.`大概意思就是：同步复制输出的下一个示例缓冲区，即得到我们想要的数据

##### 视频水印处理
在水印处理之前，大家可以先看看文章上面我的手绘图，有这么几个类:
`AVMutableVideoComposition`：用来生成`video`的组合指令，包含多段`instruction`。可以决定最终视频的尺寸，裁剪需要在这里进行； 
`AVMutableVideoCompositionInstruction`：一个指令，决定一个`timeRange`内每个轨道的状态，包含多个`layerInstruction`； 
`AVMutableVideoCompositionLayerInstruction`：在一个指令的时间范围内，某个轨道的状态； 

先看看水印的核心代码
```
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
```
++++
```
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
```
其中
```
    mutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
```
则是设置水印的关键一步，这边将我们想要设置的水印`layer`添加到我们想要的视频中，其他关于`AVMutableVideoCompositionInstruction `和`AVMutableVideoCompositionLayerInstruction `的设置均是对视频的一些设置，可以有很多设置，大家有时间可以去了解下，我这里只是简单的设置了下。

##### 尾章
终于一口气写完，讲述的不是很详细，还请各位看官见谅！请忽略那个弹钢琴的视频...辣眼睛
由于`GitHub`上传文件的限制，导致工程中有几个视频和音频不能传上去，所以这里只好通过[网盘](https://pan.baidu.com/s/1IzuPea5sXaxOVr7lyNQkVQ)  密码:`mygj`


参考文章：[官方文档](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/05_Export.html)
