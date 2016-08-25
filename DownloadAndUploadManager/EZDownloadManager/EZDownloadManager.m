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

#define DOWNLOADER_DOWNLOADLIST @"downloadList" //下载文件管理
//可能要增加一个数组来管理本地存储的
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
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.runlin.downloader"];
        sessionConfiguration.discretionary = YES;   //discretionary属性为YES时表示当程序在后台运作时由系统自己选择最佳的网络连接配置，该属性可以节省通过蜂窝连接的带宽
        sessionConfiguration.allowsCellularAccess = NO; //默认不让使用蜂窝数据下载
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 5;
        self.sessionManager = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                     delegate:self
                                                delegateQueue:nil];
        
        // ----------------------------------------------------------------------------------------
        //|注释以下代码，app启动后，可以根据缓存自动开始下载。目前是实例化后，将下载进程全部暂停，需要让用户手动开启|
        // ----------------------------------------------------------------------------------------
        __weak typeof(self) weakSelf = self;
        [_sessionManager getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
            for (NSURLSessionDownloadTask *task in downloadTasks) {
                NSDictionary *downloader = [self getDownloadDataByTaskID:task.taskIdentifier];
                [weakSelf pasteDownload:[downloader objectForKey:DOWNLOADER_TITLE] downloadPath:[downloader objectForKey:DOWNLOADER_DOWNLOADSOURCE] block:nil];
            }
        }];
    }
    return self;
}

#pragma mark -------------------文件管理方法---------------------------
//获取下载唯一标识
- (NSString *)getFileIdentifier:(NSString *)fileName downloadPath:(NSString *)urlPath
{
    return [[NSString stringWithFormat:@"%@+%@",fileName,urlPath] md5String];
}

//获取本地下载对象
- (NSMutableDictionary *) getDownloadData:(NSString *)identifier
{
    return (NSMutableDictionary *)[[TMDiskCache sharedCache] objectForKey:identifier];
}

- (NSMutableArray *)getDownloadList
{
    NSArray *temp = (NSArray *)[[TMDiskCache sharedCache] objectForKey:DOWNLOADER_DOWNLOADLIST];
    NSMutableArray *list = nil;
    if (temp == nil) {
        list = [NSMutableArray array];
    } else {
        list = [NSMutableArray arrayWithArray:temp];
    }
    return list;
}

- (void)setObjectToDownloadList:(NSString *)identifier
{
    NSMutableArray *list = [self getDownloadList];
    if ([list containsObject:identifier]) {
        return;
    }
    [list addObject:identifier];
    [[TMDiskCache sharedCache] setObject:list forKey:DOWNLOADER_DOWNLOADLIST];
}

- (void)deleteObjectFromDownloadList:(NSString *)identifier
{
    NSMutableArray *list = [self getDownloadList];
    if ([list containsObject:identifier]) {
        return;
    }
    [list removeObject:identifier];
    [[TMDiskCache sharedCache] setObject:list forKey:DOWNLOADER_DOWNLOADLIST];
}

//根据下载task 的id 获取本地管理文件
- (NSMutableDictionary *)getDownloadDataByTaskID:(NSUInteger)taskIdentifier
{
    NSMutableDictionary *downloader = nil;
    for (NSString *str in [self getDownloadList]) {
        NSMutableDictionary *downloaderT = [self getDownloadData:str];
        NSInteger identifier = [[downloaderT objectForKey:DOWNLOADER_TAKIDENTIFIER] integerValue];
        if (identifier == taskIdentifier) {
            //说明我找到了正在下载的对象，也就是进度对应的对象
            downloader = downloaderT;
            break;
        }
    }
    return downloader;
}

