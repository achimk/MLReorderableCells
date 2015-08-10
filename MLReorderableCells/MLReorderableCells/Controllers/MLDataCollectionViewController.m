//
//  MLDataCollectionViewController.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 20.05.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLDataCollectionViewController.h"
#import "MLFlowLayout.h"
#import "MLReorderableCollection.h"
#import "MLSettingsTableViewController.h"

#define NUMBER_OF_INITIAL_ITEMS     24

#pragma mark - MLDataCollectionViewController

@interface MLDataCollectionViewController () <MLReorderableCollectionDelegate, MLReorderableCollectionDataSource>

@property (nonatomic, readwrite, strong) MLReorderableCollection * reorderableCollection;
@property (nonatomic, readwrite, strong) id cachedObject;

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
    self.canInsertItems = YES;
    self.canDeleteItems = YES;
    self.canReplaceItems = YES;
    self.canMoveItems = NO;

    self.reorderableCollection = [[MLReorderableCollection alloc] initWithCollectionView:self.collectionView];
    
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

- (IBAction)settingsAction:(id)sender {
    MLSettingsTableViewController * settingsViewController = [[MLSettingsTableViewController alloc] initWithCollectionViewController:self];
    UIPopoverController * popover = [[UIPopoverController alloc] initWithContentViewController:settingsViewController];
    popover.popoverContentSize = CGSizeMake(320.0f, MLOptionCount * 44.0f);
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
    self.cachedObject = nil;
}

#pragma mark - MLReorderableCollectionDataSource

#pragma mark Reorder

- (BOOL)collectionView:(UICollectionView *)collectionView canReorderItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.canReorderItems;
}

- (UIView *)reorderableCollectionContainerForCollectionView:(UICollectionView *)collectionView {
    return (self.useMainContainer) ? self.splitViewController.view : collectionView;
}

- (NSIndexPath *)indexPathForNewItemInCollectionView:(UICollectionView *)collectionView {
    return (0 == self.resultsController.listObjects.count) ? [NSIndexPath indexPathForRow:0 inSection:0] : nil;
}

#pragma mark Insert

- (BOOL)collectionView:(UICollectionView *)collectionView canInsertItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.canInsertItems;
}

- (void)collectionView:(UICollectionView *)collectionView willInsertItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)collectionView:(UICollectionView *)collectionView didInsertItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.resultsController insertObject:self.cachedObject atIndexPath:indexPath];
    self.cachedObject = nil;
}

#pragma mark Delete

- (BOOL)collectionView:(UICollectionView *)collectionView canDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.canDeleteItems;
}

- (void)collectionView:(UICollectionView *)collectionView willDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)collectionView:(UICollectionView *)collectionView didDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
    self.cachedObject = [self.resultsController objectAtIndexPath:indexPath];
    [self.resultsController removeObjectAtIndexPath:indexPath];
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

#pragma mark Move

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
    return self.canMoveItems;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath {
    [self.resultsController moveObjectAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

@end
