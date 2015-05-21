//
//  MLDataCollectionViewController.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 20.05.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLDataCollectionViewController.h"
#import "MLFlowLayout.h"
#import "MLColorCollectionViewCell.h"
#import "MLColorModel.h"
#import "MLReorderableCollection.h"
#import <RZCollectionList/RZCollectionList.h>
#import "MLSettingsTableViewController.h"

#define NUMBER_OF_INITIAL_ITEMS     27

#pragma mark - MLDataCollectionViewController

@interface MLDataCollectionViewController () <MLReorderableCollectionDelegate, MLReorderableCollectionDataSource>

@property (nonatomic, readwrite, strong) RZArrayCollectionList * resultsController;
@property (nonatomic, readwrite, strong) MLReorderableCollection * reorderableCollection;

@end

#pragma mark -

@implementation MLDataCollectionViewController

+ (Class)defaultCollectionViewLayoutClass {
    return [MLFlowLayout class];
}

#pragma mark View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.useMainContainer = YES;
    self.canReorderItems = YES;
    self.canMoveItems = NO;
    self.canReplaceItems = YES;

    self.resultsController = [[RZArrayCollectionList alloc] initWithArray:@[] sectionNameKeyPath:nil];
    self.reorderableCollection = [[MLReorderableCollection alloc] initWithCollectionView:self.collectionView];
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [MLColorCollectionViewCell registerCellWithCollectionView:self.collectionView];
    
    
    UIBarButtonItem * addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction:)];
    UIBarButtonItem * clearItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(clearAction:)];
    UIBarButtonItem * randomItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(randomAction:)];
    UIBarButtonItem * settingsItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(settingsAction:)];
    self.navigationItem.rightBarButtonItems = @[settingsItem, clearItem, randomItem, addItem];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.appearsFirstTime) {
        [self randomAction:nil];
    }
}

#pragma mark Actions

- (IBAction)addAction:(id)sender {
    MLColorModel * model = [MLColorModel model];
    [self.resultsController addObject:model toSection:0];
    [self reloadData];
}

- (IBAction)clearAction:(id)sender {
    [self.resultsController removeAllObjects];
    [self reloadData];
}

- (IBAction)randomAction:(id)sender {
    [self.resultsController removeAllObjects];
    for (NSUInteger i = 0; i < NUMBER_OF_INITIAL_ITEMS; i++) {
        MLColorModel * model = [MLColorModel model];
        [self.resultsController addObject:model toSection:0];
    }
    [self reloadData];
}

- (IBAction)settingsAction:(id)sender {
    MLSettingsTableViewController * settingsViewController = [[MLSettingsTableViewController alloc] initWithCollectionViewController:self];
    UIPopoverController * popover = [[UIPopoverController alloc] initWithContentViewController:settingsViewController];
    popover.popoverContentSize = CGSizeMake(320.0f, 200.0f);
    [popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

#pragma mark MLReorderableCollectionDelegate

- (void)collectionView:(UICollectionView *)collectionView willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)collectionView:(UICollectionView *)collectionView didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)collectionView:(UICollectionView *)collectionView willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)collectionView:(UICollectionView *)collectionView didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - MLReorderableCollectionDataSource

#pragma mark Reorder

- (BOOL)collectionView:(UICollectionView *)collectionView canReorderItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.canReorderItems;
}

- (UIView *)reorderableCollectionContainerForCollectionView:(UICollectionView *)collectionView {
    return (self.useMainContainer) ? self.splitViewController.view : collectionView;
}

#pragma mark Move

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
    return self.canMoveItems;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath {
    [self.resultsController moveObjectAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

#pragma mark Replace

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canReplaceWithIndexPath:(NSIndexPath *)toIndexPath {
    return self.canReplaceItems;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willReplaceWithIndexPath:(NSIndexPath *)toIndexPath {
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didReplaceWithIndexPath:(NSIndexPath *)toIndexPath {
    id fromObject = [self.resultsController objectAtIndexPath:fromIndexPath];
    id toObject = [self.resultsController objectAtIndexPath:toIndexPath];
    
    [self.resultsController replaceObjectAtIndexPath:toIndexPath withObject:fromObject];
    [self.resultsController replaceObjectAtIndexPath:fromIndexPath withObject:toObject];
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark UICollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MLColorCollectionViewCell * cell = [MLColorCollectionViewCell cellForCollectionView:collectionView indexPath:indexPath];
    id object = [self.resultsController objectAtIndexPath:indexPath];
    [cell configureWithObject:object context:indexPath];
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.resultsController.sections count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    id <RZCollectionListSectionInfo> sectionInfo = [self.resultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

@end
