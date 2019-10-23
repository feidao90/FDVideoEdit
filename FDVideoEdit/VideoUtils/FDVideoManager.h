//
//  FDVideoManager.h
//  FDVideoEdit
//
//  Created by 非道 on 2019/10/23.
//  Copyright © 2019 feidao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FDVideoManager : NSObject

+ (instancetype)shareManager;

//获取视频资源
- (AVURLAsset *)getVideoAsset;

//获取音频资源
- (AVURLAsset *)getAudioAsset;

/**
 视频裁剪
 @param startTime 起始时刻
 @param endTime 结束时刻
 @param asset 视频资源
 */
- (void)cuteVideoByStartTime:(NSTimeInterval)startTime endTime:(NSTimeInterval)endTime videoAsset:(AVURLAsset *)asset filePath:(NSURL *)filePath completion:(void(^)(NSURL *fileURL))completion;

/**
 视频合成音轨
 @param videoAsset 视频资源
 @param audioAsset 音频资源
 @param filePath 裁剪后的文件路径(可指定)
 @param completion 完成回调
 */
- (void)compostionWithVideoAsset:(AVURLAsset *)videoAsset audioAsset:(AVURLAsset *)audioAsset filePath:(NSURL *)filePath completion:(void(^)(NSURL *fileURL))completion;

/**
 音轨合成音轨
 @param videoAsset 视频资源
 @param audioAsset 音频资源
 @param filePath 裁剪后的文件路径(可指定)
 @param completion 完成回调
 */
- (void)compostionAudioWithVideoAsset:(AVURLAsset *)videoAsset audioAsset:(AVURLAsset *)audioAsset filePath:(NSURL *)filePath completion:(void(^)(NSURL *fileURL))completion;
@end

NS_ASSUME_NONNULL_END