//获取下载对象
- (NSMutableDictionary *)getDownloadFile:(NSString *)fileName downloadPath:(NSString *)urlPath
{
    NSString *identifier = [self getFileIdentifier:fileName downloadPath:urlPath];
    NSMutableDictionary *downloadFile = nil;
    NSMutableDictionary *temp = [self getDownloadData:identifier];
    if (temp == nil) {
        downloadFile = [NSMutableDictionary dictionaryWithObjectsAndKeys:fileName,DOWNLOADER_TITLE,urlPath,DOWNLOADER_DOWNLOADSOURCE,[NSNumber numberWithInteger:-1],DOWNLOADER_TAKIDENTIFIER,[NSNumber numberWithInteger:EZDownloadStateUnStart],DOWNLOADER_DOWNLOADCOMPLETE, nil];
    } else {
        downloadFile = [NSMutableDictionary dictionaryWithDictionary:temp];
    }
    return downloadFile;
}

//保存本地缓存数据
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


#pragma mark -------------------获取下载文件状态方法---------------------------
//获取进度
- (CGFloat)getDownloadProgress:(NSString *)fileName
                  downloadPath:(NSString *)urlPath
{
    return 0;
}

//获取下载状态
- (EZDownloadState)getDownloadState:(NSString *)fileName
                       downloadPath:(NSString *)urlPath
{
    NSMutableDictionary *downloader = [self getDownloadFile:fileName downloadPath:urlPath];
    if (downloader == nil) {
        return EZDownloadStateUnStart;
    }
    return (EZDownloadState)[[downloader objectForKey:DOWNLOADER_DOWNLOADCOMPLETE] integerValue];
}

- (NSString *)getLocalPath:(NSString *)fileName
              downloadPath:(NSString *)urlPath
{
    NSMutableDictionary *downloader = [self getDownloadFile:fileName downloadPath:urlPath];
    if (downloader == nil) {
        return @"";
    }
    NSString *localPath = [downloader objectForKey:DOWNLOADER_LOCALSOURCE];
    if (localPath == nil || [localPath isEqualToString:@""]) {
        return @"";
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        return localPath;
    } else {
        return @"";
    }
}

#pragma mark -------------------下载方法---------------------------
- (void)downloadFile:(NSString *)fileName
        downloadPath:(NSString *)urlPath
           localPath:(NSString *)localPath
               block:(void (^)())block
{
    if (fileName == nil || [@"" isEqualToString:fileName] ||
        urlPath == nil || [@"" isEqualToString:urlPath] ||
        localPath == nil || [@"" isEqualToString:localPath]) {
        return;
    }
    //如果正在下载，不可以重复下载
    EZDownloadState state = [self getDownloadState:fileName downloadPath:urlPath];
    if (state == EZDownloadStateDownloading) {
        return;
    }
    //设置数据源
    NSMutableDictionary *downloader = [self getDownloadFile:fileName downloadPath:urlPath];
    [downloader setObject:localPath forKey:DOWNLOADER_LOCALSOURCE];
    
    NSURLSessionDownloadTask *task = nil;
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
    [task resume];
    //设置标识
    [downloader setObject:[NSNumber numberWithInteger:task.taskIdentifier] forKey:DOWNLOADER_TAKIDENTIFIER];
    //将状态设置成开始下载
    [downloader setObject:[NSNumber numberWithInteger:EZDownloadStateDownloading] forKey:DOWNLOADER_DOWNLOADCOMPLETE];
    //保存对象
    [self saveDownloadData:downloader];
    //管理下载的对象
    [self setObjectToDownloadList:[self getFileIdentifier:fileName downloadPath:urlPath]];
    block();
}

- (void)pasteDownload:(NSString *)fileName
         downloadPath:(NSString *)urlPath
                block:(void(^)())block
{
    EZDownloadState state = [self getDownloadState:fileName downloadPath:urlPath];
    if (state != EZDownloadStateDownloading) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [_sessionManager getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        NSMutableDictionary *downloader = [weakSelf getDownloadFile:fileName downloadPath:urlPath];
        if (downloadTasks.count == 0) {
            //设置状态
            [downloader setObject:[NSNumber numberWithInteger:EZDownloadStatePause] forKey:DOWNLOADER_DOWNLOADCOMPLETE];
            [weakSelf saveDownloadData:downloader];
        } else {
            for (NSURLSessionDownloadTask *task in downloadTasks) {
                NSInteger identifier = [[downloader objectForKey:DOWNLOADER_TAKIDENTIFIER] integerValue];
                if (task.taskIdentifier != identifier) {
                    continue;
                }
                [task cancelByProducingResumeData:^(NSData *resumeData) {
                    if (resumeData != nil) {
                        [downloader setObject:[[NSData alloc] initWithData:resumeData] forKey:DOWNLOADER_RESUMEDATA];
                    }
                    //设置状态
                    [downloader setObject:[NSNumber numberWithInteger:EZDownloadStatePause] forKey:DOWNLOADER_DOWNLOADCOMPLETE];
                    [weakSelf saveDownloadData:downloader];
                }];
            }
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (block) {
                block(@"");
            }
        }];
    }];
}

