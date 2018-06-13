//
//  ArcToCircleLayer.m
//  RequestDemo
//
//  Created by 高磊 on 16/5/15.
//  Copyright © 2016年 高磊. All rights reserved.
//

#import "GLProgressLayer.h"

#import <UIKit/UIKit.h>

static CGFloat kLineWidth = 4;

@interface GLProgressLayer ()

@property (nonatomic,strong) UIView *maskView;

@end

@implementation GLProgressLayer

@dynamic progress;

+ (GLProgressLayer *)showProgress
{
    UIView *windowView = [UIApplication sharedApplication].delegate.window.rootViewController.view;
    
    GLProgressLayer *progressLayer = [GLProgressLayer layer];
    progressLayer.maskView = [[UIView alloc] initWithFrame:windowView.bounds];
    progressLayer.maskView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.05];
    [windowView addSubview:progressLayer.maskView];
    
    progressLayer.frame = (CGRect){CGPointZero,CGSizeMake(80, 80)};
    progressLayer.position = CGPointMake(CGRectGetMidX(progressLayer.maskView.bounds), CGRectGetMidY(progressLayer.maskView.bounds));
    [progressLayer.maskView.layer addSublayer:progressLayer];
    
    return progressLayer;
}

- (void)hiddenProgress
{
    [self.maskView removeFromSuperview];
    self.maskView = nil;
}

+ (BOOL)needsDisplayForKey:(NSString *)key {
    if ([key isEqualToString:@"progress"]) {
        return YES;
    }
    return [super needsDisplayForKey:key];
}

- (void)drawInContext:(CGContextRef)ctx {
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    CGFloat radius = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) / 2 - kLineWidth / 2;
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

    //进度环
    [path addArcWithCenter:center radius:radius startAngle:0 endAngle:2 * M_PI clockwise:YES];
    CGContextAddPath(ctx, path.CGPath);
    CGContextSetLineWidth(ctx, kLineWidth);
    CGContextSetStrokeColorWithColor(ctx, [UIColor grayColor].CGColor);
    CGContextStrokePath(ctx);
    
    //进度条1
    UIBezierPath *progressPath = [UIBezierPath bezierPath];
    CGFloat to = - M_PI * 0.5 + self.progress * M_PI * 2 ;
    [progressPath addArcWithCenter:center radius:radius startAngle:- M_PI * 0.5 endAngle:to clockwise:YES];
    CGContextAddPath(ctx, progressPath.CGPath);
    CGContextSetLineWidth(ctx, kLineWidth);
    CGContextSetStrokeColorWithColor(ctx, [UIColor orangeColor].CGColor);
    CGContextStrokePath(ctx);
    
    
    //进度条2 面积类型
//    CGContextMoveToPoint(ctx, center.x, center.y);
//    CGContextAddLineToPoint(ctx, center.x, 0);
//    CGFloat to = - M_PI * 0.5 + self.progress * M_PI * 2 ; // 初始值
//    CGContextAddArc(ctx, center.x, center.y, radius, - M_PI * 0.5, to, 0);
//    CGContextSetFillColorWithColor(ctx, [UIColor lightGrayColor].CGColor);
//    CGContextClosePath(ctx);
//    CGContextFillPath(ctx);
    
    //在layer上绘制文字
    UIGraphicsPushContext(ctx);
    {
        // 进度数字
        NSString *progressStr = [NSString stringWithFormat:@"%.2f%s", self.progress * 100, "\%"];
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:12];
        attributes[NSForegroundColorAttributeName] = [UIColor blackColor];
        [self setCenterProgressText:progressStr withAttributes:attributes];
    }
    UIGraphicsPopContext();

}

- (void)setCenterProgressText:(NSString *)text withAttributes:(NSDictionary *)attributes
{
    CGFloat xCenter = self.frame.size.width * 0.5;
    CGFloat yCenter = self.frame.size.height * 0.5;
    
    // 判断系统版本
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0) {
        CGSize strSize = [text sizeWithAttributes:attributes];
        CGFloat strX = xCenter - strSize.width * 0.5;
        CGFloat strY = yCenter - strSize.height * 0.5;
        [text drawAtPoint:CGPointMake(strX, strY) withAttributes:attributes];
    }
}

@end
