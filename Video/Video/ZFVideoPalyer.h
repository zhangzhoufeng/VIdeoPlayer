//
//  ZFViewPalyer.h
//  Video
//
//  Created by 一公里 on 2016/11/23.
//  Copyright © 2016年 小视频录制. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^VideoFinished)();
@interface ZFVideoPalyer : UIView

@property (nonatomic, copy) NSString *videoUrl;
+ (instancetype)shareVideoPlayer;

/**
 初始化播放器 必须实现
 @param playerView 承载播放器的View
 */
- (instancetype)initWithPlayerView:(UIView *)playerView;
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
