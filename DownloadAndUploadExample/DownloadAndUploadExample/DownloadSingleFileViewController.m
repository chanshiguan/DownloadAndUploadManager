//
//  DownloadSingleFileViewController.m
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/8.
//  Copyright © 2016年 owen. All rights reserved.
//

#import "DownloadSingleFileViewController.h"
#import "EZDownloadManager.h"

@interface DownloadSingleFileViewController ()
{
    UIProgressView *proview;
}
@end

@implementation DownloadSingleFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [self beginDownload:nil];
}

- (IBAction)beginDownload:(id)sender
{
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    EZDownloadManager *downloadManager = [EZDownloadManager sharedInstance];
    
    __weak __typeof(self)weakSelf = self;
    
    [downloadManager downloadFile:@"test" downloadPath:@"http://manuals.info.apple.com/MANUALS/1000/MA1565/en_US/iphone_user_guide.pdf" localPath:[URLs objectAtIndex:0] progress:^(float progress, NSURLSessionDownloadTask *downloadTask, NSString *fileName,NSString *urlPath) {
        
        weakSelf.progressView.progress = progress;
        
    } success:^(BOOL isSuccess) {
        NSLog(@"success");
    } failure:^(NSError *error) {
        NSLog(@"%@",[error localizedDescription]);
    }];
}

- (IBAction)paste:(id)sender
{
    EZDownloadManager *downloadManager = [EZDownloadManager sharedInstance];
    [downloadManager pasteDownload:@"test" downloadPath:@"http://manuals.info.apple.com/MANUALS/1000/MA1565/en_US/iphone_user_guide.pdf" block:^(NSString *tempPaht) {
        //
    }];
}

@end
