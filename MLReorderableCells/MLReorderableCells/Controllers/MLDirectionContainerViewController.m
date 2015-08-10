//
//  MLDirectionContainerViewController.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 30.06.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLDirectionContainerViewController.h"
#import "MLDirectionCollectionViewController.h"
#import "MLReorderableCollectionController.h"

#pragma mark - MLDirectionContainerViewController

@interface MLDirectionContainerViewController () <MLReorderableCollectionControllerDelegate, MLReorderableCollectionControllerDataSource>

@property (nonatomic, readwrite, strong) MLDirectionCollectionViewController * verticalCollectionViewController;
@property (nonatomic, readwrite, strong) MLDirectionCollectionViewController * horizontalCollectionViewController;
@property (nonatomic, readwrite, strong) MLReorderableCollectionController * reorderableController;
@property (nonatomic, readwrite, strong) id cachedObject;

@end

#pragma mark -

@implementation MLDirectionContainerViewController

#pragma mark View

- (void)viewDidLoad {
    [super viewDidLoad];

    self.reorderableController = [[MLReorderableCollectionController alloc] initWithViewContainer:self.view];
    self.reorderableController.delegate = self;
    self.reorderableController.dataSource = self;
    [self.reorderableController addCollectionView:self.verticalCollectionViewController.collectionView];
    [self.reorderableController addCollectionView:self.horizontalCollectionViewController.collectionView];
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

#pragma mark MLReorderableCollectionControllerDelegate

- (void)collectionView:(UICollectionView *)collectionView didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    self.cachedObject = nil;
}

- (void)collectionView:(UICollectionView *)collectionView didBeginHoveringItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"-> begin: %@-%@", @(indexPath.section), @(indexPath.row));
}

- (void)collectionView:(UICollectionView *)collectionView didEndHoveringItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"<- end: %@-%@\n\n", @(indexPath.section), @(indexPath.row));
}

#pragma mark MLReorderableCollectionControllerDataSource
#pragma mark Reorder

- (BOOL)collectionView:(UICollectionView *)collectionView canReorderItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)canReorderContinouslyInCollectionView:(UICollectionView *)collectionView {
    return (collectionView == self.verticalCollectionViewController.collectionView);
}

- (NSIndexPath *)indexPathForNewItemInCollectionView:(UICollectionView *)collectionView {
    return [NSIndexPath indexPathForRow:0 inSection:0];
}

#pragma mark Insert

- (BOOL)collectionView:(UICollectionView *)collectionView canInsertItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didInsertItemAtIndexPath:(NSIndexPath *)indexPath {
    RZArrayCollectionList * resultsController = [self resultsControllerForCollectionView:collectionView];
    [resultsController insertObject:self.cachedObject atIndexPath:indexPath];
    self.cachedObject = nil;
    NSLog(@"-> insert object at index: %@", indexPath);
}

#pragma mark Delete

- (BOOL)collectionView:(UICollectionView *)collectionView canDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
    RZArrayCollectionList * resultsController = [self resultsControllerForCollectionView:collectionView];
    self.cachedObject = [resultsController objectAtIndexPath:indexPath];
    [resultsController removeObjectAtIndexPath:indexPath];
    NSLog(@"-> delete object at index: %@", indexPath);
}

#pragma mark Replace

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canReplaceWithIndexPath:(NSIndexPath *)toIndexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didReplaceWithIndexPath:(NSIndexPath *)toIndexPath {
    RZArrayCollectionList * resultsController = [self resultsControllerForCollectionView:collectionView];
    
    if ([fromIndexPath isEqual:toIndexPath]) { // replace items between collections
        id key = [self keyFromCollectionView:collectionView];
        id object = [self.cachedObject objectForKey:key];
        [resultsController replaceObjectAtIndexPath:toIndexPath withObject:object];
    }
    else { // replace items in collection
        id fromObject = [resultsController objectAtIndexPath:fromIndexPath];
        id toObject = [resultsController objectAtIndexPath:toIndexPath];
        
        [resultsController replaceObjectAtIndexPath:toIndexPath withObject:fromObject];
        [resultsController replaceObjectAtIndexPath:fromIndexPath withObject:toObject];
        NSLog(@"-> replace object at index: %@ with index: %@", fromIndexPath, toIndexPath);
    }
}

#pragma mark Move

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath {
    RZArrayCollectionList * resultsController = [self resultsControllerForCollectionView:collectionView];
    [resultsController moveObjectAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

#pragma mark Transfer Between Collections

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath canTransferToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    return NO;
}

#pragma mark Copy Between Collections

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath canCopyToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath willCopyToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    RZArrayCollectionList * resultsController = [self resultsControllerForCollectionView:collectionView];
    self.cachedObject = [[resultsController objectAtIndexPath:indexPath] copy];
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath didCopyToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    self.cachedObject = nil;
}

#pragma mark Replace Between Collections

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath canReplaceWithCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath willReplaceWithCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    RZArrayCollectionList * fromResultsController = [self resultsControllerForCollectionView:collectionView];
    RZArrayCollectionList * toResultsController = [self resultsControllerForCollectionView:toCollectionView];
    
    id fromObject = [fromResultsController objectAtIndexPath:indexPath];
    id toObject = [toResultsController objectAtIndexPath:toIndexPath];
    
    id fromKey = [self keyFromCollectionView:collectionView];
    id toKey = [self keyFromCollectionView:toCollectionView];
    
    self.cachedObject = @{fromKey   : toObject,
                          toKey     : fromObject};
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath didReplaceWithCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    self.cachedObject = nil;
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

- (NSString *)keyFromCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    return [NSString stringWithFormat:@"%p", collectionView];
}

@end
