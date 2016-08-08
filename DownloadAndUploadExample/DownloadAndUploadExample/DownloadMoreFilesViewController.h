//
//  DownloadMoreFilesViewController.h
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/8.
//  Copyright © 2016年 owen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DownloadMoreFilesViewController : UITableViewController<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *dataList;

- (IBAction)startOrPauseDownloadingSingleFile:(id)sender event:(id)event;

- (IBAction)stopDownloading:(id)sender event:(id)event;

@end
