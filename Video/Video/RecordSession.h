//
//  RecordSession.h
//  Video
//
//  Created by 一公里 on 16/10/24.
//  Copyright © 2016年 小视频录制. All rights reserved.
//  视屏录制类

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef void(^VideoUrl)(NSString *videoUrl);

@interface RecordSession : NSObject
/**
 视频录制时长 默认15s
 */
@property (nonatomic, assign) Float64 recordTimeout;

/**
 初始化录制器 必须实现此方法
 @param sessionView 承载录制器的View
 */
- (instancetype)initWithSessionView:(UIView *)sessionView;

/**
 开始录制短视频
 @param videoUrl 返回录制完成 裁剪 压缩 后的视频地址
 */
- (void)startRecord:(VideoUrl)videoUrl;
/**
 停止录制短视频
 */
- (void)stopRecord;
@end
