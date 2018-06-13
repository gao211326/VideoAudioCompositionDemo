//
//  GLFolderManager.h
//  GLDownLoaderDemo
//
//  Created by 高磊 on 2017/12/8.
//  Copyright © 2017年 高磊. All rights reserved.
//  文件夹管理

#import <Foundation/Foundation.h>

@interface GLFolderManager : NSObject


/**
 获取沙盒Document的文件目录

 @return 返回
 */
+ (NSString *)getDocumentDirectory;

/**
 获取沙盒Library的文件目录

 @return 返回
 */
+ (NSString *)getLibraryDirectory;


/**
 获取沙盒Library/Caches的文件目录

 @return 返回
 */
+ (NSString *)getCachesDirectory;


/**
 获取沙盒Preference的文件目录

 @return 返回
 */
+ (NSString *)getPreferencePanesDirectory;


/**
 获取沙盒tmp的文件目录

 @return 返回
 */
+ (NSString *)getTmpDirectory;


/**
 创建缓存目录

 @param path 路径（默认为Document目录下）
 @return 返回文件夹路径
 */
+ (NSString *)createCacheFilePath:(NSString *)path;


/**
 判断文件是否存在

 @param path 文件路径
 @return 返回
 */
+ (BOOL)fileExistsAtPath:(NSString *)path;

/**
 根据路径返回目录或文件的大小

 @param path 路径
 @return 返回
 */
+ (double)sizeWithFilePath:(NSString *)path;


/**
 得到指定目录下的所有文件

 @param dirPath 指定目录
 @return 返回
 */
+ (NSArray *)getAllFileNames:(NSString *)dirPath;


/**
 删除指定目录或文件

 @param path 路径
 @return 返回
 */
+ (BOOL)clearCachesWithFilePath:(NSString *)path;


/**
 清空指定目录下文件

 @param dirPath 路径
 @return 返回
 */
+ (BOOL)clearCachesFromDirectoryPath:(NSString *)dirPath;


@end
