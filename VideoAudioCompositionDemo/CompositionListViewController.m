//
//  CompositionListViewController.m
//  VideoAudioCompositionDemo
//
//  Created by 高磊 on 2018/1/25.
//  Copyright © 2018年 高磊. All rights reserved.
//

#import "CompositionListViewController.h"
#import "ViewController.h"
#import "VideoAudioComposition.h"
#import "GLProgressLayer.h"
#import "VideoAudioEdit.h"

@interface CompositionListViewController ()

@property (nonatomic,strong) NSMutableArray *dataSource;

@property (nonatomic,strong) GLProgressLayer *progressLayer;

@property (nonatomic,strong) NSMutableArray *images;

@end

@implementation CompositionListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.rowHeight = 60;
    self.dataSource = [NSMutableArray arrayWithObjects:@"视频加视频频-视频",@"视频加视频-音频",@"视频加音频-视频",@"视频加音频-音频",@"音频加音频-音频",@"截取视频帧",@"多张图片-视频",@"多张图片+音乐-视频",@"视频加水印效果", nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"compositionCell" forIndexPath:indexPath];
    
    cell.textLabel.text = self.dataSource[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
        case 0:
        {
//            NSURL *audioInputUrl1 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"5" ofType:@"mp4"]];
//            // 视频来源
//            NSURL *videoInputUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"大王叫我来巡山" ofType:@"mp4"]];
            
            self.progressLayer = [GLProgressLayer showProgress];
            
            NSURL *audioInputUrl1 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"1" ofType:@"mp4"]];
            // 视频来源
            NSURL *videoInputUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"piano" ofType:@"mp4"]];

            
            VideoAudioComposition *videoAudioManager = [[VideoAudioComposition alloc] init];
            videoAudioManager.compositionName = @"merge1112.mp4";
            videoAudioManager.compositionType = VideoToVideo;
            __weak typeof(self)weakSelf = self;
            [videoAudioManager compositionVideoUrl:videoInputUrl
                                    videoTimeRange:CMTimeRangeMake(kCMTimeZero, kCMTimeZero)
                                     mergeVideoUrl:audioInputUrl1
                               mergeVideoTimeRange:CMTimeRangeMake(kCMTimeZero, kCMTimeZero)
                                           success:^(NSURL *fileUrl) {
                [weakSelf.progressLayer hiddenProgress];
                ViewController *vc = [[ViewController alloc] init];
                [weakSelf.navigationController pushViewController:vc animated:YES];
                [vc playWithUrl:fileUrl];
            }];
        
            videoAudioManager.progressBlock = ^(CGFloat progress) {
                weakSelf.progressLayer.progress = progress;
            };
        }
            break;
        case 1:
        {
            NSURL *audioInputUrl1 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"大王叫我来巡山" ofType:@"mp4"]];
            // 视频来源
            NSURL *videoInputUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"5" ofType:@"mp4"]];
            
            self.progressLayer = [GLProgressLayer showProgress];
            
            VideoAudioComposition *videoAudioManager = [[VideoAudioComposition alloc] init];
            videoAudioManager.compositionName = @"merge1.m4a";
            videoAudioManager.compositionType = VideoToAudio;
            __weak typeof(self)weakSelf = self;
            [videoAudioManager compositionVideoUrl:videoInputUrl
                                    videoTimeRange:CMTimeRangeMake(kCMTimeZero, kCMTimeZero)
                                     mergeVideoUrl:audioInputUrl1
                               mergeVideoTimeRange:CMTimeRangeMake(kCMTimeZero, kCMTimeZero)
                                           success:^(NSURL *fileUrl) {
                [weakSelf.progressLayer hiddenProgress];
                ViewController *vc = [[ViewController alloc] init];
                [weakSelf.navigationController pushViewController:vc animated:YES];
                [vc playWithUrl:fileUrl];
            }];
            
            videoAudioManager.progressBlock = ^(CGFloat progress) {
                weakSelf.progressLayer.progress = progress;
            };
        }
            break;
        case 2:
        {
            NSURL *audioInputUrl1 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Kim Taylor-I Am You" ofType:@"mp3"]];
            // 视频来源
            NSURL *videoInputUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"大王叫我来巡山" ofType:@"mp4"]];
            
            self.progressLayer = [GLProgressLayer showProgress];
            
            VideoAudioComposition *videoAudioManager = [[VideoAudioComposition alloc] init];
            videoAudioManager.compositionName = @"test_1.mp4";
            videoAudioManager.compositionType = VideoAudioToVideo;
            __weak typeof(self)weakSelf = self;
