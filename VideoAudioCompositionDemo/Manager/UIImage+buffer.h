//
//  UIImage+buffer.h
//  VideoAudioCompositionDemo
//
//  Created by 高磊 on 2018/2/11.
//  Copyright © 2018年 高磊. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <CoreMedia/CMSampleBuffer.h>

@interface UIImage (buffer)


/**
 将UIImage转换为CVPixelBufferRef

 @param size 转化后的大小
 @return 返回CVPixelBufferRef
 */
- (CVPixelBufferRef)pixelBufferRefWithSize:(CGSize)size;


/**
 将CMSampleBufferRef转换为UIImage

 @param sampleBuffer  sampleBuffer数据
 @return 返回UIImage
 */
+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;


/**
 将CVPixelBufferRef转换为UIImage

 @param pixelBuffer pixelBuffer 数据
 @return 返回UIImage
 */
+ (UIImage*)imageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@end
