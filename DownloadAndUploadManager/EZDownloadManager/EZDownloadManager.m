//
//  EZDownloadManager.m
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/5.
//  Copyright © 2016年 owen. All rights reserved.
//

#import "EZDownloadManager.h"

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
        self.sessionManager = [EZNetworkManager sharedInstance];
    }
    return self;
}

- (void)addDownloadFile:(FileDownloadInfo *)fdi
                 toPath:(NSString *)url
               progress:(float)progress
                success:(DownloadComplete)success
                failure:(DownloadFailure)failure
{
    if (!fdi.isDownloading) {
        if (fdi.taskIdentifier == -1) {
            fdi.downloadTask = [_sessionManager downloadTaskWithURL:[NSURL URLWithString:fdi.downloadSource]];
            fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
            [fdi.downloadTask resume];
        }
    } else {
        //  A new download task is created by using the downloadTaskWithResumeData: method of the session object.
        //  This new task is assigned to the downloadTask object for future access, and then it’s resumed.
        //  Finally, the new task identifier is stored to the respective property.
        
        //Create a new download task, which will use the stored resume data
        fdi.downloadTask = [_sessionManager downloadTaskWithResumeData:fdi.ta];
        [fdi.downloadTask resume];
        
        //Keep the new download task identifier
        fdi.taskIdentifier = fdi.downloadTask.taskIdentifier;
    }
}

@end
