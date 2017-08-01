//
//  vide.swift
//  Video
//
//  Created by 一公里 on 16/10/20.
//  Copyright © 2016年 小视频录制. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
class vide: NSObject {
    //合并视频片段
    func mergeVideos() {
//        let duration = 12
        //最大允许的录制时间（秒）
        let totalSeconds: Float64 = 15.00
//        //每秒帧数
        let framesPerSecond:Int32 = 30
        
        let composition = AVMutableComposition()
        //合并视频、音频轨道
        let firstTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
//        let audioTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
//
//        var insertTime: CMTime = kCMTimeZero
//        for asset in videoAssets {
//            print("合并视频片段：\(asset)")
//            do {
//                try firstTrack.insertTimeRange(
//                    CMTimeRangeMake(kCMTimeZero, asset.duration),
//                    ofTrack: asset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
//                    atTime: insertTime)
//            } catch _ {
//            }
//            do {
//                try audioTrack.insertTimeRange(
//                    CMTimeRangeMake(kCMTimeZero, asset.duration),
//                    ofTrack: asset.tracksWithMediaType(AVMediaTypeAudio)[0] ,
//                    atTime: insertTime)
//            } catch _ {
//            }
//            
//            insertTime = CMTimeAdd(insertTime, asset.duration)
//        }
        //旋转视频图像，防止90度颠倒
        firstTrack.preferredTransform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
        
        //定义最终生成的视频尺寸（矩形的）
        print("视频原始尺寸：", firstTrack.naturalSize)
        let renderSize = CGSize(width:firstTrack.naturalSize.height, height: firstTrack.naturalSize.height)
        print("最终渲染尺寸：", renderSize)
        
        //通过AVMutableVideoComposition实现视频的裁剪(矩形，截取正中心区域视频)
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTimeMake(1, framesPerSecond)
        videoComposition.renderSize = renderSize
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(
            kCMTimeZero,CMTimeMakeWithSeconds(totalSeconds, framesPerSecond))
        
        let transformer: AVMutableVideoCompositionLayerInstruction =
            AVMutableVideoCompositionLayerInstruction(assetTrack: firstTrack)
        let t1 = CGAffineTransform(translationX: firstTrack.naturalSize.height,
                                   y: -(firstTrack.naturalSize.width-firstTrack.naturalSize.height)/2)
        let t2 = t1.rotated(by: CGFloat(M_PI_2))
        let finalTransform: CGAffineTransform = t2
        transformer.setTransform(finalTransform, at: kCMTimeZero)
        
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        
        //获取合并后的视频路径
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                .userDomainMask,true)[0]
        let destinationPath = documentsPath + "/mergeVideo-\(arc4random()%1000).mov"
        print("合并后的视频：\(destinationPath)")
        let videoPath: NSURL = NSURL(fileURLWithPath: destinationPath as String)
        let exporter = AVAssetExportSession(asset: composition,
                                            presetName:AVAssetExportPresetHighestQuality)!
        exporter.outputURL = videoPath as URL
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.videoComposition = videoComposition //设置videoComposition
        exporter.shouldOptimizeForNetworkUse = true
        exporter.timeRange = CMTimeRangeMake(
            kCMTimeZero,CMTimeMakeWithSeconds(totalSeconds, framesPerSecond))
        exporter.exportAsynchronously(completionHandler: {
            //将合并后的视频保存到相册
//            self.exportDidFinish(session: exporter)
        })
    }
}
