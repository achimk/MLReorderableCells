//
//  MLColorsCollectionViewController.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 30.06.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLColorsCollectionViewController.h"
#import "MLColorCollectionViewCell.h"

#define NUMBER_OF_INITIAL_ITEMS     9

#pragma mark - MLColorsCollectionViewController

@interface MLColorsCollectionViewController ()

@property (nonatomic, readwrite, strong) RZArrayCollectionList * resultsController;

@end

#pragma mark -

@implementation MLColorsCollectionViewController

@dynamic verticalLayout, horizontalLayout;

#pragma mark View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.resultsController = [[RZArrayCollectionList alloc] initWithArray:@[] sectionNameKeyPath:nil];
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [MLColorCollectionViewCell registerCellWithCollectionView:self.collectionView];
}

#pragma mark Accessors

- (BOOL)isVerticalLayout {
    if (![self.collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        return NO;
    }
    
    UICollectionViewFlowLayout * flowLayout = (id)self.collectionViewLayout;
    return (UICollectionViewScrollDirectionVertical == flowLayout.scrollDirection);
}

- (BOOL)isHorizontalLayout {
    if (![self.collectionViewLayout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        return NO;
    }
    
    UICollectionViewFlowLayout * flowLayout = (id)self.collectionViewLayout;
    return (UICollectionViewScrollDirectionHorizontal == flowLayout.scrollDirection);
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
    NSUInteger numberOfItems = NUMBER_OF_INITIAL_ITEMS;
    
    if ([sender isKindOfClass:[NSNumber class]]) {
        numberOfItems = [sender unsignedIntegerValue];
    }
    
    [self.resultsController removeAllObjects];
    
    for (NSUInteger i = 0; i < numberOfItems; i++) {
        MLColorModel * model = [MLColorModel model];
        [self.resultsController addObject:model toSection:0];
    }
    
    [self reloadData];
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"-> %@: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
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
