//
//  VideoPlayer.m
//  Video
//
//  Created by 一公里 on 16/10/24.
//  Copyright © 2016年 小视频录制. All rights reserved.
//

#import "ZFVideoPalyer.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
static ZFVideoPalyer *_videoPalyer = nil;
@interface ZFVideoPalyer ()
#define SCREEN_SIZE [UIScreen mainScreen].bounds.size
#define SLIDER_HEIGHT 40
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
// 呈现视频
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
//滑竿
@property (strong, nonatomic) UISlider *slider;
//已经播放时长
@property (strong, nonatomic) UILabel *videoPlayTime;
//总时长
@property (strong, nonatomic) UILabel *videoLength;
//进度条view
@property (strong, nonatomic) UIView *sliderView;
//缓冲进度条
@property (nonatomic, strong) UIProgressView *progressView;
//全屏播放
@property (strong, nonatomic) UIButton *screenBtn;
@property (nonatomic, strong) UIView *superView;
//滑竿在滑动中
@property (nonatomic, assign) BOOL sliderValueChange;
//视频正在播放中
@property (nonatomic, assign) BOOL playerIsPlay;
//隐藏进度条
@property (nonatomic, assign) BOOL sliderIsHidden;
//屏幕左旋转
@property (nonatomic, assign) BOOL screenIsLeft;
@end
@implementation ZFVideoPalyer

+ (instancetype)shareVideoPlayer{
    if (!_videoPalyer) {
        _videoPalyer = [[ZFVideoPalyer alloc]init];
    }
    return _videoPalyer;
}
/**
 初始化播放器 必须实现
 @param playerView 承载播放器的View
 */
- (instancetype)initWithPlayerView:(UIView *)playerView{
    self = [super init];
    if (self) {
        self.sliderValueChange = NO;
        self.playerIsPlay = NO;
        self.sliderIsHidden = NO;
        self.screenIsLeft = YES;
        playerView.clipsToBounds = YES;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor blackColor];
        self.superView = playerView;
        [self addGestureRecognizer];
//        self.videoUrl = @"http://video.jiecao.fm/8/17/%E6%8A%AB%E8%90%A8.mp4";
    }
    return self;
}

#pragma mark -- 初始化视频播放器
/**
 赋值视频地址
 */
