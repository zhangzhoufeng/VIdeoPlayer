//
//  VideoTailoring.h
//  Video
//
//  Created by 一公里 on 16/10/20.
//  Copyright © 2016年 小视频录制. All rights reserved.
//  视频裁剪 压缩类

#import <Foundation/Foundation.h>

@interface VideoTailoring : NSObject
+ (void)tailoringVideos:(NSURL *)url mergeBlock:(void(^)(NSString *videoPath))mergeBlock;
@end
