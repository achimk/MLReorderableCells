//
//  MLMenuTableViewController.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 20.05.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLMenuTableViewController.h"
#import "MLTableViewCell.h"

typedef NS_ENUM(NSUInteger, MLMenuItem) {
    MLMenuItemReorderableCollection,
    MLMenuItemCount
};

#pragma mark - MLMenuTableViewController

@interface MLMenuTableViewController ()

@end

#pragma mark -

@implementation MLMenuTableViewController

#pragma mark View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnReloadData = NO;
    self.clearsSelectionOnViewWillAppear = NO;
    
    [MLTableViewCell registerCellWithTableView:self.tableView];
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case MLMenuItemReorderableCollection: {
            NSLog(@"-> %@: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        } break;
    }
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MLTableViewCell * cell = [MLTableViewCell cellForTableView:tableView indexPath:indexPath];
    
    switch (indexPath.row) {
        case MLMenuItemReorderableCollection: {
            cell.textLabel.text = @"Collection";
        } break;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MLMenuItemCount;
}

@end
