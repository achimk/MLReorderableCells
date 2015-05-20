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

#define NUMBER_OF_INITIAL_ITEMS     9

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

    self.resultsController = [[RZArrayCollectionList alloc] initWithArray:@[] sectionNameKeyPath:nil];
    self.reorderableCollection = [[MLReorderableCollection alloc] initWithCollectionView:self.collectionView];
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [MLColorCollectionViewCell registerCellWithCollectionView:self.collectionView];
    
    UIBarButtonItem * addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction:)];
    UIBarButtonItem * clearItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(clearAction:)];
    UIBarButtonItem * randomItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(randomAction:)];
    self.navigationItem.rightBarButtonItems = @[addItem, clearItem, randomItem];
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

#pragma mark MLReorderableCollectionDelegate

- (void)collectionView:(UICollectionView *)collectionView willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)collectionView:(UICollectionView *)collectionView didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)collectionView:(UICollectionView *)collectionView willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)collectionView:(UICollectionView *)collectionView didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark MLReorderableCollectionDataSource

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath {
    [self.resultsController moveObjectAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
    return YES;
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
