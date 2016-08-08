//
//  DownloadMoreFilesViewController.m
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/8.
//  Copyright © 2016年 owen. All rights reserved.
//

#import "DownloadMoreFilesViewController.h"
#import "FileDownloadInfo.h"
#import "EZDownloadManager.h"

#define CellLabelTagValue               10
#define CellStartPauseButtonTagValue    20
#define CellStopButtonTagValue          30
#define CellProgressBarTagValue         40
#define CellLabelReadyTagValue          50

@interface DownloadMoreFilesViewController ()

@end

@implementation DownloadMoreFilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeFileDownloadDataArray];
    [self.tableView reloadData];
}

- (void)initializeFileDownloadDataArray
{
    self.dataList = [NSMutableArray array];
    
    NSDictionary *data1 = @{@"title":@"test1",
                            @"downloadSource":@"http://dl2.itools.hk/dl/iTools64_Pro_1.6.9.dmg"};
    NSDictionary *data2 = @{@"title":@"Human Interface Guidelines",
                            @"downloadSource":@"http://manuals.info.apple.com/MANUALS/1000/MA1565/en_US/iphone_user_guide.pdf"};
    NSDictionary *data3 = @{@"title":@"MobileHIG.pdf",
                            @"downloadSource":@"https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/MobileHIG/MobileHIG.pdf"};
    NSDictionary *data4 = @{@"title":@"AV Foundation",
                            @"downloadSource":@"https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/AVFoundationPG.pdf"};
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
    
    //Get the respective FileDownloadInfo object from the arrFileDownloadData array
    NSDictionary *obj = [self.dataList objectAtIndex:indexPath.row];
    
    //Get all cell's subviews
    UILabel *displayedTitle = (UILabel *)[cell viewWithTag:10];
    UIButton *startPauseButton = (UIButton *)[cell viewWithTag:CellStartPauseButtonTagValue];
    UIButton *stopButton = (UIButton *)[cell viewWithTag:CellStopButtonTagValue];
    UIProgressView *progressView = (UIProgressView *)[cell viewWithTag:CellProgressBarTagValue];
    UILabel *readyLabel = (UILabel *)[cell viewWithTag:CellLabelReadyTagValue];
    
    NSString *startPauseButtonImageName;
    progressView.progress = 0;
    //Set the file title
    displayedTitle.text = [obj objectForKey:@"title"];
    
//    if(!fdi.isDownloading)
//    {
//        //Hide the progress view and disable the stop button
//        progressView.hidden = YES;
//        stopButton.enabled = NO;
//        
//        BOOL hideControls = (fdi.downloadComplete) ? YES : NO;
//        startPauseButton.hidden = hideControls;
//        stopButton.hidden = hideControls;
//        readyLabel.hidden = !hideControls;
//        
//        startPauseButtonImageName = @"play-25";
//    }
//    else
//    {
//        progressView.hidden = NO;
//        
//        stopButton.enabled = YES;
//        
//        startPauseButtonImageName = @"pause-25";
//    }
//    [startPauseButton setImage:[UIImage imageNamed:startPauseButtonImageName] forState:UIControlStateNormal];
    
    return cell;
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSDictionary *dic = [self.dataList objectAtIndex:indexPath.row];
    
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    
    __weak UITableViewCell *weakCell = cell;
    FileDownloadInfo *fdi = [[FileDownloadInfo alloc] initWithFileTitle:[dic objectForKey:@"title"] downloadSource:[dic objectForKey:@"downloadSource"] localSource:[URLs objectAtIndex:0]];
    [[EZDownloadManager sharedInstance] addDownloadFile:fdi progress:^(float progress, NSURLSessionDownloadTask *downloadTask, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        UIProgressView *progressView = (UIProgressView *)[weakCell viewWithTag:CellProgressBarTagValue];
        progressView.progress = progress;
    } success:^(BOOL isSuccess) {
        
    } failure:^(NSError *error) {
        //
    }];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (IBAction)stopDownloading:(id)sender event:(id)event
{
//    if ([[[[sender superview] superview] superview] isKindOfClass:[UITableViewCell class]])
//    {
//        // Get the container cell.
//        UITableViewCell *containerCell = (UITableViewCell *)[[[sender superview] superview] superview];
//        
//        // Get the row (index) of the cell. We'll keep the index path as well, we'll need it later.
//        NSIndexPath *cellIndexPath = [self.tblFiles indexPathForCell:containerCell];
//        int cellIndex = cellIndexPath.row;
//        
//        // Get the FileDownloadInfo object being at the cellIndex position of the array.
//        FileDownloadInfo *fdi = [self.arrFileDownloadData objectAtIndex:cellIndex];
//        
//        //Cancel the task
//        [fdi.downloadTask cancel];
//        
//        //Change all related properties
//        fdi.isDownloading = NO;
//        fdi.taskIdentifier = -1;
//        fdi.downloadProgress = 0.0;
//        
//        //Reload the table view
//        [self.tblFiles reloadRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
//        
//    }
}

@end
