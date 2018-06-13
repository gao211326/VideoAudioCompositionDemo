//
//  VideoAudioComposition.h
//  VideoAudioCompositionDemo
//
//  Created by 高磊 on 2018/1/22.
//  Copyright © 2018年 高磊. All rights reserved.
//  音视频合成

#import <Foundation/Foundation.h>

#import <CoreMedia/CMTimeRange.h>
#import <AVFoundation/AVFoundation.h>

#import "GLVideoConstant.h"


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
