
#import "RNVideoEditor.h"

@implementation RNVideoEditor

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(merge:(NSArray *)fileNames
                  outputPath:(NSString *)outputPath
                  quality:(NSString *)quality
                  errorCallback:(RCTResponseSenderBlock)failureCallback
                  callback:(RCTResponseSenderBlock)successCallback) {

    if (!fileNames || fileNames.count == 0) {
        failureCallback(@[@"No video files provided"]);
        return;
    }

    NSString *preset = AVAssetExportPresetHighestQuality;
    if ([quality isEqualToString:@"low"]) {
        preset = AVAssetExportPresetLowQuality;
    } else if ([quality isEqualToString:@"medium"]) {
        preset = AVAssetExportPresetMediumQuality;
    }

    NSLog(@"%@ %@ with quality: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), preset);

    [self mergeVideos:fileNames
           outputPath:outputPath
              preset:preset
       successCallback:successCallback
       failureCallback:failureCallback];
}

- (void)mergeVideos:(NSArray *)fileNames
         outputPath:(NSString *)outputPath
             preset:(NSString *)preset
     successCallback:(RCTResponseSenderBlock)successCallback
     failureCallback:(RCTResponseSenderBlock)failureCallback
{
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];

    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                     preferredTrackID:kCMPersistentTrackID_Invalid];

    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                     preferredTrackID:kCMPersistentTrackID_Invalid];

    CMTime insertTime = kCMTimeZero;
    CGAffineTransform originalTransform = CGAffineTransformIdentity;
    BOOL hasSetTransform = NO;
    NSError *error = nil;

    for (NSString *filePath in fileNames) {
        // Clean file path and create URL
        NSString *cleanPath = [filePath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        NSURL *fileURL = [NSURL fileURLWithPath:cleanPath];

        // Validate file exists
        if (![[NSFileManager defaultManager] fileExistsAtPath:cleanPath]) {
            failureCallback(@[[NSString stringWithFormat:@"File not found: %@", cleanPath]]);
            return;
        }

        AVAsset *asset = [AVAsset assetWithURL:fileURL];
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);

        // Insert video track if available
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if (videoTracks.count > 0) {
            AVAssetTrack *assetVideoTrack = [videoTracks objectAtIndex:0];

            BOOL success = [videoTrack insertTimeRange:timeRange
                                               ofTrack:assetVideoTrack
                                                atTime:insertTime
                                                 error:&error];

            if (!success) {
                NSString *errorMsg = error ? error.localizedDescription : @"Failed to insert video track";
                failureCallback(@[errorMsg]);
                return;
            }

            // Preserve transform from the first video
            if (!hasSetTransform) {
                originalTransform = assetVideoTrack.preferredTransform;
                hasSetTransform = YES;
            }
        }

        // Insert audio track if available
        NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
        if (audioTracks.count > 0) {
            AVAssetTrack *assetAudioTrack = [audioTracks objectAtIndex:0];

            BOOL success = [audioTrack insertTimeRange:timeRange
                                               ofTrack:assetAudioTrack
                                                atTime:insertTime
                                                 error:&error];

            if (!success) {
                NSString *errorMsg = error ? error.localizedDescription : @"Failed to insert audio track";
                failureCallback(@[errorMsg]);
                return;
            }
        }

        insertTime = CMTimeAdd(insertTime, asset.duration);
    }

    // Apply the preserved transform to the video track
    if (hasSetTransform) {
        videoTrack.preferredTransform = originalTransform;
    }

    // Use provided output path or generate default one
    NSString *finalOutputPath;
    if (outputPath && outputPath.length > 0) {
        finalOutputPath = [outputPath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    } else {
        NSString *documentsDirectory = [self applicationDocumentsDirectory];
        NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
        NSString *fileName = [NSString stringWithFormat:@"merged_video_%ld.mp4", (long)timestamp];
        finalOutputPath = [documentsDirectory stringByAppendingPathComponent:fileName];
    }
    NSURL *outputURL = [NSURL fileURLWithPath:finalOutputPath];

    // Remove existing file if present
    if ([[NSFileManager defaultManager] fileExistsAtPath:finalOutputPath]) {
        NSError *removeError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:finalOutputPath error:&removeError];
        if (removeError) {
            NSLog(@"Warning: Failed to remove existing file: %@", removeError.localizedDescription);
        }
    }

    // Export the composition
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition
                                                                      presetName:preset];

    if (!exporter) {
        failureCallback(@[@"Failed to create export session"]);
        return;
    }

    exporter.outputURL = outputURL;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;

    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (exporter.status) {
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"Video merge completed: %@", finalOutputPath);
                    successCallback(@[@"", finalOutputPath]);
                    break;

                case AVAssetExportSessionStatusFailed:
                    NSLog(@"Video merge failed: %@", exporter.error.localizedDescription);
                    failureCallback(@[exporter.error.localizedDescription ?: @"Export failed"]);
                    break;

                case AVAssetExportSessionStatusCancelled:
                    failureCallback(@[@"Export was cancelled"]);
                    break;

                default:
                    failureCallback(@[@"Export failed with unknown status"]);
                    break;
            }
        });
    }];
}

- (NSString *)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = paths.count > 0 ? paths[0] : NSTemporaryDirectory();
    return basePath;
}

@end