- (void)setVideoUrl:(NSString *)videoUrl{
    _videoUrl = videoUrl;
    self.hidden = NO;
    self.videoPlayTime.text = @"00:00";
    self.videoLength.text = @"00:00";
    __weak __typeof(self) weakSelf = self;
    __block NSURL *sourceMovieURL = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;

        if (![videoUrl hasPrefix:@"http"]) {
            // 1、获取媒体资源地址
            sourceMovieURL = [NSURL fileURLWithPath:_videoUrl];
        }else{
            sourceMovieURL = [NSURL URLWithString:_videoUrl];
        }
        // 2、创建AVPlayerItem
        strongSelf.playerItem = [AVPlayerItem playerItemWithURL:sourceMovieURL];
        // 3、根据AVPlayerItem创建媒体播放器
        if (!strongSelf.player) {
            strongSelf.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        }else{
            [strongSelf.player replaceCurrentItemWithPlayerItem:strongSelf.playerItem];
        }
        // 4、创建AVPlayerLayer，用于呈现视频
        strongSelf.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        // 5、设置显示大小和位置
        [strongSelf playerFrame:strongSelf.superView];
        // 6、设置拉伸模式
        strongSelf.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        //zPosition 默认值是0，值越高view的层级就越高，值越低就越低，因此我设置为-1,就在最下层。不会盖住其他的view。
        strongSelf.playerLayer.zPosition = -1;
        [strongSelf.layer addSublayer:strongSelf.playerLayer];
        
        //监测播放进度
        [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            
            if (strongSelf.playerItem.isPlaybackLikelyToKeepUp) {
                float current=CMTimeGetSeconds(time);
                float total=CMTimeGetSeconds([strongSelf.playerItem duration]);
                if (strongSelf.slider.value == 0) {
                    strongSelf.slider.maximumValue = total;
                    strongSelf.videoLength.text = [strongSelf timeValue:total];
                }
                if (!strongSelf.sliderValueChange) {
                    strongSelf.slider.value = current;
                }
                strongSelf.videoPlayTime.text = [strongSelf timeValue:current];
                NSLog(@"当前已经播放%.2fs.,总长:%.2fs",current,total);
                if (current == total) {
                    if (strongSelf) {
                        strongSelf.slider.value = 0;
                        strongSelf.videoPlayTime.text = @"00:00";
                        strongSelf.videoLength.text = @"00:00";
                        [strongSelf playbackFinished];
                    }
                }
            }
        }];
    });

}
#pragma mark -- 播放器监听响应事件
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            NSLog(@"开始播放");
//            [self startPlay];
        } else if ([playerItem status] == AVPlayerStatusFailed || [playerItem status] == AVPlayerStatusUnknown) {
            NSLog(@"播放错误");
        }
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {  //监听播放器的下载进度
        // 计算缓冲进度
        NSArray *loadedTimeRanges = [playerItem loadedTimeRanges];
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval timeInterval = startSeconds + durationSeconds;// 计算缓冲总进度
        CMTime duration = playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        [self.progressView setProgress:timeInterval / totalDuration animated:NO];        
        
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        NSLog(@"缓存不足了");
        if (playerItem.isPlaybackBufferEmpty) {
            [self.player pause];
        }
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        
        NSLog(@"缓冲达到可播放程度了");
        //由于 AVPlayer 缓存不足就会自动暂停，所以缓存充足了需要手动播放，才能继续播放
        if (self.playerItem.isPlaybackLikelyToKeepUp) {
            [self.player play];
        }
    }
}
#pragma mark -- 屏幕旋转响应事件
- (void)orientChange:(NSNotification *)noti
{
    UIDeviceOrientation  orient = [UIDevice currentDevice].orientation;
    switch (orient) {
        case UIDeviceOrientationLandscapeLeft:
            self.screenIsLeft = YES;
            self.screenBtn.selected = NO;
            break;
        case UIDeviceOrientationLandscapeRight:
            self.screenIsLeft = NO;
            self.screenBtn.selected = NO;
            break;
        default:
            self.screenIsLeft = YES;
            self.screenBtn.selected = YES;
            break;
    }
    [self screenPlay:self.screenBtn];
}
#pragma mark -- 触发事件
/**
 滑竿滑动结束
 */
- (void)sliderTouchUp:(UISlider *)sender {
    self.sliderValueChange = NO;
    int64_t value = roundf(sender.value);
    [self.player seekToTime:CMTimeMake(value, 1)];
}
/**
 滑竿滑动中
 */
- (void)sliderValueChange:(UISlider *)sender {
    self.sliderValueChange = YES;
    self.videoPlayTime.text = [self timeValue:sender.value];
}
/**
 全屏播放
 */
- (void)screenPlay:(UIButton *)sender{
    sender.selected = !sender.selected;
    if (sender.selected) {
        if (self.screenIsLeft) {
            [UIView animateWithDuration:0.25 animations:^{
                self.transform = CGAffineTransformMakeRotation(M_PI/2);
            }];
        }else{
            [UIView animateWithDuration:0.25 animations:^{
                self.transform = CGAffineTransformMakeRotation(-M_PI/2);
            }];
        }
        
        [self playerFrame:[[UIApplication sharedApplication] keyWindow]];
    }else{
        [UIView animateWithDuration:0.25 animations:^{
            self.transform = CGAffineTransformMakeRotation(0);
        }];
        [self playerFrame:self.superView];
    }
    [[UIApplication sharedApplication] setStatusBarHidden:sender.selected withAnimation:UIStatusBarAnimationSlide];
}
/**
 播放视频
 */
