//
//  MLMenuTableViewController.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 20.05.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLMenuTableViewController.h"
#import "MLTableViewCell.h"
#import "MLDataCollectionViewController.h"
#import "MLFlowLayout.h"

typedef NS_ENUM(NSUInteger, MLMenuSection) {
    MLMenuSectionCollectionView,
    MLMenuSectionMultipleCollectionViews,
    MLMenuSectionCount
};

typedef NS_ENUM(NSUInteger, MLMenuCollection) {
    MLMenuCollectionVertical,
    MLMenuCollectionHorizontal,
    MLMenuCollectionCount
};

typedef NS_ENUM(NSUInteger, MLMenuMultiple) {
    MLMenuMultipleCount
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
    MLDataCollectionViewController * viewController = nil;
    
    switch (indexPath.section) {
        case MLMenuSectionCollectionView: {
            switch (indexPath.row) {
                case MLMenuCollectionVertical: {
                    MLFlowLayout * layout = [[MLFlowLayout alloc] init];
                    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
                    viewController = [[MLDataCollectionViewController alloc] initWithCollectionViewLayout:layout];
                } break;
                case MLMenuCollectionHorizontal: {
                    MLFlowLayout * layout = [[MLFlowLayout alloc] init];
                    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
                    viewController = [[MLDataCollectionViewController alloc] initWithCollectionViewLayout:layout];
                } break;
            }
        } break;
        case MLMenuSectionMultipleCollectionViews: {
            switch (indexPath.row) {
                default: break;
            }
        } break;
    }

    if (viewController) {
        UINavigationController * navigationController = self.splitViewController.viewControllers[1];
        [navigationController setViewControllers:@[viewController] animated:YES];
    }
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MLTableViewCell * cell = [MLTableViewCell cellForTableView:tableView indexPath:indexPath];
    
    switch (indexPath.section) {
        case MLMenuSectionCollectionView: {
            switch (indexPath.row) {
                case MLMenuCollectionVertical: {
                    cell.textLabel.text = @"Vertical";
                } break;
                case MLMenuCollectionHorizontal: {
                    cell.textLabel.text = @"Horizontal";
                } break;
            }
        } break;
        case MLMenuSectionMultipleCollectionViews: {
            switch (indexPath.row) {
                default: break;
            }
        } break;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case MLMenuSectionCollectionView: {
            return MLMenuCollectionCount;
        }
        case MLMenuSectionMultipleCollectionViews: {
            return MLMenuMultipleCount;
        }
        default: {
            return 0;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return MLMenuSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case MLMenuSectionCollectionView: {
            return @"Collection View";
        }
        case MLMenuSectionMultipleCollectionViews: {
            return @"Multiple";
        }
        default: {
            return nil;
        }
    }
}

@end
