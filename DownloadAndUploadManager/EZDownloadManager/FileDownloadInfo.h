//
//  FileDownloadInfo.h
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/5.
//  Copyright © 2016年 owen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileDownloadInfo : NSObject

@property (nonatomic, strong) NSString *fileTitle;  //文件名

@property (nonatomic, strong) NSString *downloadSource;     //下载地址

@property (nonatomic, strong) NSString *loacalSource;       //本地存储路径

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;       //下载进程

@property (nonatomic, strong) NSData *taskResumeData;   

@property (nonatomic) double downloadProgress;  //下载进度

@property (nonatomic) BOOL isDownloading;       //下载进度

@property (nonatomic) BOOL downloadComplete;    //下载状态

@property (nonatomic) unsigned long taskIdentifier; //下载标识

-(id)initWithFileTitle:(NSString *)title
        downloadSource:(NSString *)downloadSource
           localSource:(NSString *)loacalSource;
@end
