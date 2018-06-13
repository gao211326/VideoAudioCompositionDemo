//
//  VideoAudioEdit.h
//  VideoAudioCompositionDemo
//
//  Created by 高磊 on 2018/2/1.
//  Copyright © 2018年 高磊. All rights reserved.
//  视频裁剪、水印等

#import <Foundation/Foundation.h>
#import <CoreMedia/CMTimeRange.h>
#import <AVFoundation/AVFoundation.h>
#import "GLVideoConstant.h"


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
