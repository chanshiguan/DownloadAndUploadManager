//
//  EZNetworkManager.h
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/5.
//  Copyright © 2016年 owen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EZNetworkManager : NSURLSession

+ (instancetype)sharedInstance;

@end
