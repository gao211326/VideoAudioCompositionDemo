//
//  ArcToCircleLayer.h
//  RequestDemo
//
//  Created by 高磊 on 16/5/15.
//  Copyright © 2016年 高磊. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface GLProgressLayer : CALayer

@property (nonatomic) CGFloat progress;


/**
 显示加载进度
 @return 返回
 */
+ (GLProgressLayer *)showProgress;


/**
 隐藏加载
 */
- (void)hiddenProgress;

@end
