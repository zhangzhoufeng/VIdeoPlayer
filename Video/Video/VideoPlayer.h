//
//  VideoPlayer.h
//  Video
//
//  Created by 一公里 on 16/10/24.
//  Copyright © 2016年 小视频录制. All rights reserved.
//  视频播放类

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface VideoPlayer : NSObject
/**
 初始化播放器 必须实现
 @param playerView 承载播放器的View
 */
- (instancetype)initWithPlayerView:(UIView *)playerView videoUrl:(NSString *)videoUrl;
/**
 播放小视频
 */
- (void)startPlay;
/**
 暂停播放小视频
 */
- (void)pausePlay;
/**
 停止播放小视频
 */
- (void)stopPlay;
@end