- (void)startPlay{
    if (self.playerIsPlay) {
        return;
    }
    
    [self addPlayItemNotification];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playerIsPlay = YES;
        [self.player play];
    });
}
/**
 暂停视频
 */
- (void)pausePlay{
    if (!self.playerIsPlay) {
        return;
    }
    [self removePlayItemNotification];
    self.playerIsPlay = NO;
    [self.player pause];
}
/**
 停止播放小视频
 */
- (void)stopPlay{
    [self pausePlay];
    self.hidden = YES;
    [self.playerLayer removeFromSuperlayer];
}
#pragma mark -- 添加手势
- (void)addGestureRecognizer{
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapClick:)];
    tap.numberOfTapsRequired=1;//单击
    tap.numberOfTouchesRequired=1;//单点触碰
    [self addGestureRecognizer:tap];
    UITapGestureRecognizer *doubleTap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.numberOfTapsRequired=2;
    [self addGestureRecognizer:doubleTap];
    //避免单击与双击冲突
    [tap requireGestureRecognizerToFail:doubleTap];
}
#pragma mark -- 手势触发事件
/**
 view单击事件
 */
- (void)tapClick:(UITapGestureRecognizer *)tap{
    if (!self.sliderIsHidden) {
        [UIView animateWithDuration:0.4 animations:^{
            [self.sliderView setTransform:CGAffineTransformMakeTranslation(0, SLIDER_HEIGHT)];
        }];
    }else{
        [UIView animateWithDuration:0.4 animations:^{
            [self.sliderView setTransform:CGAffineTransformMakeTranslation(0, 0)];
        }];
    }
    self.sliderIsHidden = !self.sliderIsHidden;
}
/**
 view双击事件
 */
- (void)doubleTap:(UITapGestureRecognizer *)tap{
    if (self.playerIsPlay) {
        [self pausePlay];
    }else{
        [self startPlay];
    }
}
#pragma mark -- 调整view大小
/**
 设置显示大小和位置
 */
- (void)playerFrame:(UIView *)superView{
    if (superView.bounds.size.height == SCREEN_SIZE.height) {
        self.playerLayer.frame = CGRectMake(0, 0, superView.bounds.size.height, superView.bounds.size.width);
    }else{
        self.playerLayer.frame = superView.bounds;
    }
    self.frame = superView.bounds;
    self.sliderView.frame = CGRectMake(0, self.playerLayer.frame.size.height - SLIDER_HEIGHT, self.playerLayer.frame.size.width, SLIDER_HEIGHT);
    self.videoPlayTime.frame = CGRectMake(0, 0, 50, SLIDER_HEIGHT);
    self.slider.frame = CGRectMake(50, 0, self.sliderView.frame.size.width - 100 - SLIDER_HEIGHT, SLIDER_HEIGHT);
    self.progressView.frame = CGRectMake(52, SLIDER_HEIGHT/2.0 - 1, self.sliderView.frame.size.width - 104 - SLIDER_HEIGHT, 0);
    self.videoLength.frame = CGRectMake(self.sliderView.frame.size.width - 50 - SLIDER_HEIGHT, 0, 50, SLIDER_HEIGHT);
    self.screenBtn.frame = CGRectMake(self.sliderView.frame.size.width - SLIDER_HEIGHT, 0, SLIDER_HEIGHT, SLIDER_HEIGHT);

    [superView addSubview:self];
}
/**
 视频播放完成
 */
-(void)playbackFinished{
    NSLog(@"视频播放完成.");
    // 播放完成后重复播放
    // 跳到最新的时间点开始播放
    // 使用延时操作是为了给播放器一个缓冲的时间
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.player seekToTime:kCMTimeZero];
        [self.player play];
    });
}
/**
 时间计算
 */
