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

@interface EZDownloadManager : NSObject
{
    DownloadComplete _downloadComplete;
    DownloadFailure _downloadFailure;
}

@property (nonatomic, strong) NSMutableArray *downloadList;
@property (nonatomic, strong) EZNetworkManager *sessionManager;

+ (instancetype)sharedInstance;

- (void)addDownloadFile:(FileDownloadInfo *)fdi
                 toPath:(NSString *)url
               progress:(float)progress
                success:(DownloadComplete)success
                failure:(DownloadFailure)failure;

@end
