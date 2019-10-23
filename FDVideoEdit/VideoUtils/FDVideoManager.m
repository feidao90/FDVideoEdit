//
//  FDVideoManager.m
//  FDVideoEdit
//
//  Created by 非道 on 2019/10/23.
//  Copyright © 2019 feidao. All rights reserved.
//

#import "FDVideoManager.h"

@implementation FDVideoManager

+ (instancetype)shareManager{
    static FDVideoManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [FDVideoManager new];
    });
    return manager;
}

#pragma mark - public method
//获取视频资源
- (AVURLAsset *)getVideoAsset
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test-video" ofType:@"mp4"];
    NSURL *pathUrl = [NSURL fileURLWithPath:path];
    AVURLAsset *asset = [AVURLAsset assetWithURL:pathUrl];
    NSParameterAssert(asset);   //实际视频可能与封装格式有差异
    return asset;
}

/**
 视频裁剪
 @param startTime 起始时刻
 @param endTime 结束时刻
 @param asset 视频资源
 */
- (void)cuteVideoByStartTime:(NSTimeInterval)startTime endTime:(NSTimeInterval)endTime videoAsset:(AVURLAsset *)asset filePath:(NSURL *)filePath completion:(void(^)(NSURL *fileURL))completion
{
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    AVMutableComposition *composition = [[AVMutableComposition alloc] init]; // AVAsset的子类
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid]; // 视频轨道
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil]; // 在视频轨道插入一个时间段的视频
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    CMTime totalDuration = CMTimeAdd(kCMTimeZero, asset.duration);
    //视频尺寸
    CGFloat videoAssetTrackNaturalWidth = videoAssetTrack.naturalSize.width;
    CGFloat videoAssetTrackNatutalHeight = videoAssetTrack.naturalSize.height;
    CGSize renderSize = CGSizeMake(videoAssetTrackNaturalWidth, videoAssetTrackNatutalHeight);
    CGFloat renderW = MAX(renderSize.width, renderSize.height);
    CGFloat rate;
    rate = renderW / MIN(videoAssetTrackNaturalWidth, videoAssetTrackNatutalHeight);
    CGAffineTransform layerTransform = CGAffineTransformMake(videoAssetTrack.preferredTransform.a, videoAssetTrack.preferredTransform.b, videoAssetTrack.preferredTransform.c, videoAssetTrack.preferredTransform.d, videoAssetTrack.preferredTransform.tx * rate, videoAssetTrack.preferredTransform.ty * rate);
    layerTransform = CGAffineTransformScale(layerTransform, rate, rate);
    [layerInstruction setTransform:layerTransform atTime:kCMTimeZero]; // 得到视频素材
    [layerInstruction setOpacity:0.0 atTime:totalDuration];

    AVMutableVideoCompositionInstruction *instrucation = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instrucation.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    instrucation.layerInstructions = @[layerInstruction];
    
    AVMutableVideoComposition *mainComposition = [AVMutableVideoComposition videoComposition];
    mainComposition.instructions = @[instrucation];
    mainComposition.frameDuration = CMTimeMake(1, 30);
    mainComposition.renderSize = CGSizeMake(renderW, renderW); // 裁剪出对应大小
    
    // 导出
    CMTime start = CMTimeMakeWithSeconds(startTime, totalDuration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(endTime - startTime, totalDuration.timescale);
    
    CMTimeRange range = CMTimeRangeMake(start, duration);
    
    // 导出视频
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    session.videoComposition = mainComposition;
    session.outputURL = filePath;
    session.shouldOptimizeForNetworkUse = YES;
    session.outputFileType = AVFileTypeMPEG4;
    session.timeRange = range;
    [session exportAsynchronouslyWithCompletionHandler:^{
           if ([session status] == AVAssetExportSessionStatusCompleted) {
               NSLog(@"%@",[NSThread currentThread]);
               NSLog(@"%@",session.outputURL);
               NSLog(@"导出成功");
               if (completion) {
                   completion(session.outputURL);
               }
           }else {
               dispatch_async(dispatch_get_main_queue(), ^{
                   NSLog(@"导出失败");
               });
           }
       }];
}
@end
