//
//  VideoRequest.m
//  Video
//
//  Created by 一公里 on 16/10/26.
//  Copyright © 2016年 小视频录制. All rights reserved.
//

#import "VideoRequestTask.h"
#define DOCUMENT NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject

@interface VideoRequestTask ()<NSURLSessionDataDelegate,NSURLSessionDelegate>
/**
 视频临时保存的地址
 */
@property (nonatomic, copy) NSString *videoDownLoadPath;
/**
 请求次数
 */
@property (nonatomic, strong) NSMutableArray *taskArray;
/**
 临时文件管理
 */
@property (nonatomic, strong) NSFileHandle  *fileHandle;


@property (nonatomic, strong) NSURLSession *session;
/**
 下载任务
 */
@property (nonatomic, strong) NSURLSessionDataTask *task;
/**
 已下载的数据
 */
@property (nonatomic, strong) NSData *resumeData;
@end
@implementation VideoRequestTask
-(instancetype)init{
    self = [super init];
    if (self) {
        self.videoDownLoadPath = [DOCUMENT stringByAppendingString:@"321.mp4"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.videoDownLoadPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.videoDownLoadPath error:nil];
        }
        [[NSFileManager defaultManager] createFileAtPath:self.videoDownLoadPath contents:nil attributes:nil];

    }
    return self;
}
- (void)setVideoUrl:(NSURL *)videoUrl offset:(NSUInteger)offset{
    _videoUrl = videoUrl;
    _offset = offset;
    _videoDownLoadOffset = 0;
    //建立第二次请求  先移除原来文件 新建
    if (self.taskArray.count > 0) {
        [[NSFileManager defaultManager] removeItemAtPath:self.videoDownLoadPath error:nil];
        [[NSFileManager defaultManager] createFileAtPath:self.videoDownLoadPath contents:nil attributes:nil];
    }
    //创建请求
    NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:videoUrl resolvingAgainstBaseURL:NO];
    actualURLComponents.scheme = @"http";
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[actualURLComponents URL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
    //如果视频节点不为0 则从节点处开始下载
    if (offset > 0 && self.videoLength > 0) {
        [request addValue:[NSString stringWithFormat:@"bytes=%ld-",(unsigned long)offset] forHTTPHeaderField:@"Range"];
    }
    if (self.task) {
        [self cancel];
        self.task = nil;
    }
    // session的delegate属性是只读的,要想设置代理只能通过这种方式创建session
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    //创建任务
    self.task = [self.session dataTaskWithRequest:request];
    //开始任务
    [self.task resume];
}
#pragma mark session Delegate

// 1.接收到服务器的响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    // 允许处理服务器的响应，才会继续接收服务器返回的数据
    completionHandler(NSURLSessionResponseAllow);
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    
    NSDictionary *dic = (NSDictionary *)[httpResponse allHeaderFields] ;
    NSString *content = [dic valueForKey:@"Content-Range"];
    NSArray *array = [content componentsSeparatedByString:@"/"];
    NSString *length = array.lastObject;
    NSUInteger videoLength;
    
    if ([length integerValue] == 0) {
        videoLength = (NSUInteger)httpResponse.expectedContentLength;
    } else {
        videoLength = [length integerValue];
    }
    _videoLength = videoLength;
    self.mimeType = @"video/mp4";
    if ([self.delegate respondsToSelector:@selector(didReciveVideoLength:)]) {
        [self.delegate didReciveVideoLength:self.videoLength];
    }
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.videoDownLoadPath];
    
}
//每次下载到数据都会调用
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    [self.fileHandle seekToEndOfFile];
    
    [self.fileHandle writeData:data];
    
    _videoDownLoadOffset += data.length;
    if ([self.delegate respondsToSelector:@selector(didDownloadProgress:)]) {
        [self.delegate didReciveVideoLength:0];
    }
}
// 由于下载失败导致的下载中断会进入此协议方法,也可以得到用来恢复的数据
//网络中断：-1005
//无网络连接：-1009
//请求超时：-1001
//服务器内部错误：-1004
//找不到服务器：-1003
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    
    self.resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
    NSLog(@"%ld",error.code);
    if (error.code == -1001) {
        // 保存恢复数据
        if ([self.delegate respondsToSelector:@selector(didDownloadFail)]) {
            [self.delegate didDownloadFail];
        }
        //断点续传
        [self continueLoading];
    }
    
}
/**
 取消下载
 */
- (void)cancel{
//    __weak typeof(self) weakSelf = self;
    [self.task cancel];
//    [self.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
//        weakSelf.resumeData = resumeData;
//    }];
}
/**
 清除数据
 */
- (void)cleanData{
    [self.task cancel];
    [[NSFileManager defaultManager] removeItemAtPath:self.videoDownLoadPath error:nil];
}
/**
 断点续传 继续下载
 */
- (void)continueLoading{
    // 恢复下载时接过保存的恢复数据
//    self.task = [self.session da];
    // 启动任务
    [self.task resume];

}
//- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
// didResumeAtOffset:(int64_t)fileOffset
//expectedTotalBytes:(int64_t)expectedTotalBytes{
//    downloadTask.
//}
@end
