//
//  GLVideoConstant.h
//  VideoAudioCompositionDemo
//
//  Created by 高磊 on 2018/2/2.
//  Copyright © 2018年 高磊. All rights reserved.
//
#import <Foundation/Foundation.h>

#ifndef GLVideoConstant_h
#define GLVideoConstant_h

/**
 合成类型
 */
typedef NS_ENUM(NSInteger,CompositionType) {
    VideoToVideo = 0,//视频加视频频-视频（可细分）
    VideoToAudio,//视频加视频-音频
    VideoAudioToVideo,//视频加音频-视频
    VideoAudioToAudio,//视频加音频-音频
    AudioToAudio,//音频加音频-音频
};


/**
 合成成功block

 @param fileUrl 合成后的地址
 */
typedef void(^SuccessBlcok)(NSURL *fileUrl);


/**
 合成进度block

 @param progress 进度
 */
typedef void(^CompositionProgress)(CGFloat progress);


/**
 
 @param image 图片
 @param error 错误

 */
typedef  void(^CompleteBlock)(UIImage * _Nullable image,NSError * _Nullable error);

#endif /* GLVideoConstant_h */
