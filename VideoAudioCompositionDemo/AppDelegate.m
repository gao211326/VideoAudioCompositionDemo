//
//  AppDelegate.m
//  VideoAudioCompositionDemo
//
//  Created by 高磊 on 2018/1/17.
//  Copyright © 2018年 高磊. All rights reserved.
//

#import "AppDelegate.h"
#import <CommonCrypto/CommonDigest.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    NSString *tt1 = [self doubleMD5:@"___!LDA@qh#intf$-0971:[2018-01-24 17:54:55]"];
    NSString *tt = [self md5:@"Qhlda@189"];
    
    return YES;
}

- (NSString *)md5:(NSString *)content
{
    NSString *encryptStr = content;
    const char *cStr = [encryptStr UTF8String];
    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, strlen(cStr), result);
    
    NSString *sb = @"";
    
    for(int i = 0;i < CC_MD5_DIGEST_LENGTH;i ++){

        NSString *hexString = [NSString stringWithFormat:@"%d",result[i]];
        if (result[i] < 0) {
            int b = 256 + result[i];
            sb = [sb stringByAppendingString:[NSString stringWithFormat:@"%d",b]];
        }
        sb = [sb stringByAppendingString:hexString];
    }
    encryptStr = sb;
    return encryptStr;
}

- (NSString *)doubleMD5:(NSString *)content
{
    NSString *encryptStr = content;
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    NSString *sb = @"";
    
    for(int c = 0; c < 2 ;c ++){
        const char *cStr = [encryptStr UTF8String];
        CC_MD5(cStr, strlen(cStr), result);
        for(int i = 0;i < CC_MD5_DIGEST_LENGTH;i ++){
//            int restring = result[i]&0xff;
//            NSString *hexString = [NSString stringWithFormat:@"%d%d",restring,2];
            NSString *hexString = [NSString stringWithFormat:@"%x2",result[i]];
            if (hexString.length < 2) {
                sb = [sb stringByAppendingString:@"0"];
            }
            sb = [sb stringByAppendingString:hexString];
        }
        encryptStr = [NSString stringWithFormat:@"%@",sb];
        sb = @"";
    }
    return encryptStr;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
