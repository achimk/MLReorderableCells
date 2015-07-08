//
//  MLDirectionContainerViewController.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 30.06.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLDirectionContainerViewController.h"
#import "MLDirectionCollectionViewController.h"
#import "MLReorderableCollections.h"

#pragma mark - MLDirectionContainerViewController

@interface MLDirectionContainerViewController () <MLReorderableCollectionDelegate, MLReorderableCollectionDataSource>

@property (nonatomic, readwrite, strong) MLDirectionCollectionViewController * verticalCollectionViewController;
@property (nonatomic, readwrite, strong) MLDirectionCollectionViewController * horizontalCollectionViewController;
@property (nonatomic, readwrite, strong) MLReorderableCollections * reorderableCollections;
@property (nonatomic, readwrite, strong) id cachedObject;

@end

#pragma mark -

@implementation MLDirectionContainerViewController

#pragma mark View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.reorderableCollections = [[MLReorderableCollections alloc] initWithContainerView:self.view];
    
    MLReorderableCollection * reorderableCollection = nil;
    reorderableCollection = [self.reorderableCollections addCollectionView:self.verticalCollectionViewController.collectionView];
    reorderableCollection.delegate = self;
    reorderableCollection.dataSource = self;
    
    reorderableCollection = [self.reorderableCollections addCollectionView:self.horizontalCollectionViewController.collectionView];
    reorderableCollection.delegate = self;
    reorderableCollection.dataSource = self;
}

#pragma mark Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
   
    if ([segue.identifier isEqualToString:@"VerticalCollectionViewController"]) {
        self.verticalCollectionViewController = segue.destinationViewController;
    }
    else if ([segue.identifier isEqualToString:@"HorizontalCollectionViewController"]) {
        self.horizontalCollectionViewController = segue.destinationViewController;
    }
}

#pragma mark MLReorderableCollectionDelegate

- (void)collectionView:(UICollectionView *)collectionView willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"-> %@: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (void)collectionView:(UICollectionView *)collectionView didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"-> %@: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (void)collectionView:(UICollectionView *)collectionView willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"-> %@: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

- (void)collectionView:(UICollectionView *)collectionView didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"-> %@: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    self.cachedObject = nil;
}

#pragma mark - MLReorderableCollectionDataSource

#pragma mark Reorder

- (BOOL)collectionView:(UICollectionView *)collectionView canReorderItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UIView *)reorderableCollectionContainerForCollectionView:(UICollectionView *)collectionView {
    return self.splitViewController.view;
}

- (NSIndexPath *)indexPathForNewItemInCollectionView:(UICollectionView *)collectionView {
    RZArrayCollectionList * resultsController = [self resultsControllerForCollectionView:collectionView];
    return (0 == resultsController.listObjects.count) ? [NSIndexPath indexPathForRow:0 inSection:0] : nil;
}

#pragma mark Insert

- (BOOL)collectionView:(UICollectionView *)collectionView canInsertItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"-> can insert: %@", [self nameForCollectionView:collectionView]);
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView willInsertItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)collectionView:(UICollectionView *)collectionView didInsertItemAtIndexPath:(NSIndexPath *)indexPath {
    RZArrayCollectionList * resultsController = [self resultsControllerForCollectionView:collectionView];
    [resultsController insertObject:self.cachedObject atIndexPath:indexPath];
    self.cachedObject = nil;
}

#pragma mark Delete

- (BOOL)collectionView:(UICollectionView *)collectionView canDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"-> can delete: %@", [self nameForCollectionView:collectionView]);
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView willDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)collectionView:(UICollectionView *)collectionView didDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
    RZArrayCollectionList * resultsController = [self resultsControllerForCollectionView:collectionView];
    self.cachedObject = [resultsController objectAtIndexPath:indexPath];
    [resultsController removeObjectAtIndexPath:indexPath];
}

#pragma mark Replace

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canReplaceWithIndexPath:(NSIndexPath *)toIndexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willReplaceWithIndexPath:(NSIndexPath *)toIndexPath {
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didReplaceWithIndexPath:(NSIndexPath *)toIndexPath {
    RZArrayCollectionList * resultsController = [self resultsControllerForCollectionView:collectionView];
    id fromObject = [resultsController objectAtIndexPath:fromIndexPath];
    id toObject = [resultsController objectAtIndexPath:toIndexPath];
    
    [resultsController replaceObjectAtIndexPath:toIndexPath withObject:fromObject];
    [resultsController replaceObjectAtIndexPath:fromIndexPath withObject:toObject];
}

#pragma mark Move

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath {
    RZArrayCollectionList * resultsController = [self resultsControllerForCollectionView:collectionView];
    [resultsController moveObjectAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

#pragma mark Private Methods

- (RZArrayCollectionList *)resultsControllerForCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    
    if ([collectionView isEqual:self.verticalCollectionViewController.collectionView]) {
        return self.verticalCollectionViewController.resultsController;
    }
    else if ([collectionView isEqual:self.horizontalCollectionViewController.collectionView]) {
        return self.horizontalCollectionViewController.resultsController;
    }
    
    return nil;
}

- (NSString *)nameForCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    
    if ([collectionView isEqual:self.verticalCollectionViewController.collectionView]) {
        return @"vertical";
    }
    else if ([collectionView isEqual:self.horizontalCollectionViewController.collectionView]) {
        return @"horizontal";
    }
    
    return nil;
}

@end
