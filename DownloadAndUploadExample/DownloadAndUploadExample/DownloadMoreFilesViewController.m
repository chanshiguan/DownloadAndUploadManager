//
//  DownloadMoreFilesViewController.m
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/8.
//  Copyright © 2016年 owen. All rights reserved.
//

#import "DownloadMoreFilesViewController.h"
#import "EZDownloadManager.h"

#define CellLabelTagValue               10
#define CellStartPauseButtonTagValue    20
#define CellStopButtonTagValue          30
#define CellProgressBarTagValue         40
#define CellLabelReadyTagValue          50

@interface DownloadMoreFilesViewController ()
{
    EZDownloadManager *downloadManager;
}
@end

@implementation DownloadMoreFilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeFileDownloadDataArray];
    [self.tableView reloadData];
    
    downloadManager = [EZDownloadManager sharedInstance];
    __weak __typeof(self)weakSelf = self;
    [downloadManager setDownloadProgress:^(float progress, NSURLSessionDownloadTask *downloadTask, NSString *fileName,NSString *urlPath) {
        for (NSDictionary *obj in weakSelf.dataList) {
            if ([[obj objectForKey:@"title"] isEqualToString:fileName] &&
                [[obj objectForKey:@"downloadSource"] isEqualToString:urlPath]) {
                NSInteger idex = [weakSelf.dataList indexOfObject:obj];
                UITableViewCell *cell = [weakSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idex inSection:0]];
                UIProgressView *progressView = (UIProgressView *)[cell viewWithTag:CellProgressBarTagValue];
                progressView.progress = progress;
            }
        }
    }];
    
    [downloadManager setDownloadComplete:^(NSString *fileName,NSString *urlPath) {
        for (NSDictionary *obj in weakSelf.dataList) {
            if ([[obj objectForKey:@"title"] isEqualToString:fileName] &&
                [[obj objectForKey:@"downloadSource"] isEqualToString:urlPath]) {
                NSInteger idex = [weakSelf.dataList indexOfObject:obj];
                [weakSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idex inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }];
    
    [downloadManager setDownloadFailure:^(NSError *error,NSString *fileName,NSString *urlPath) {
        NSLog(@"%@",[error localizedDescription]);
        for (NSDictionary *obj in weakSelf.dataList) {
            if ([[obj objectForKey:@"title"] isEqualToString:fileName] &&
                [[obj objectForKey:@"downloadSource"] isEqualToString:urlPath]) {
                NSInteger idex = [weakSelf.dataList indexOfObject:obj];
                [weakSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idex inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }];
}

- (void)initializeFileDownloadDataArray
{
    self.dataList = [NSMutableArray array];
    
    NSDictionary *data1 = @{@"title":@"QQ8.4",
                            @"downloadSource":@"http://dldir1.qq.com/qqfile/qq/QQ8.4/18380/QQ8.4.exe"};
    NSDictionary *data2 = @{@"title":@"Human Interface Guidelines",
                            @"downloadSource":@"http://manuals.info.apple.com/MANUALS/1000/MA1565/en_US/iphone_user_guide.pdf"};
    NSDictionary *data3 = @{@"title":@"mac QQ_V5.1.1",
                            @"downloadSource":@"http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.1.1.dmg"};
    NSDictionary *data4 = @{@"title":@"MAC QQ",
                            @"downloadSource":@"http://dldir1.qq.com/music/clntupate/mac/QQMusic4.0Build09.dmg"};
    [self.dataList addObject:data1];
    [self.dataList addObject:data2];
    [self.dataList addObject:data3];
    [self.dataList addObject:data4];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"idCell"];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"idCell"];
    }
    
    NSDictionary *obj = [self.dataList objectAtIndex:indexPath.row];
    
    UILabel *displayedTitle = (UILabel *)[cell viewWithTag:10];
    UIButton *startPauseButton = (UIButton *)[cell viewWithTag:CellStartPauseButtonTagValue];
    UIButton *stopButton = (UIButton *)[cell viewWithTag:CellStopButtonTagValue];
    UIProgressView *progressView = (UIProgressView *)[cell viewWithTag:CellProgressBarTagValue];
    UILabel *readyLabel = (UILabel *)[cell viewWithTag:CellLabelReadyTagValue];
    
    NSString *startPauseButtonImageName;
    progressView.progress = 0;
    
    displayedTitle.text = [obj objectForKey:@"title"];
    
    EZDownloadManager *manager = [EZDownloadManager sharedInstance];
    EZDownloadState state = [manager getDownloadState:[obj objectForKey:@"title"] downloadPath:[obj objectForKey:@"downloadSource"]];
    if( state!= EZDownloadStateDownloading)
    {
        progressView.hidden = YES;
        stopButton.enabled = NO;
        
        BOOL hideControls = state == EZDownloadStateFinish ? YES : NO;
        startPauseButton.hidden = hideControls;
        stopButton.hidden = hideControls;
        readyLabel.hidden = !hideControls;
        startPauseButtonImageName = @"play-25";
    }
    else
    {
        progressView.hidden = NO;
        stopButton.enabled = YES;
        startPauseButtonImageName = @"pause-25";
    }
    [startPauseButton setImage:[UIImage imageNamed:startPauseButtonImageName] forState:UIControlStateNormal];
    
    return cell;
}

- (IBAction)startOrPauseDownloadingSingleFile:(id)sender event:(id)event
{
    NSSet *touches =[event allTouches];
    UITouch *touch =[touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath= [self.tableView indexPathForRowAtPoint:currentTouchPosition];
    if (indexPath == nil)
    {
        return;
    }
    
    NSDictionary *dic = [self.dataList objectAtIndex:indexPath.row];
    EZDownloadState state = [[EZDownloadManager sharedInstance] getDownloadState:[dic objectForKey:@"title"] downloadPath:[dic objectForKey:@"downloadSource"]];
    __weak typeof(self) weakSelf = self;
    if (state == EZDownloadStateDownloading) {
        [[EZDownloadManager sharedInstance] pasteDownload:[dic objectForKey:@"title"] downloadPath:[dic objectForKey:@"downloadSource"] block:^(NSString *tempPaht) {
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }];
    } else {
        NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        
        [[EZDownloadManager sharedInstance] downloadFile:[dic objectForKey:@"title"] downloadPath:[dic objectForKey:@"downloadSource"] localPath:[URLs objectAtIndex:0] block:^{
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }
    
    
    
    
}

- (IBAction)stopDownloading:(id)sender event:(id)event
{
    NSSet *touches =[event allTouches];
    UITouch *touch =[touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath= [self.tableView indexPathForRowAtPoint:currentTouchPosition];
    if (indexPath == nil)
    {
        return;
    }
    NSDictionary *obj = [self.dataList objectAtIndex:indexPath.row];
    __weak typeof(self) weakSelf=  self;
    [[EZDownloadManager sharedInstance] stopDownload:[obj objectForKey:@"title"] downloadPath:[obj objectForKey:@"downloadSource"] block:^{
        [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

@end
