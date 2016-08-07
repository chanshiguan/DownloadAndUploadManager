//
//  EZDownloadManager.m
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/5.
//  Copyright © 2016年 owen. All rights reserved.
//

#import "EZDownloadManager.h"
#import "AppDelegate.h"

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
        self.downloadList = [NSMutableArray array];
        
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.BGTransferDemo"];
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 5;
        self.sessionManager = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                     delegate:self
                                                delegateQueue:nil];
    }
    return self;
}

- (void)startDownload:(FileDownloadInfo *)fdi;
{
#warning 重复点击怎么办？
    if (!fdi.isDownloading) {
        if (fdi.taskIdentifier == -1) {
            fdi.downloadTask = [_sessionManager downloadTaskWithURL:[NSURL URLWithString:fdi.downloadSource]];
            
            fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
            [fdi.downloadTask resume];
            [self.downloadList addObject:fdi];
            
        } else {
            
            fdi.downloadTask = [_sessionManager downloadTaskWithResumeData:fdi.taskResumeData];
            [fdi.downloadTask resume];
            
            fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
        }
    }
    fdi.isDownloading = !fdi.isDownloading;
}

- (void)pasteDownload:(FileDownloadInfo *)fdi
                block:(void(^)(NSString *tempPaht))block
{
    if (!fdi.isDownloading) {
        return;
    }
    [fdi.downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
        if (resumeData != nil) {
            fdi.taskResumeData = [[NSData alloc] initWithData:resumeData];
            //备份数据
            if (block) {
                block(@"");
            }
            
        }
    }];
}

- (void)stopDownload:(FileDownloadInfo *)fdi
               block:(void(^)())block
{
    if (fdi.isDownloading) {
        // Cancel the task.
        [fdi.downloadTask cancel];
        
        fdi.isDownloading = NO;
        fdi.taskIdentifier = -1;
        fdi.downloadProgress = 0.0;
        fdi.downloadTask = nil;
    }
}

- (void)addDownloadFile:(FileDownloadInfo *)fdi
               progress:(DownloadProgress)progress
                success:(DownloadComplete)success
                failure:(DownloadFailure)failure
{
    
    _downloadProgress = progress;
    _downloadComplete = success;
    _downloadFailure = failure;
    [self startDownload:fdi];
}

#pragma mark - NSURLSession Delegate method implementation

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    
    FileDownloadInfo *targetFdi = [self getFileDownloadInfoIndexWithTaskIdentifier:downloadTask.taskIdentifier];
    
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *destinationFilename = downloadTask.originalRequest.URL.lastPathComponent;
    NSURL *destinationURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",targetFdi.loacalSource,destinationFilename]];
    
    if ([fileManager fileExistsAtPath:[destinationURL path]]) {
        [fileManager removeItemAtURL:destinationURL error:nil];
    }
    
    BOOL success = [fileManager copyItemAtURL:location
                                        toURL:destinationURL
                                        error:&error];
    
    if (success) {
        
        targetFdi.isDownloading = NO;
        targetFdi.downloadComplete = YES;
        
        // Set the initial value to the taskIdentifier property of the fdi object,
        // so when the start button gets tapped again to start over the file download.
        targetFdi.taskIdentifier = -1;
        
        // In case there is any resume data stored in the fdi object, just make it nil.
        targetFdi.taskResumeData = nil;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // Reload the respective table view row using the main thread.
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
            FileDownloadInfo *fdi = [self getFileDownloadInfoIndexWithTaskIdentifier:downloadTask.taskIdentifier];
            fdi.downloadProgress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
            NSLog(@"progress%0.2f",fdi.downloadProgress);
            if (_downloadProgress) {
                _downloadProgress(fdi.downloadProgress,totalBytesWritten,totalBytesExpectedToWrite);
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

-(FileDownloadInfo *)getFileDownloadInfoIndexWithTaskIdentifier:(unsigned long)taskIdentifier{
    FileDownloadInfo *targetFdi = 0;
    for (int i=0; i<[self.downloadList count]; i++) {
        FileDownloadInfo *fdi = [self.downloadList objectAtIndex:i];
        if (fdi.taskIdentifier == taskIdentifier) {
            targetFdi = fdi;
            break;
        }
    }
    
    return targetFdi;
}

@end
