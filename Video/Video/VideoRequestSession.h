//
//  VideoRequestSession.h
//  Video
//
//  Created by 一公里 on 16/10/27.
//  Copyright © 2016年 小视频录制. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoRequestSession : NSObject<AVAssetResourceLoaderDelegate>
- (NSURL *)getSchemeVideoURL:(NSURL *)url;

@end
