//
//  ViewController.m
//  DownloadAndUploadExample
//
//  Created by Owen.li on 16/8/5.
//  Copyright © 2016年 owen. All rights reserved.
//

#import "ViewController.h"
#import "DownloadSingleFileViewController.h"
#import "DownloadMoreFilesViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataList = @[@"单个下载",@"多个下载",@"全部下载"];
    [self.tableView reloadData];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell_identifier" forIndexPath:indexPath];
    cell.textLabel.text = [self.dataList objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
        {
            DownloadSingleFileViewController *singleFile = [self.storyboard instantiateViewControllerWithIdentifier:@"downloadSingleFileViewController"];
            [self.navigationController pushViewController:singleFile animated:YES];
        }
            break;
        case 1:
        {
            DownloadMoreFilesViewController *moreFiles = [self.storyboard instantiateViewControllerWithIdentifier:@"downloadMoreFilesViewController"];
            [self.navigationController pushViewController:moreFiles animated:YES];
        }
            break;
            
        default:
            break;
    }
}

@end
