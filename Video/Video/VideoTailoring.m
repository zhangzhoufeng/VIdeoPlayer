//
//  VideoTailoring.m
//  Video
//
//  Created by 一公里 on 16/10/20.
//  Copyright © 2016年 小视频录制. All rights reserved.
//

#import "VideoTailoring.h"
#import <Photos/Photos.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
@implementation VideoTailoring
+ (void)tailoringVideos:(NSURL *)url mergeBlock:(void(^)(NSString *videoPath))tailoringBlock{
    //宽高比例
    #define Ratio 0.7
    
    AVURLAsset *asset = [[AVURLAsset alloc]initWithURL:url options:nil];
    NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
    NSLog(@"生成的视频片段:%@",asset);
    
    //拍摄时间总长
    Float64 totalSecconds = duration;
    //每秒录制帧数
    int32_t framesPerSecond = 20;
    AVMutableComposition *composion = [[AVMutableComposition alloc]init];
    CMPersistentTrackID ida = 0;
    //合并视频音频轨道
    
    AVMutableCompositionTrack *firstTrack = [composion addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:ida];
    AVMutableCompositionTrack *audioTrack = [composion addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:ida];
    CMTime inserTime = kCMTimeZero;
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo][0] atTime:inserTime error:nil];
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio][0] atTime:inserTime error:nil];

    inserTime = CMTimeAdd(inserTime, asset.duration);
    
    //旋转视频图像 防止90度颠倒
    firstTrack.preferredTransform = CGAffineTransformMakeRotation(M_PI_2);
    NSLog(@"视频原尺寸:%@",NSStringFromCGSize(firstTrack.naturalSize));
    
    //定义最终生成的尺寸
    CGSize renderSize = CGSizeMake(firstTrack.naturalSize.height, firstTrack.naturalSize.height * Ratio);
    NSLog(@"渲染后的尺寸:%@",NSStringFromCGSize(renderSize));
    //通过AVMutableVideoComposition实现视频的裁剪(矩形，截取正中心区域视频)
    AVMutableVideoComposition *videoComposition = [[AVMutableVideoComposition alloc]init];
    videoComposition.frameDuration = CMTimeMake(1,framesPerSecond);
    videoComposition.renderSize = renderSize;
    AVMutableVideoCompositionInstruction *instruction = [[AVMutableVideoCompositionInstruction alloc]init];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(totalSecconds, framesPerSecond));
    AVMutableVideoCompositionLayerInstruction *transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
    CGAffineTransform t1 = CGAffineTransformMakeTranslation(firstTrack.naturalSize.height,
                                                  -(firstTrack.naturalSize.width-(firstTrack.naturalSize.height * Ratio))/2 );
    CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
    CGAffineTransform finalTransform = t2;
    [transformer setTransform:finalTransform atTime:kCMTimeZero];
    
    instruction.layerInstructions = @[transformer];
    videoComposition.instructions = @[instruction];
    
    //处理后的视频路径
    NSString *destinationPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"myVidio2.mov"];
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:destinationPath]){
        [manager removeItemAtPath:destinationPath error:nil];
    }
    
    
    NSURL *videoPath = [NSURL fileURLWithPath:destinationPath];
    //对视频做相应的压缩
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc]initWithAsset:composion presetName:AVAssetExportPresetMediumQuality];
    exporter.outputURL = videoPath;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.videoComposition = videoComposition;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(totalSecconds, framesPerSecond));
    //处理成功后
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        tailoringBlock(destinationPath);
    }];
    
    
    
}
@end
