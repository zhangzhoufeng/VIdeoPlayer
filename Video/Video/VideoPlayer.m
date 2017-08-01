//
//  VideoPlayer.m
//  Video
//
//  Created by 一公里 on 16/10/24.
//  Copyright © 2016年 小视频录制. All rights reserved.
//

#import "VideoPlayer.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoRequestSession.h"
@interface VideoPlayer ()

//@property (nonatomic, strong) UIView *playerView;
//@property (nonatomic, copy) NSString *videoUrl;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVURLAsset *videoAsset;
@property (nonatomic, assign) CGFloat videoLength;
// 呈现视频
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, strong) VideoRequestSession *session;
@property (nonatomic, strong) AVURLAsset     *videoURLAsset;

@end
@implementation VideoPlayer
/**
 初始化播放器 必须实现
 @param playerView 承载播放器的View
 */
- (instancetype)initWithPlayerView:(UIView *)playerView videoUrl:(NSString *)videoUrl{
    self = [super init];
    if (self) {
        [self initVideoPlayerWithPlayerView:playerView videoUrl:videoUrl];
    }
    return self;
}
/**
 播放小视频
 */
- (void)startPlay{
    dispatch_async(dispatch_get_main_queue(), ^{

        [self.player play];
    });
}
/**
 暂停播放小视频
 */
- (void)pausePlay{
   
    [self.player pause];
}
/**
 停止播放小视频
 */
- (void)stopPlay{
    
}
/**
 初始化视频播放器
 */
- (void)initVideoPlayerWithPlayerView:(UIView *)playerView videoUrl:(NSString *)videoUrl{
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![videoUrl hasPrefix:@"http"]) {
            // 1、获取媒体资源地址
            NSURL *sourceMovieURL = [NSURL fileURLWithPath:videoUrl];
            // 2、创建AVPlayerItem
            self.playerItem = [AVPlayerItem playerItemWithURL:sourceMovieURL];
            // 3、根据AVPlayerItem创建媒体播放器
            if (!self.player) {
                self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
            }else{
                [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
            }

        }else{
            self.session = [[VideoRequestSession alloc]init];
            NSURL *playUrl = [self.session getSchemeVideoURL:[NSURL URLWithString:videoUrl]];
            self.videoURLAsset             = [AVURLAsset URLAssetWithURL:playUrl options:nil];
            [_videoURLAsset.resourceLoader setDelegate:_session queue:dispatch_get_main_queue()];
            self.playerItem = [AVPlayerItem playerItemWithAsset:_videoURLAsset];
            if (!_player) {
                _player = [AVPlayer playerWithPlayerItem:_playerItem];
            } else {
                [_player replaceCurrentItemWithPlayerItem:_playerItem];
            }
        }
        // 4、创建AVPlayerLayer，用于呈现视频
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        // 5、设置显示大小和位置
        CALayer *layer = playerView.layer;
        self.playerLayer.frame = layer.bounds;
        // 6、设置拉伸模式
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [playerView.layer addSublayer:self.playerLayer];
        
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            float current=CMTimeGetSeconds(time);
            float total=CMTimeGetSeconds([strongSelf.playerItem duration]);
            NSLog(@"当前已经播放%.2fs.,总长:%.2fs",current,total);
            if (current == total) {
                if (strongSelf) {
                    [strongSelf playbackFinished];
                }
            }
        }];
        
        [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
        
    });

}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            [self startPlay];
        } else if ([playerItem status] == AVPlayerStatusFailed || [playerItem status] == AVPlayerStatusUnknown) {
            [self startPlay];
        }
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {  //监听播放器的下载进度
        
        
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) { //监听播放器在缓冲数据的状态
        if (playerItem.isPlaybackBufferEmpty) {
            [self bufferingSomeSecond];
        }
    }
}
- (void)bufferingSomeSecond{
    [self.player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.player play];
        if (!self.playerItem.isPlaybackLikelyToKeepUp) {
            [self bufferingSomeSecond];
        }
    });
}
-(void)playbackFinished{
    NSLog(@"视频播放完成.");
    // 播放完成后重复播放
    // 跳到最新的时间点开始播放
    // 使用延时操作是为了给播放器一个缓冲的时间
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.player seekToTime:CMTimeMake(0, 1)];
        [self.player play];
    });
}
@end
