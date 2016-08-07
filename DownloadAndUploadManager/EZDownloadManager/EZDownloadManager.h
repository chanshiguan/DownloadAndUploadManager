//
//  EZDownloadManager.h
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/5.
//  Copyright © 2016年 owen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileDownloadInfo.h"
#import "EZNetworkManager.h"

typedef void (^DownloadComplete)(BOOL isSuccess);
typedef void (^DownloadFailure)(NSError *error);
typedef void (^DownloadProgress)(float progress,int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);

@interface EZDownloadManager : NSObject<NSURLSessionDelegate>
{
    DownloadComplete _downloadComplete;
    DownloadFailure _downloadFailure;
    DownloadProgress _downloadProgress;
}

@property (nonatomic, strong) NSMutableArray *downloadList;
@property (nonatomic, strong) NSURLSession *sessionManager;

+ (instancetype)sharedInstance;

- (void)addDownloadFile:(FileDownloadInfo *)fdi
               progress:(DownloadProgress)progress
                success:(DownloadComplete)success
                failure:(DownloadFailure)failure;

- (void)startDownload:(FileDownloadInfo *)fdi;//不想暴露他。

- (void)pasteDownload:(FileDownloadInfo *)fdi
                block:(void(^)(NSString *tempPaht))block;

- (void)stopDownload:(FileDownloadInfo *)fdi
               block:(void(^)())block;

@end
