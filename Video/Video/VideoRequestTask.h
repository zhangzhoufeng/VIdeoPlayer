//
//  VideoRequest.h
//  Video
//
//  Created by 一公里 on 16/10/26.
//  Copyright © 2016年 小视频录制. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol VideoRequestTaskDelegate <NSObject>
@optional
/**
 与服务器连接
 @param videoLength 视频长度
 */
- (void)didReciveVideoLength:(NSUInteger)videoLength;
/**
 视频正在下载中
 @param progress 下载进度
 */
- (void)didDownloadProgress:(CGFloat)progress;
/**
 视频下载完成
 @param videoUrl 本地视频地址
 */
- (void)didDownloadFinishVideoUrl:(NSString *)videoUrl;
/**
 下载失败
 */
- (void)didDownloadFail;
@end



@interface VideoRequestTask : NSObject

/**
 VideoRequestTaskDelegate
 */
@property (nonatomic, strong)
                id<VideoRequestTaskDelegate> delegate;
/**
 视频下载地址
 */
@property (nonatomic, strong, readonly) NSURL *videoUrl;
/**
 定位到的视频节点
 */
@property (nonatomic, assign, readonly) NSUInteger offset;
/**
 视频已下载长度
 */
@property (nonatomic, assign, readonly) NSUInteger                 videoDownLoadOffset;
/**
 视频总长
 */
@property (nonatomic, assign, readonly) NSUInteger videoLength;
/**
 视频格式
 */
@property (nonatomic, copy)  NSString *mimeType;
/**
 赋值Url
 */
- (void)setVideoUrl:(NSURL *)videoUrl offset:(NSUInteger)offset;
/**
 取消下载
 */
- (void)cancel;
/**
 继续下载
 */
- (void)continueLoading;
/**
 清楚数据
 */
- (void)cleanData;

@end
