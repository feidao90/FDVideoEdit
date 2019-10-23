//
//  FDVideoManager.m
//  FDVideoEdit
//
//  Created by 非道 on 2019/10/23.
//  Copyright © 2019 feidao. All rights reserved.
//

#import "FDVideoManager.h"
#import <UIKit/UIKit.h>

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

//获取音频资源
- (AVURLAsset *)getAudioAsset
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test-audio" ofType:@"wav"];
    NSURL *pathUrl = [NSURL fileURLWithPath:path];
    AVURLAsset *asset = [AVURLAsset assetWithURL:pathUrl];
    NSParameterAssert(asset);   //实际音频可能与封装格式有差异
    return asset;
}
/**
 视频裁剪
 @param startTime 起始时刻
 @param endTime 结束时刻
 @param asset 视频资源
 @param filePath 裁剪后的文件路径(可指定)
 @param completion 完成回调
 */
- (void)cuteVideoByStartTime:(NSTimeInterval)startTime endTime:(NSTimeInterval)endTime videoAsset:(AVURLAsset *)asset filePath:(NSURL *)filePath completion:(void(^)(NSURL *fileURL))completion
{
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    AVAssetTrack *audioAssetTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject]; // 音轨
    
    AVMutableComposition *composition = [[AVMutableComposition alloc] init]; // AVAsset的子类
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid]; // 视频轨道
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil]; // 在视频轨道插入一个时间段的视频
    
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid]; // 音轨
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil]; // 插入音频数据，否则没有声音
        
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

/**
 视频合成音轨
 @param videoAsset 视频资源
 @param audioAsset 音频资源
 @param filePath 裁剪后的文件路径(可指定)
 @param completion 完成回调
 */
- (void)compostionWithVideoAsset:(AVURLAsset *)videoAsset audioAsset:(AVURLAsset *)audioAsset filePath:(NSURL *)filePath completion:(void(^)(NSURL *fileURL))completion
{
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];    //视频轨道
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject]; // 新添加音轨
    
    AVMutableComposition *composition = [[AVMutableComposition alloc] init]; // AVAsset的子类
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid]; // 视频轨道
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil]; // 在视频轨道插入一个时间段的视频
    
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid]; // 音轨
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil]; // 插入音频数据，否则没有声音
    
    CMTimeRange range = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
    // 导出视频
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    session.outputURL = filePath;
    session.outputFileType = AVFileTypeMPEG4;
    session.timeRange = range;
    [session exportAsynchronouslyWithCompletionHandler:^{
           if ([session status] == AVAssetExportSessionStatusCompleted) {
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

/**
 音轨合成音轨
 @param videoAsset 视频资源
 @param audioAsset 音频资源
 @param filePath 裁剪后的文件路径(可指定)
 @param completion 完成回调
 */
- (void)compostionAudioWithVideoAsset:(AVURLAsset *)videoAsset audioAsset:(AVURLAsset *)audioAsset filePath:(NSURL *)filePath completion:(void(^)(NSURL *fileURL))completion{
    AVAssetTrack *originAudioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];    //视频轨道
    AVAssetTrack *audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject]; // 新添加音轨
    
    AVMutableComposition *composition = [[AVMutableComposition alloc] init]; // AVAsset的子类
    AVMutableCompositionTrack *videoOriginAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid]; // 视频原音轨道
    [videoOriginAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:originAudioAssetTrack atTime:kCMTimeZero error:nil]; // 在视频轨道插入一个时间段的音轨
    
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid]; // 音轨
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil]; // 插入音频数据，否则没有声音
    
    CMTimeRange range = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    // 导出视频
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    session.outputURL = filePath;
    session.outputFileType = AVFileTypeAppleM4A;
    session.timeRange = range;
    [session exportAsynchronouslyWithCompletionHandler:^{
           if ([session status] == AVAssetExportSessionStatusCompleted) {
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

/**
 添加水印
 @param videoAsset 视频资源
 @param handler 回到
 */
- (void)addWaterMarkTypeWithCorAnimationAndInputVideoURL:(AVURLAsset *)videoAsset WithCompletionHandler:(void (^)(NSURL* outPutURL))handler{
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
      AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
      [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                          ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject]
                           atTime:kCMTimeZero error:nil];
      //2 音频通道
      AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio                                         preferredTrackID:kCMPersistentTrackID_Invalid];
      [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                          ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject]
                           atTime:kCMTimeZero error:nil];
      AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
      mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
      AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
      [videolayerInstruction setOpacity:0.0 atTime:videoAsset.duration];
      mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
      AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
      AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
      CGSize naturalSize = videoAssetTrack.naturalSize;
      
      float renderWidth, renderHeight;
      renderWidth = naturalSize.width;
      renderHeight = naturalSize.height;
      mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
      mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
      mainCompositionInst.frameDuration = CMTimeMake(1, 30);
      [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize];
      
      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
      NSString *documentsDirectory = [paths objectAtIndex:0];
      NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                               [NSString stringWithFormat:@"FinalVideo-%d.mp4",arc4random() % 1000]];
      NSURL* videoUrl = [NSURL fileURLWithPath:myPathDocs];
      AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition     presetName:AVAssetExportPresetHighestQuality];
      exporter.outputURL = videoUrl;
      exporter.outputFileType = AVFileTypeMPEG4;
      exporter.shouldOptimizeForNetworkUse = YES;
      exporter.videoComposition = mainCompositionInst;
      [exporter exportAsynchronouslyWithCompletionHandler:^{
          dispatch_async(dispatch_get_main_queue(), ^{
              if( exporter.status == AVAssetExportSessionStatusCompleted ){
                  handler([NSURL fileURLWithPath:myPathDocs]);
              }else if( exporter.status == AVAssetExportSessionStatusFailed )
              {
                  NSLog(@"failed");
              }
          });
      }];
}

#pragma mark - private method
/**
 设置水印及位置
 @param composition 视频的结构
 @param size 视频的尺寸
 */
- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
    // 文字
//    CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
//    //    [subtitle1Text setFont:@"Helvetica-Bold"];
//    [subtitle1Text setFontSize:36];
//    [subtitle1Text setFrame:CGRectMake(10, size.height-10-100, size.width, 100)];
//    [subtitle1Text setString:@"feidaofeidao"];
//    //    [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
//    [subtitle1Text setForegroundColor:[[UIColor whiteColor] CGColor]];
    
    //图片
    CALayer*picLayer = [CALayer layer];
    picLayer.contents = (id)[UIImage imageNamed:@"watermark"].CGImage;
    picLayer.frame = CGRectMake(size.width-15-87, 15, 87, 26);
    
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer addSublayer:picLayer];
    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [overlayLayer setMasksToBounds:YES];
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
}
@end
