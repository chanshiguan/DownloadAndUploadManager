//
//  EZDownloadManager.m
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/5.
//  Copyright © 2016年 owen. All rights reserved.
//

#import "EZDownloadManager.h"
#import "AppDelegate.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "NSString+Hash.h"
#import "TMCache.h"

#define DOWNLOADER_TITLE    @"fileTitle"    //文件名
#define DOWNLOADER_DOWNLOADSOURCE    @"downloadSource"    //下载地址
#define DOWNLOADER_LOCALSOURCE    @"loacalSource"    //本地存储路径
#define DOWNLOADER_RESUMEDATA    @"taskResumeData"    //下载进度
#define DOWNLOADER_DOWNLOADCOMPLETE    @"downloadComplete"    //下载状态
#define DOWNLOADER_TAKIDENTIFIER    @"taskIdentifier"    //下载标识

@implementation EZDownloadManager

static EZDownloadManager *instance = nil;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    return instance;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.downloadingMap = [NSMutableDictionary dictionary];
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.runlin.downloader"];
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 5;
        self.sessionManager = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                     delegate:self
                                                delegateQueue:nil];
    }
    return self;
}

//获取下载唯一标识
- (NSString *)getFileIdentifier:(NSString *)fileName downloadPath:(NSString *)urlPath
{
    return [[NSString stringWithFormat:@"%@+%@",fileName,urlPath] md5String];
}

//获取下载对象
- (NSMutableDictionary *)getDownloadFile:(NSString *)fileName downloadPath:(NSString *)urlPath
{
    NSString *identifier = [self getFileIdentifier:fileName downloadPath:urlPath];
    NSMutableDictionary *downloadFile = nil;
    NSMutableDictionary *temp = [self getDownloadData:identifier];
    if (temp == nil) {
        downloadFile = [NSMutableDictionary dictionaryWithObjectsAndKeys:fileName,DOWNLOADER_TITLE,urlPath,DOWNLOADER_DOWNLOADSOURCE,[NSNumber numberWithInteger:-1],DOWNLOADER_TAKIDENTIFIER,[NSNumber numberWithBool:NO],DOWNLOADER_DOWNLOADCOMPLETE, nil];
    } else {
        downloadFile = [NSMutableDictionary dictionaryWithDictionary:temp];
    }
    return downloadFile;
}

//本地缓存数据
- (void)saveDownloadData:(NSDictionary *)downloader
{
    if (downloader == nil) {
        return;
    }
    NSString *identifier = [self getFileIdentifier:[downloader objectForKey:DOWNLOADER_TITLE] downloadPath:[downloader objectForKey:DOWNLOADER_DOWNLOADSOURCE]];
    [[TMDiskCache sharedCache] setObject:downloader forKey:identifier];
}

//删除本地缓存，应该只用作停止下载
- (void)removeDownloadData:(NSDictionary *)downloader
{
    NSString *identifier = [self getFileIdentifier:[downloader objectForKey:DOWNLOADER_TITLE] downloadPath:[downloader objectForKey:DOWNLOADER_DOWNLOADSOURCE]];
    [[TMDiskCache sharedCache] removeObjectForKey:identifier];
}

//获取本地管理文件
- (NSMutableDictionary *) getDownloadData:(NSString *)identifier
{
    return (NSMutableDictionary *)[[TMDiskCache sharedCache] objectForKey:identifier];
}

//保存正在下载的
- (void)setDownloadingTask:(NSURLSessionDownloadTask *)task withIdentifier:(NSString *)identifier
{
    if (task == nil) {
        return;
    }
    if (self.downloadingMap == nil) {
        self.downloadingMap = [NSMutableDictionary dictionary];
    }
    
    [self.downloadingMap setObject:task forKey:identifier];
}

//根据下载task 的id 获取本地管理文件
- (NSMutableDictionary *)getDownloadDataByTaskID:(NSURLSessionDownloadTask *)task
{
    NSMutableDictionary *downloader = nil;
    for (NSString *str in [self.downloadingMap allKeys]) {
        NSURLSessionDownloadTask *downloadTask = [self.downloadingMap objectForKey:str];
        if (downloadTask == task) {
            //说明我找到了正在下载的对象，也就是进度对应的对象
            downloader = [self getDownloadData:str];
            break;
        }
    }
    return downloader;
}

- (void)downloadFile:(NSString *)fileName
        downloadPath:(NSString *)urlPath
           localPath:(NSString *)localPath
            progress:(DownloadProgress)progress
             success:(DownloadComplete)success
             failure:(DownloadFailure)failure;
{
    
    _downloadProgress = progress;
    _downloadComplete = success;
    _downloadFailure = failure;
    
    //如果正在下载，不可以重复下载
    if ([self.downloadingMap objectForKey:[self getFileIdentifier:fileName downloadPath:urlPath]]) {
        return;
    }
    //设置数据源
    NSMutableDictionary *downloader = [self getDownloadFile:fileName downloadPath:urlPath];
    [downloader setObject:localPath forKey:DOWNLOADER_LOCALSOURCE];
    
    NSURLSessionDownloadTask *task = nil;
    if (![self.downloadingMap objectForKey:[self getFileIdentifier:fileName downloadPath:urlPath]]) {
        if ([[downloader objectForKey:DOWNLOADER_TAKIDENTIFIER] integerValue] == -1) {
            task = [_sessionManager downloadTaskWithURL:[NSURL URLWithString:[downloader objectForKey:DOWNLOADER_DOWNLOADSOURCE]]];
        } else {
            NSData *taskResumeData = [downloader objectForKey:DOWNLOADER_RESUMEDATA];
            //如果找不到本地数据，那么重新下载
            if (taskResumeData == nil) {
                task = [_sessionManager downloadTaskWithURL:[NSURL URLWithString:[downloader objectForKey:DOWNLOADER_DOWNLOADSOURCE]]];
            } else {
                task = [_sessionManager downloadTaskWithResumeData:taskResumeData];
            }
        }
    } else {
        return;
    }
    [task resume];
    [downloader setObject:[NSNumber numberWithInteger:task.taskIdentifier] forKey:DOWNLOADER_TAKIDENTIFIER];
    [self saveDownloadData:downloader];
    [self setDownloadingTask:task withIdentifier:[self getFileIdentifier:fileName downloadPath:urlPath]];
}

