//
//  EZNetworkManager.m
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/5.
//  Copyright © 2016年 owen. All rights reserved.
//

#import "EZNetworkManager.h"

@implementation EZNetworkManager

static EZNetworkManager *instance = nil;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.BGTransferDemo"];
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 5;
        
        instance = [self sessionWithConfiguration:sessionConfiguration];
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

@end