- (NSString *)timeValue:(float)value{
    NSInteger intValue = value;
    if (value < 60) {
        return [NSString stringWithFormat:@"00:%@%ld",intValue < 10 ? @"0" : @"",intValue];
    }else if (value < 3600){
        return [NSString stringWithFormat:@"%@%ld:%@%ld",intValue/60 < 10 ? @"0" : @"",intValue/60,intValue%60 < 10 ? @"0" : @"",intValue%60];
    }else{
        return [NSString stringWithFormat:@"%@%ld:%@%ld:%@%ld",intValue/3600 < 10 ? @"0" : @"",intValue/3600,intValue%3600/60 < 10 ? @"0" : @"",intValue%3600/60,intValue%3600%60 < 10 ? @"0" : @"",intValue%3600%60];
    }
    return @"";
}
#pragma mark -- 播放器监听 添加 与 移除
/**
 添加播放器监听
 */
- (void)addPlayItemNotification{
    //添加监听
//    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
//    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
//    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
//    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    //屏幕旋转
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}
/**
 移除播放器监听
 */
- (void)removePlayItemNotification{
//    [self.playerItem removeObserver:self forKeyPath:@"status"];
//    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
//    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
//    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
#pragma mark -- 懒加载
- (UIView *)sliderView{
    if (!_sliderView) {
        _sliderView = [UIView new];
        _sliderView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        _sliderView.userInteractionEnabled = YES;
        [_sliderView addSubview:self.videoPlayTime];
        [_sliderView addSubview:self.progressView];
        [_sliderView addSubview:self.slider];
        [_sliderView addSubview:self.videoLength];
        [_sliderView addSubview:self.screenBtn];
        [self addSubview:_sliderView];
    }
    return _sliderView;
}
/**
 已播放时长
 */
- (UILabel *)videoPlayTime{
    if (!_videoPlayTime) {
        _videoPlayTime = [UILabel new];
        _videoPlayTime.text = @"00:00";
        _videoPlayTime.font = [UIFont systemFontOfSize:10];
        _videoPlayTime.textAlignment = NSTextAlignmentCenter;
        _videoPlayTime.textColor = [UIColor whiteColor];
    }
    return _videoPlayTime;
}
/**
 视频总长度
 */
- (UILabel *)videoLength{
    if (!_videoLength) {
        _videoLength = [UILabel new];
        _videoLength.text = @"00:00";
        _videoLength.font = [UIFont systemFontOfSize:10];
        _videoLength.textAlignment = NSTextAlignmentCenter;
        _videoLength.textColor = [UIColor whiteColor];
    }
    return _videoLength;
}
/**
 滑块
 */
- (UISlider *)slider{
    if (!_slider) {
        _slider = [UISlider new];
        _slider.minimumValue = 0;
        _slider.value = 0;
        [_slider setThumbImage:[UIImage imageNamed:@"我的收藏"] forState:UIControlStateNormal];
        [_slider setThumbImage:[UIImage imageNamed:@"我的收藏"] forState:UIControlStateSelected];
        _slider.maximumTrackTintColor = [UIColor clearColor];
        [_slider addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [_slider addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
    }
    return _slider;
}
/**
 缓存进度条
 */
- (UIProgressView *)progressView{
    if(!_progressView){
        _progressView = [UIProgressView new];
        //进度条颜色
        _progressView.trackTintColor = [UIColor lightGrayColor];
        _progressView.progressTintColor = [UIColor whiteColor];
    }
    return _progressView;
}
/**
 全屏播放按钮
 */
- (UIButton *)screenBtn{
    if (!_screenBtn) {
        _screenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_screenBtn setImage:[UIImage imageNamed:@"fullScreen"] forState:UIControlStateNormal];
        [_screenBtn setImage:[UIImage imageNamed:@"fullScreen"] forState:UIControlStateSelected];
        [_screenBtn addTarget:self action:@selector(screenPlay:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _screenBtn;
}
/**
 视频正在缓存中(暂时不用了)
 */
- (void)bufferingSomeSecond{
    [self.player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.player play];
        if (!self.playerItem.isPlaybackLikelyToKeepUp) {
            [self bufferingSomeSecond];
        }
    });
}
- (void)dealloc{
    [self removePlayItemNotification];
}

@end