- (void)pasteDownload:(NSString *)fileName
         downloadPath:(NSString *)urlPath
                block:(void(^)(NSString *tempPaht))block
{
    if (![self.downloadingMap objectForKey:[self getFileIdentifier:fileName downloadPath:urlPath]]) {
        return;
    }
    
    NSURLSessionDownloadTask *task = [self.downloadingMap objectForKey:[self getFileIdentifier:fileName downloadPath:urlPath]];
    [task cancelByProducingResumeData:^(NSData *resumeData) {
        if (resumeData != nil) {
            
            NSMutableDictionary *downloader = [self getDownloadFile:fileName downloadPath:urlPath];
            [downloader setObject:[[NSData alloc] initWithData:resumeData] forKey:DOWNLOADER_RESUMEDATA];
            [self saveDownloadData:downloader];
            [self.downloadingMap removeObjectForKey:[self getFileIdentifier:fileName downloadPath:urlPath]];
            //备份数据
            if (block) {
                block(@"");
            }
            
        }
    }];
}

- (void)stopDownload:(NSString *)fileName
        downloadPath:(NSString *)urlPath
               block:(void(^)())block
{
    NSURLSessionDownloadTask *task = [self.downloadingMap objectForKey:[self getFileIdentifier:fileName downloadPath:urlPath]];
    NSMutableDictionary *downloader = [self getDownloadFile:fileName downloadPath:urlPath];
    if (task) {
        [task cancel];
        [self.downloadingMap removeObjectForKey:[self getFileIdentifier:fileName downloadPath:urlPath]];
        [self removeDownloadData:downloader];
    }
}

#pragma mark - NSURLSession Delegate method implementation

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    
    NSMutableDictionary *downloader = [self getDownloadDataByTaskID:downloadTask];
    
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *destinationFilename = downloadTask.originalRequest.URL.lastPathComponent;
    NSURL *destinationURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",[downloader objectForKey:DOWNLOADER_LOCALSOURCE],destinationFilename]];
    
    if ([fileManager fileExistsAtPath:[destinationURL path]]) {
        [fileManager removeItemAtURL:destinationURL error:nil];
    }
    
    BOOL success = [fileManager copyItemAtURL:location
                                        toURL:destinationURL
                                        error:&error];
    
    if (success) {
        
        [downloader setObject:[NSNumber numberWithBool:YES] forKey:DOWNLOADER_DOWNLOADCOMPLETE];
        [self.downloadingMap removeObjectForKey:[self getFileIdentifier:[downloader objectForKey:DOWNLOADER_TITLE] downloadPath:[downloader objectForKey:DOWNLOADER_DOWNLOADSOURCE]]];
        [downloader setObject:[NSNumber numberWithInteger:-1] forKey:DOWNLOADER_TAKIDENTIFIER];
        [downloader removeObjectForKey:DOWNLOADER_RESUMEDATA];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (_downloadComplete) {
                _downloadComplete(YES);
            }
        }];
    }
    else{
        if (_downloadFailure) {
            _downloadFailure(error);
        }
    }
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error != nil) {
        _downloadFailure(error);
    }
    else{
        NSLog(@"Download finished successfully.");
    }
}


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
        NSLog(@"Unknown transfer size");
    } else {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            NSMutableDictionary *downloader = [self getDownloadDataByTaskID:downloadTask];
            
            double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
            NSLog(@"progress%0.2f",progress);
            if (_downloadProgress) {
                _downloadProgress(progress,downloadTask,[downloader objectForKey:DOWNLOADER_TITLE],[downloader objectForKey:DOWNLOADER_DOWNLOADSOURCE]);
            }
        }];
    }
}


-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    // Check if all download tasks have been finished.
    [_sessionManager getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        if ([downloadTasks count] == 0) {
            if (appDelegate.backgroundTransferCompletionHandler != nil) {
                // Copy locally the completion handler.
                void(^completionHandler)() = appDelegate.backgroundTransferCompletionHandler;
                
                // Make nil the backgroundTransferCompletionHandler.
                appDelegate.backgroundTransferCompletionHandler = nil;
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    // Call the completion handler to tell the system that there are no other background transfers.
                    completionHandler();
                    
                    // Show a local notification when all downloads are over.
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.alertBody = @"All files have been downloaded!";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }];
            }
        }
    }];
}

//-(FileDownloadInfo *)getFileDownloadInfoIndexWithTaskIdentifier:(unsigned long)taskIdentifier{
//    FileDownloadInfo *targetFdi = 0;
//    for (int i=0; i<[self.downloadList count]; i++) {
//        FileDownloadInfo *fdi = [self.downloadList objectAtIndex:i];
//        if (fdi.taskIdentifier == taskIdentifier) {
//            targetFdi = fdi;
//            break;
//        }
//    }
//    
//    return targetFdi;
//}


@end