//            CMTimeMakeWithSeconds(<#Float64 seconds#>, <#int32_t preferredTimescale#>)
            [videoAudioManager compositionVideoUrl:videoInputUrl
                                    videoTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(30, 1))
                                          audioUrl:audioInputUrl1
                                    audioTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(30, 1))
                                           success:^(NSURL *fileUrl) {
                [weakSelf.progressLayer hiddenProgress];
                ViewController *vc = [[ViewController alloc] init];
                [weakSelf.navigationController pushViewController:vc animated:YES];
                [vc playWithUrl:fileUrl];
            }];
            
            videoAudioManager.progressBlock = ^(CGFloat progress) {
                weakSelf.progressLayer.progress = progress;
            };
        }
            break;
        case 3:
        {
            NSURL *audioInputUrl1 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Kim Taylor-I Am You" ofType:@"mp3"]];
            // 视频来源
            NSURL *videoInputUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"大王叫我来巡山" ofType:@"mp4"]];
            
            self.progressLayer = [GLProgressLayer showProgress];

            VideoAudioComposition *videoAudioManager = [[VideoAudioComposition alloc] init];
            videoAudioManager.compositionName = @"merge11.m4a";
            videoAudioManager.compositionType = VideoAudioToAudio;
            __weak typeof(self)weakSelf = self;
            [videoAudioManager compositionVideoUrl:videoInputUrl
                                    videoTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(30, 1))
                                          audioUrl:audioInputUrl1
                                    audioTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(30, 1))
                                           success:^(NSURL *fileUrl) {
                [weakSelf.progressLayer hiddenProgress];
                ViewController *vc = [[ViewController alloc] init];
                [weakSelf.navigationController pushViewController:vc animated:YES];
                [vc playWithUrl:fileUrl];
            }];
            
            videoAudioManager.progressBlock = ^(CGFloat progress) {
                weakSelf.progressLayer.progress = progress;
            };
        }
            break;
        case 4:
        {
            NSURL *audioInputUrl1 = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Kim Taylor-I Am You" ofType:@"mp3"]];
            // 视频来源
            NSURL *videoInputUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"爱在记忆中找你" ofType:@"mp3"]];
            
            self.progressLayer = [GLProgressLayer showProgress];
            
            VideoAudioComposition *videoAudioManager = [[VideoAudioComposition alloc] init];
            videoAudioManager.compositionName = @"testMusic.m4a";

            __weak typeof(self)weakSelf = self;
            [videoAudioManager compositionAudios:@[audioInputUrl1,videoInputUrl]
                                      timeRanges:nil
                                         success:^(NSURL *fileUrl) {
                [weakSelf.progressLayer hiddenProgress];
                ViewController *vc = [[ViewController alloc] init];
                [weakSelf.navigationController pushViewController:vc animated:YES];
                [vc playWithUrl:fileUrl];
            }];
            
            videoAudioManager.progressBlock = ^(CGFloat progress) {
                weakSelf.progressLayer.progress = progress;
            };
        }
            break;
        case 5:
        {
            //
            self.progressLayer = [GLProgressLayer showProgress];
            __weak typeof(self)weakSelf = self;
            VideoAudioEdit *videoManager = [[VideoAudioEdit alloc] init];
            [videoManager getThumbImageOfVideo:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"大王叫我来巡山" ofType:@"mp4"]]
                                      forTimes:@[[NSValue valueWithCMTime:CMTimeMakeWithSeconds(15, NSEC_PER_SEC)]]
                                      complete:^(UIImage * _Nullable image, NSError * _Nullable error)
            {
                [weakSelf.progressLayer hiddenProgress];
                
                [weakSelf.images addObject:image];
                

                ViewController *vc = [[ViewController alloc] init];
                [vc setImages:weakSelf.images];
                [weakSelf.navigationController pushViewController:vc animated:YES];

            }];
            
            videoManager.progressBlock = ^(CGFloat progress) {
                weakSelf.progressLayer.progress = progress;
            };
        }
            break;
        case 6:
        {
            //
            self.progressLayer = [GLProgressLayer showProgress];
            NSMutableArray *images = [[NSMutableArray alloc] init];
            for (int i = 0; i < 11; i++) {
                [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"img%d.jpg",i]]];
            }
            __weak typeof(self)weakSelf = self;
            
            NSMutableArray *imageArray = [[NSMutableArray alloc] init];
            for (int i = 0; i<images.count; i++) {
                UIImage *imageNew = images[i];
                //设置image的尺寸
                CGSize imagesize = imageNew.size;
                imagesize.height =480;
                imagesize.width =320;
                //对图片大小进行压缩--
                imageNew = [self imageWithImage:imageNew scaledToSize:imagesize];
                [imageArray addObject:imageNew];
            }
            
            VideoAudioEdit *videoManager = [[VideoAudioEdit alloc] init];
            [videoManager compositionVideoWithImage:imageArray
                                          videoName:@"video_image.mov"
                                            success:^(NSURL *fileUrl) {
                [weakSelf.progressLayer hiddenProgress];
                ViewController *vc = [[ViewController alloc] init];
                [weakSelf.navigationController pushViewController:vc animated:YES];
                [vc playWithUrl:fileUrl];
            }];
            
            videoManager.progressBlock = ^(CGFloat progress) {
                weakSelf.progressLayer.progress = progress;
            };
        }
            break;
            case 7:
        {
            //
            self.progressLayer = [GLProgressLayer showProgress];
            NSMutableArray *images = [[NSMutableArray alloc] init];
            for (int i = 0; i < 11; i++) {
                [images addObject:[UIImage imageNamed:[NSString stringWithFormat:@"img%d.jpg",i]]];
            }
            __weak typeof(self)weakSelf = self;
            
            NSMutableArray *imageArray = [[NSMutableArray alloc] init];
            for (int i = 0; i<images.count; i++) {
                UIImage *imageNew = images[i];
                //设置image的尺寸
                CGSize imagesize = imageNew.size;
                imagesize.height =480;
                imagesize.width =320;
                //对图片大小进行压缩--
                imageNew = [self imageWithImage:imageNew scaledToSize:imagesize];
                [imageArray addObject:imageNew];
            }
            
            NSURL *videoInputUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"爱在记忆中找你" ofType:@"mp3"]];
            VideoAudioEdit *videoManager = [[VideoAudioEdit alloc] init];
            [videoManager compositionVideoWithImage:imageArray
                                          videoName:@"test.mov"
                                              audio:videoInputUrl
                                            success:^(NSURL *fileUrl) {
                [weakSelf.progressLayer hiddenProgress];
                ViewController *vc = [[ViewController alloc] init];
                [weakSelf.navigationController pushViewController:vc animated:YES];
                [vc playWithUrl:fileUrl];
            }];
            
            videoManager.progressBlock = ^(CGFloat progress) {
                weakSelf.progressLayer.progress = progress;
            };
        }
            break;
        case 8:
        {
            self.progressLayer = [GLProgressLayer showProgress];
            
            NSURL *videoInputUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"piano" ofType:@"mp4"]];
            VideoAudioEdit *videoManager = [[VideoAudioEdit alloc] init];
            __weak typeof(self)weakSelf = self;
            [videoManager watermarkForVideo:videoInputUrl videoName:@"淡出.mov" success:^(NSURL *fileUrl){
                [weakSelf.progressLayer hiddenProgress];
                 ViewController *vc = [[ViewController alloc] init];
                 [weakSelf.navigationController pushViewController:vc animated:YES];
                 [vc playWithUrl:fileUrl];
             }];
            
            videoManager.progressBlock = ^(CGFloat progress) {
                weakSelf.progressLayer.progress = progress;
            };
        }
            break;
        default:
            break;
    }
}

-(UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize
{
    //    新创建的位图上下文 newSize为其大小
    UIGraphicsBeginImageContext(newSize);
    //    对图片进行尺寸的改变
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    //    从当前上下文中获取一个UIImage对象  即获取新的图片对象
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    // Return the new image.
    return newImage;
}
#pragma mark == 懒加载
- (NSMutableArray *)dataSource
{
    if (nil == _dataSource) {
        _dataSource = [[NSMutableArray alloc] init];
    }
    return _dataSource;
}

- (NSMutableArray *)images
{
    if (nil == _images) {
        _images = [[NSMutableArray alloc] init];
    }
    return _images;
}

@end