- (void)stopDownload:(NSString *)fileName
        downloadPath:(NSString *)urlPath
               block:(void(^)())block
{
    EZDownloadState state = [self getDownloadState:fileName downloadPath:urlPath];
    if (state != EZDownloadStateDownloading) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [_sessionManager getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        NSMutableDictionary *downloader = [weakSelf getDownloadFile:fileName downloadPath:urlPath];
        for (NSURLSessionDownloadTask *task in downloadTasks) {
            NSInteger identifier = [[downloader objectForKey:DOWNLOADER_TAKIDENTIFIER] integerValue];
            if (task.taskIdentifier != identifier) {
                continue;
            }
            [task cancel];
            [weakSelf removeDownloadData:downloader];
            [weakSelf deleteObjectFromDownloadList:[self getFileIdentifier:fileName downloadPath:urlPath]];
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (block) {
                block(@"");
            }
        }];
    }];
}

#pragma mark - NSURLSession Delegate method implementation
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    
    NSMutableDictionary *downloader = [self getDownloadDataByTaskID:downloadTask.taskIdentifier];
    
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *destinationFilename = downloadTask.originalRequest.URL.lastPathComponent;
    NSURL *destinationURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",[downloader objectForKey:DOWNLOADER_LOCALSOURCE],destinationFilename]];
    
    if ([fileManager fileExistsAtPath:[destinationURL path]]) {
        [fileManager removeItemAtURL:destinationURL error:nil];
    }
    
    BOOL success = [fileManager copyItemAtURL:location
                                        toURL:destinationURL
                                        error:&error];
    
    if (success) {
        
        [self deleteObjectFromDownloadList:[self getFileIdentifier:[downloader objectForKey:DOWNLOADER_TITLE] downloadPath:[downloader objectForKey:DOWNLOADER_DOWNLOADSOURCE]]];
        //设置状态
        [downloader setObject:[NSNumber numberWithInteger:EZDownloadStateFinish] forKey:DOWNLOADER_DOWNLOADCOMPLETE];
        [downloader setObject:[NSNumber numberWithInteger:-1] forKey:DOWNLOADER_TAKIDENTIFIER];
        [downloader removeObjectForKey:DOWNLOADER_RESUMEDATA];
        [self saveDownloadData:downloader];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (_downloadComplete) {
                _downloadComplete([downloader objectForKey:DOWNLOADER_TITLE],[downloader objectForKey:DOWNLOADER_DOWNLOADSOURCE]);
            }
        }];
    }
    else{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (_downloadFailure) {
                _downloadFailure(error,[downloader objectForKey:DOWNLOADER_TITLE],[downloader objectForKey:DOWNLOADER_DOWNLOADSOURCE]);
            }
        }];
    }
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error != nil) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (_downloadFailure) {
                NSMutableDictionary *downloader = [self getDownloadDataByTaskID:task.taskIdentifier];
                _downloadFailure(error,[downloader objectForKey:DOWNLOADER_TITLE],[downloader objectForKey:DOWNLOADER_DOWNLOADSOURCE]);
            }
        }];
        
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
            
            NSMutableDictionary *downloader = [self getDownloadDataByTaskID:downloadTask.taskIdentifier];
            
            double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
            NSLog(@"%@ - %f",[downloader objectForKey:DOWNLOADER_TITLE],progress);
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
@end
