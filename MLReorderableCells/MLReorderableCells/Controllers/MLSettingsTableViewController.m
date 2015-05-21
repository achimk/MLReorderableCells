//
//  MLSettingsTableViewController.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 21.05.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLSettingsTableViewController.h"
#import "MLDataCollectionViewController.h"
#import "MLTableViewCell.h"

typedef NS_ENUM(NSUInteger, MLOptions) {
    MLOptionReorderItems,
    MLOptionMoveItems,
    MLOptionReplaceItems,
    MLOptionCount
};

#pragma mark - MLSettingsTableViewController

@interface MLSettingsTableViewController ()

@end

#pragma mark -

@implementation MLSettingsTableViewController

#pragma mark Init

- (instancetype)initWithCollectionViewController:(MLDataCollectionViewController *)collectionViewController {
    NSParameterAssert(collectionViewController);
    
    if (self = [super init]) {
        __weak typeof(collectionViewController)weakCollectionViewController = collectionViewController;
        _collectionViewController = weakCollectionViewController;
    }
    
    return self;
}

#pragma mark View

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.scrollEnabled = NO;
    self.clearsSelectionOnReloadData = YES;
    self.clearsSelectionOnViewWillAppear = YES;
    [MLTableViewCell registerCellWithTableView:self.tableView];
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case MLOptionReorderItems: {
            self.collectionViewController.canReorderItems = !self.collectionViewController.canReorderItems;
        } break;
        case MLOptionMoveItems: {
            self.collectionViewController.canMoveItems = !self.collectionViewController.canMoveItems;
        } break;
        case MLOptionReplaceItems: {
            self.collectionViewController.canReplaceItems = !self.collectionViewController.canReplaceItems;
        } break;
    }
    
    [self reloadData];
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MLTableViewCell * cell = [MLTableViewCell cellForTableView:tableView indexPath:indexPath];
    
    switch (indexPath.row) {
        case MLOptionReorderItems: {
            cell.textLabel.text = @"Allow reorder";
            cell.accessoryType = (self.collectionViewController.canReorderItems) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } break;
        case MLOptionMoveItems: {
            cell.textLabel.text = @"Allow move";
            cell.accessoryType = (self.collectionViewController.canMoveItems) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } break;
        case MLOptionReplaceItems: {
            cell.textLabel.text = @"Allow replace";
            cell.accessoryType = (self.collectionViewController.canReplaceItems) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } break;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MLOptionCount;
}


@end
