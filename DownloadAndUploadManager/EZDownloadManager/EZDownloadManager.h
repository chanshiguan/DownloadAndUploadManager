//
//  EZDownloadManager.h
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/5.
//  Copyright © 2016年 owen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EZDownloadState) {
    EZDownloadStateUnStart = 0,
    EZDownloadStateDownloading = 1,
    EZDownloadStatePause = 2,
    EZDownloadStateFail = 3,
    EZDownloadStateFinish = 4,
};

typedef void (^DownloadComplete)(NSString *fileName,NSString *urlPath);
typedef void (^DownloadFailure)(NSError *error,NSString *fileName,NSString *urlPath);
typedef void (^DownloadProgress)(float progress,NSURLSessionDownloadTask *downloadTask,NSString *fileName,NSString *urlPath);

@interface EZDownloadManager : NSObject<NSURLSessionDelegate>
{
    DownloadComplete _downloadComplete;
    DownloadFailure _downloadFailure;
    DownloadProgress _downloadProgress;
}

@property (nonatomic, strong) NSURLSession *sessionManager;
@property (nonatomic, strong) DownloadComplete downloadComplete;
@property (nonatomic, strong) DownloadFailure downloadFailure;
@property (nonatomic, strong) DownloadProgress downloadProgress;
@property (nonatomic) EZDownloadState downloadState;

+ (instancetype)sharedInstance;

//开始下载
- (void)downloadFile:(NSString *)fileName
        downloadPath:(NSString *)urlPath
           localPath:(NSString *)localPath
               block:(void(^)())block;

//暂停下载
- (void)pasteDownload:(NSString *)fileName
         downloadPath:(NSString *)urlPath
                block:(void(^)())block;   //先留着block 也许未来需要返回什么值

//取消下载
- (void)stopDownload:(NSString *)fileName
        downloadPath:(NSString *)urlPath
               block:(void(^)())block;

//获取进度
- (CGFloat)getDownloadProgress:(NSString *)fileName
                  downloadPath:(NSString *)urlPath;

//获取下载状态
- (EZDownloadState)getDownloadState:(NSString *)fileName
                       downloadPath:(NSString *)urlPath;

//获取已经下载的本地路径
- (NSString *)getLocalPath:(NSString *)fileName
              downloadPath:(NSString *)urlPath;
@end
