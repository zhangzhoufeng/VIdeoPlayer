//
//  RecordSession.m
//  Video
//
//  Created by 一公里 on 16/10/24.
//  Copyright © 2016年 小视频录制. All rights reserved.
//

#import "RecordSession.h"
#import "VideoTailoring.h"
#import <AVFoundation/AVFoundation.h>
@interface RecordSession ()<AVCaptureFileOutputRecordingDelegate>
/**
 视频录制输出
 */
@property (nonatomic, strong)AVCaptureMovieFileOutput *output;
/**
 承载录制器的父视图
 */
@property (nonatomic, strong) UIView *sessionView;
/**
 录制完成回调视频URL
 */
@property (nonatomic, copy) VideoUrl videoUrl;
/**
 录制时间倒计时
 */
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) AVCaptureDevice *device;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preLayer;
@end

@implementation RecordSession
/**
 初始化录制器 必须实现此方法
 @param sessionView 承载录制器的View
 */- (instancetype)initWithSessionView:(UIView *)sessionView{
    self = [super init];
    if (self) {
        self.sessionView = sessionView;
//        [self.sessionView addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(sessionTap:)]];
        [self initSession];
    }
    return self;
}
//- (void)sessionTap:(UITapGestureRecognizer *)tap{
//    CGPoint tapPoint = [tap locationInView:tap.view];
//    CGPoint FocusPoint = CGPointMake(tapPoint.x/tap.view.frame.size.width, tapPoint.y/tap.view.frame.size.height);
//    if ([self.device isFocusPointOfInterestSupported]) {
//        [self.device setFocusPointOfInterest:FocusPoint];
//        [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
//    }
//}
/**
 开始录制短视频
 @param videoUrl 返回录制完成 裁剪 压缩 后的视频地址
 */
- (void)startRecord:(VideoUrl)videoUrl{
    self.videoUrl = videoUrl;
    __weak typeof(self) weakSelf = self;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.recordTimeout repeats:NO block:^(NSTimer * _Nonnull timer) {
        [weakSelf.timer invalidate];
        [weakSelf.output stopRecording];
    }];
    self.timer = timer;
    
    //10.开始录制视频
    //设置录制视频保存的路径
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"myVidio.mov"];
    //转为视频保存的url
    NSURL *url = [NSURL fileURLWithPath:path];
    //开始录制,并设置控制器为录制的代理
    [self.output startRecordingToOutputFileURL:url recordingDelegate:self];
    [self.sessionView.layer addSublayer:self.preLayer];
}
/**
 停止录制短视频
 */
- (void)stopRecord{
    [self.preLayer removeFromSuperlayer];
    [self.timer invalidate];
    if ([self.output isRecording]) {
        [self.output stopRecording];
    }
}
/**
 初始化录制器
 */
- (void)initSession{
    //1.创建视频设备(摄像头前，后)
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.device = device;
    //2.初始化一个摄像头输入设备(first是后置摄像头，last是前置摄像头)
    AVCaptureDeviceInput *inputVideo = [AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];
    if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
//        CGPoint focusPoint = CGPointMake(10, 10);
//        [device setFocusPointOfInterest:focusPoint];
//        [device setFocusMode:AVCaptureFocusModeAutoFocus];
    }
    //3.创建麦克风设备x
    AVCaptureDevice *deviceAudio = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    //4.初始化麦克风输入设备
    AVCaptureDeviceInput *inputAudio = [AVCaptureDeviceInput deviceInputWithDevice:deviceAudio error:NULL];
    
    //5.初始化一个movie的文件输出
    AVCaptureMovieFileOutput *output = [[AVCaptureMovieFileOutput alloc] init];
    //设置录制时间与每秒帧数
    if (self.recordTimeout == 0) {
        self.recordTimeout = 15;
    }
    Float64 seconds = self.recordTimeout;
    int32_t frameNumber = 20;
    output.maxRecordedDuration = CMTimeMakeWithSeconds(seconds, frameNumber);
    self.output = output; //保存output，方便下面操作
    
    //6.初始化一个会话
    AVCaptureSession *session = [[AVCaptureSession alloc]init];
    if ([session canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        [session setSessionPreset:AVCaptureSessionPreset640x480];
    }
    //7.将输入输出设备添加到会话中
    if ([session canAddInput:inputVideo]) {
        [session addInput:inputVideo];
    }
    if ([session canAddInput:inputAudio]) {
        [session addInput:inputAudio];
    }
    if ([session canAddOutput:output]) {
        [session addOutput:output];
    }
    CALayer *layer = self.sessionView.layer;
//    layer.frame = self.sessionView.frame;
    NSLog(@"%@",NSStringFromCGRect(self.sessionView.frame));
    layer.masksToBounds=YES;
    
    //8.创建一个预览涂层
    AVCaptureVideoPreviewLayer *preLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    // 设置图层的大小
    preLayer.frame = layer.bounds;
    preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preLayer = preLayer;
    //添加到view上
    [self.sessionView.layer addSublayer:preLayer];
    [session startRunning];
}

#pragma  mark - AVCaptureFileOutputRecordingDelegate
//录制完成代理
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
//    NSURL *url = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"myVidio.mov"]];

    NSLog(@"完成录制,可以自己做进一步的处理");
    NSLog(@"转换前文件大小==%lld",[self fileSizeAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"myVidio.mov"]]);
    
    // 这里为什么要调用延迟1.0秒呢，我们说过用 AVCaptureMovieFileOutput 来录制视频，是边录边写的，即使是录制完成了，真实的是视频还在写，大概时间是延迟1.2秒左右。
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [VideoTailoring tailoringVideos:outputFileURL mergeBlock:^(NSString *videoPath) {
            NSLog(@"转换后文件大小==%lld",[weakSelf fileSizeAtPath:videoPath]);
            weakSelf.videoUrl(videoPath);
        }];
    });
    
}
/**
 计算文件大小
 */
-(long long) fileSizeAtPath:(NSString*) filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize]/1024;
    }
    return 0;
}
- (void)dealloc{
    self.output = nil;
}
@end
