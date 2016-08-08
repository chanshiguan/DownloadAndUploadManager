//
//  DownloadSingleFileViewController.m
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/8.
//  Copyright © 2016年 owen. All rights reserved.
//

#import "DownloadSingleFileViewController.h"
#import "EZDownloadManager.h"
#import "FileDownloadInfo.h"

@interface DownloadSingleFileViewController ()
{
    FileDownloadInfo *fdi;
}
@end

@implementation DownloadSingleFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)beginDownload:(id)sender
{
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    fdi = [[FileDownloadInfo alloc] initWithFileTitle:@"test" downloadSource:@"http://dl2.itools.hk/dl/iTools64_Pro_1.6.9.dmg" localSource:[URLs objectAtIndex:0]];
    EZDownloadManager *downloadManager = [EZDownloadManager sharedInstance];
    [downloadManager addDownloadFile:fdi progress:^(float progress, NSURLSessionDownloadTask *downloadTask, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        self.progressView.progress = progress;
    } success:^(BOOL isSuccess) {
        NSLog(@"success");
    } failure:^(NSError *error) {
        NSLog(@"%@",[error localizedDescription]);
    }];
}

- (IBAction)paste:(id)sender
{
    EZDownloadManager *downloadManager = [EZDownloadManager sharedInstance];
    [downloadManager pasteDownload:fdi block:nil];
}

@end
