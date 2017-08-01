//
//  ViewController.m
//  Video
//
//  Created by 一公里 on 16/10/19.
//  Copyright © 2016年 小视频录制. All rights reserved.
//

#import "ViewController.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ZFVideoPalyer.h"
#import "RecordSession.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,CAAnimationDelegate>
@property (nonatomic, strong) UIView *layerView;
@property (nonatomic, strong) ZFVideoPalyer *videoPlayer;
@property (nonatomic, strong) RecordSession *session;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) NSInteger playRow;
@property (nonatomic, assign) NSInteger pauseRow;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *recorde;
@property (nonatomic, strong) CAShapeLayer *arcLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.layerView = [[UIView alloc]initWithFrame:CGRectMake(0, 50, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width * 0.7)];
    [self.view addSubview:self.layerView];
    self.session = [[RecordSession alloc]initWithSessionView:self.layerView];
    self.videoPlayer = [[ZFVideoPalyer alloc]initWithPlayerView:self.layerView];
}
- (IBAction)touchDown:(UIButton *)sender {
    [self.arcLayer removeFromSuperlayer];
    self.messageLabel.hidden = NO;
    self.messageLabel.text = @"滑动手指 取消发送";
    NSLog(@"touchDown");
    UIBezierPath *path1 = [UIBezierPath bezierPath];
    [path1 addArcWithCenter:CGPointMake(self.recorde.frame.size.width/2.0,self.recorde.frame.size.height/2.0) radius:self.recorde.frame.size.width/2.0 + 2.5 startAngle:-M_PI/2.0 endAngle:(-M_PI/2.0 - 0.000000000001) clockwise:YES];
    CAShapeLayer *arcLayer1 = [CAShapeLayer layer];
    arcLayer1.path = path1.CGPath;//46,169,230
    arcLayer1.fillColor = [UIColor clearColor].CGColor;
    arcLayer1.strokeColor = [UIColor blueColor].CGColor;
    arcLayer1.lineWidth = 5;
    arcLayer1.backgroundColor = [UIColor blueColor].CGColor;
    [self.recorde.layer addSublayer:arcLayer1];
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:CGPointMake(self.recorde.frame.size.width/2.0,self.recorde.frame.size.height/2.0) radius:self.recorde.frame.size.width/2.0 + 2.5 startAngle:-M_PI/2.0 endAngle:(-M_PI/2.0 - 0.000000000001) clockwise:YES];
    CAShapeLayer *arcLayer = [CAShapeLayer layer];
    arcLayer.path = path.CGPath;//46,169,230
    arcLayer.fillColor = [UIColor clearColor].CGColor;
    arcLayer.strokeColor = [UIColor colorWithRed:227.0/255.0 green:91.0/255.0 blue:90.0/255.0 alpha:0.7].CGColor;
    arcLayer.lineWidth = 5;
    arcLayer.backgroundColor = [UIColor blueColor].CGColor;
    self.arcLayer = arcLayer;
    [self.recorde.layer addSublayer:arcLayer];
    [self drawLineAnimation:arcLayer];
    
    [self.videoPlayer stopPlay];
    [self.session startRecord:^(NSString *videoUrl) {
        self.videoPlayer.videoUrl = videoUrl;
        [self.videoPlayer startPlay];
    }];
}
//定义动画过程
-(void)drawLineAnimation:(CALayer*)layer {
    CABasicAnimation *bas=[CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    bas.duration = 10;//动画时间
    bas.delegate = self;
    bas.fromValue = [NSNumber numberWithInteger:0];
    bas.toValue = [NSNumber numberWithInteger:1];
    [layer addAnimation:bas forKey:@"key"];
}
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    [self.session stopRecord];
    self.messageLabel.hidden = YES;
    [self.arcLayer removeAllAnimations];
    [self.arcLayer removeFromSuperlayer];
}
- (IBAction)touchUp:(UIButton *)sender {
    [self.session stopRecord];
    self.messageLabel.hidden = YES;
    [self.arcLayer removeAllAnimations];
    [self.arcLayer removeFromSuperlayer];
    NSLog(@"touchUpInSide");
}
- (IBAction)touchUpOutSide:(UIButton *)sender {
    [self.session stopRecord];
    self.messageLabel.hidden = YES;
    [self.arcLayer removeAllAnimations];
    [self.arcLayer removeFromSuperlayer];
    NSLog(@"touchUpOutSide---所有在控件之外触摸抬起事件(点触必须开始与控件内部才会发送通知)。");
}
- (IBAction)touchDragOutside:(UIButton *)sender {
    for (UIGestureRecognizer *tap in sender.gestureRecognizers) {
        if ([tap isKindOfClass:[UISwipeGestureRecognizer class]]) {
            NSLog(@"\n\n");
        }
    }
    NSLog(@"%s",__func__);
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.recorde];
    NSLog(@"%f,%f",touchPoint.x,touchPoint.y);
    //touchPoint.x ，touchPoint.y 就是触点的坐标。
    
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.recorde];
    NSLog(@"%f,%f",touchPoint.x,touchPoint.y);
}
- (IBAction)touchCancel:(id)sender {
    self.messageLabel.hidden = YES;
    NSLog(@"touchCancel--所有触摸取消事件，即一次触摸因为放上了太多手指而被取消，或者被上锁或者电话呼叫打断");
}
- (IBAction)touchDragExit:(id)sender {
    self.messageLabel.text = @"松开手指 取消发送";
    NSLog(@"touchDragExit--当一次触摸从控件窗口内部拖动到外部时");
}
- (IBAction)touchDragEnter:(id)sender {
    self.messageLabel.text = @"手指滑动 取消发送";
    NSLog(@"touchDragEnter---当一次触摸从控件窗口之外拖动到内部时。");
}

//停止录制
- (IBAction)stopDownLoad:(id)sender {
    [self.session stopRecord];
}
//暂停播放
- (IBAction)continueDownload:(id)sender {
    [self.videoPlayer pausePlay];
}
//继续播放
- (IBAction)nextPlay:(id)sender {
    [self.videoPlayer startPlay];
}
//开始录制
- (IBAction)REC:(id)sender {
//    self.videoPlayer = [[ZFVideoPalyer alloc]initWithPlayerView:self.layerView];
//    self.videoPlayer.videoUrl = @"http://video.jiecao.fm/8/17/%E6%8A%AB%E8%90%A8.mp4";
//    self.videoPlayer = [[ZFVideoPalyer alloc]initWithPlayerView:self.layerView videoUrl:@"http://video.jiecao.fm/8/17/%E6%8A%AB%E8%90%A8.mp4"];
//    
//    VideoPlayer *video = [[VideoPlayer alloc]initWithPlayerView:self.layerView videoUrl:@"http://zyvideo1.oss-cn-qingdao.aliyuncs.com/zyvd/7c/de/04ec95f4fd42d9d01f63b9683ad0"];
//    [video startPlay];
    
    [self.session startRecord:^(NSString *videoUrl) {
        self.videoPlayer = [[ZFVideoPalyer alloc]initWithPlayerView:self.layerView];
        self.videoPlayer.videoUrl = videoUrl;
        [self.videoPlayer startPlay];
    }];
}
@end
