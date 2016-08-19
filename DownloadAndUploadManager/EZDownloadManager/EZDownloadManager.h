//
//  EZDownloadManager.h
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/5.
//  Copyright © 2016年 owen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZNetworkManager.h"

typedef void (^DownloadComplete)(BOOL isSuccess);
typedef void (^DownloadFailure)(NSError *error);
typedef void (^DownloadProgress)(float progress,NSURLSessionDownloadTask *downloadTask,NSString *fileName,NSString *urlPath);

@interface EZDownloadManager : NSObject<NSURLSessionDelegate>
{
    DownloadComplete _downloadComplete;
    DownloadFailure _downloadFailure;
    DownloadProgress _downloadProgress;
}

@property (nonatomic, strong) NSMutableDictionary *downloadingMap;
@property (nonatomic, strong) NSURLSession *sessionManager;

+ (instancetype)sharedInstance;

- (void)downloadFile:(NSString *)fileName
        downloadPath:(NSString *)urlPath
           localPath:(NSString *)localPath
            progress:(DownloadProgress)progress
             success:(DownloadComplete)success
             failure:(DownloadFailure)failure;

- (void)pasteDownload:(NSString *)fileName
         downloadPath:(NSString *)urlPath
                block:(void(^)(NSString *tempPaht))block;

- (void)stopDownload:(NSString *)fileName
        downloadPath:(NSString *)urlPath
               block:(void(^)())block;

- (NSMutableDictionary *)getDownloadFile:(NSString *)fileName downloadPath:(NSString *)urlPath;
@end
