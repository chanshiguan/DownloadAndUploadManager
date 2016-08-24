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
    EZDownloadManager *downloadManager;
}
@end

@implementation DownloadSingleFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    downloadManager = [EZDownloadManager sharedInstance];
    __weak __typeof(self)weakSelf = self;
    [downloadManager setDownloadProgress:^(float progress, NSURLSessionDownloadTask *downloadTask, NSString *fileName,NSString *urlPath) {
        if ([fileName isEqualToString:@"test"] &&
            [urlPath isEqualToString:@"http://manuals.info.apple.com/MANUALS/1000/MA1565/en_US/iphone_user_guide.pdf"]) {
            weakSelf.progressView.progress = progress;
        }
    }];
    
    [downloadManager setDownloadComplete:^(NSString *fileName,NSString *urlPath) {
        NSLog(@"success");
    }];
    
    [downloadManager setDownloadFailure:^(NSError *error,NSString *fileName,NSString *urlPath) {
        NSLog(@"%@",[error localizedDescription]);
    }];
}

- (IBAction)beginDownload:(id)sender
{
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];

    [downloadManager downloadFile:@"test" downloadPath:@"http://manuals.info.apple.com/MANUALS/1000/MA1565/en_US/iphone_user_guide.pdf" localPath:[URLs objectAtIndex:0] block:^{
        //
    }];
}

- (IBAction)paste:(id)sender
{
    [downloadManager pasteDownload:@"test" downloadPath:@"http://manuals.info.apple.com/MANUALS/1000/MA1565/en_US/iphone_user_guide.pdf" block:^(NSString *tempPaht) {
        //
    }];
}

@end
