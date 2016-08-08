//
//  DownloadSingleFileViewController.h
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/8.
//  Copyright © 2016年 owen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DownloadSingleFileViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
- (IBAction)beginDownload:(id)sender;

@end
