//
//  FileDownloadInfo.m
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/5.
//  Copyright © 2016年 owen. All rights reserved.
//

#import "FileDownloadInfo.h"

@implementation FileDownloadInfo

-(id)initWithFileTitle:(NSString *)title
        downloadSource:(NSString *)downloadSource
           localSource:(NSString *)loacalSource{
    if (self == [super init]) {
        self.fileTitle = title;
        self.downloadSource = downloadSource;
        self.loacalSource = loacalSource;
//        self.downloadProgress = 0.0;
        self.isDownloading = NO;
        self.downloadComplete = NO;
        self.taskIdentifier = -1;
    }
    
    return self;
}

@end
