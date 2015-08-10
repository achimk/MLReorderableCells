//
//  MLReorderableCollectionController.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 08.07.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLReorderableCollectionController.h"
#import "MLReorderableCollectionAnimator.h"

#pragma mark - MLReorderableCollectionController (Delegate)

@interface MLReorderableCollectionController (Delegate)

// Dragging delegates
- (void)collectionView:(UICollectionView *)collectionView willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

// Hover item delegate
- (void)collectionView:(UICollectionView *)collectionView didBeginHoveringItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView didEndHoveringItemAtIndexPath:(NSIndexPath *)indexPath;

@end

#pragma mark - MLReorderableCollectionController (DataSource)

@interface MLReorderableCollectionController (DataSource)

// Reorder data source
- (BOOL)collectionView:(UICollectionView *)collectionView canReorderItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForNewItemInCollectionView:(UICollectionView *)collectionView;

// Insert data source
- (BOOL)collectionView:(UICollectionView *)collectionView canInsertItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView willInsertItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView didInsertItemAtIndexPath:(NSIndexPath *)indexPath;

// Delete data source
- (BOOL)collectionView:(UICollectionView *)collectionView canDeleteItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView willDeleteItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView didDeleteItemAtIndexPath:(NSIndexPath *)indexPath;

// Replace data source
- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canReplaceWithIndexPath:(NSIndexPath *)toIndexPath;
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willReplaceWithIndexPath:(NSIndexPath *)toIndexPath;
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didReplaceWithIndexPath:(NSIndexPath *)toIndexPath;

// Move data source
- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath;
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath;
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath;

// Transfer data source
- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath canTransferToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath;
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath willTransferToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath;
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath didTransferToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath;

// Copy data source
- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath canCopyToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath;
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath willCopyToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath;
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath didCopyToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath;

// Replace data source
- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath canReplaceWithCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath;
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath willReplaceWithCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath;
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath didReplaceWithCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath;


@end

#pragma mark - MLReorderableCollectionController

@interface MLReorderableCollectionController ()

@property (nonatomic, readonly, strong) NSMutableArray * arrayOfCollectionViews;
@property (nonatomic, readwrite, assign, getter=isDragging) BOOL dragging;
@property (nonatomic, readwrite, assign, getter=isInsideBounds) BOOL insideBounds;
@property (nonatomic, readwrite, assign, getter=isItemCopied) BOOL itemCopied;
@property (nonatomic, readwrite, assign) CGPoint centerPointPlaceholder;
@property (nonatomic, readwrite, strong) UIView * viewPlaceholder;

@property (nonatomic, readwrite, copy) NSIndexPath * currentIndexPath;
@property (nonatomic, readwrite, strong) UICollectionView * currentCollectionView;

@property (nonatomic, readwrite, copy) NSIndexPath * hoverIndexPath;
@property (nonatomic, readwrite, strong) UICollectionView * hoverCollectionView;

@property (nonatomic, readwrite, copy) NSIndexPath * lastIndexPath;
@property (nonatomic, readwrite, strong) UICollectionView * lastCollectionView;

@end

#pragma mark -

@implementation MLReorderableCollectionController

@synthesize animator = _animator;

#pragma mark Init

- (instancetype)initWithViewContainer:(UIView *)viewContainer {
    NSParameterAssert(viewContainer);
    
    if (self = [super init]) {
        _shouldReorderContinously = YES;
        _viewContainer = viewContainer;
        _arrayOfCollectionViews = [[NSMutableArray alloc] init];
        
        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        _longPressGesture.delegate = self;
        [viewContainer addGestureRecognizer:_longPressGesture];
        
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        _panGesture.delegate = self;
        [viewContainer addGestureRecognizer:_panGesture];
        
        if ([viewContainer isKindOfClass:[UICollectionView class]]) {
            UICollectionView * collectionView = (UICollectionView *)viewContainer;
            
            if ([collectionView.delegate conformsToProtocol:@protocol(MLReorderableCollectionControllerDelegate)]) {
                id delegate = collectionView.delegate;
                __weak typeof(delegate)weakDelegate = delegate;
                _delegate = weakDelegate;
            }
            
            if ([collectionView.dataSource conformsToProtocol:@protocol(MLReorderableCollectionControllerDataSource)]) {
                id dataSource = collectionView.dataSource;
                __weak typeof(dataSource)weakDataSource = dataSource;
                _dataSource = weakDataSource;
            }
            
            [self addCollectionView:collectionView];
        }
    }
    
    return self;
}

- (void)dealloc {
    _longPressGesture.delegate = nil;
    _panGesture.delegate = nil;
}

#pragma mark Accessors

- (void)allowsScrollToTop:(BOOL)flag {
    [self.arrayOfCollectionViews enumerateObjectsUsingBlock:^(UICollectionView * collectionView, NSUInteger idx, BOOL *stop) {
        collectionView.scrollsToTop = flag;
    }];
}

- (BOOL)isVerticalScrollAllowedForCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    UICollectionViewLayout * layout = collectionView.collectionViewLayout;
    if ([layout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        UICollectionViewFlowLayout * flowLayout = (UICollectionViewFlowLayout *)layout;
        return (UICollectionViewScrollDirectionVertical == flowLayout.scrollDirection);
    }
    
    return NO;
}

- (BOOL)isHorizontalScrollAllowedForCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    UICollectionViewLayout * layout = collectionView.collectionViewLayout;
    if ([layout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        UICollectionViewFlowLayout * flowLayout = (UICollectionViewFlowLayout *)layout;
        return (UICollectionViewScrollDirectionHorizontal == flowLayout.scrollDirection);
    }
    
    return NO;
}

- (void)setAnimator:(id<MLReorderableCollectionControllerAnimator>)animator {
    if (animator != _animator) {
        _animator = animator;
    }
}

- (id<MLReorderableCollectionControllerAnimator>)animator {
    if (!_animator) {
        _animator = [MLReorderableCollectionAnimator animator];
    }
    return _animator;
}

- (void)updateLastCollectionView:(UICollectionView *)collectionView withItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView) {
        self.lastIndexPath = (indexPath) ?: self.lastIndexPath;
        self.lastCollectionView = collectionView;
    }
}

- (void)updateHoveringItemInCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath {
    if (![collectionView isEqual:self.hoverCollectionView] || ![indexPath isEqual:self.hoverIndexPath]) {
        if (self.hoverCollectionView && self.hoverIndexPath) {
            [self collectionView:self.hoverCollectionView didEndHoveringItemAtIndexPath:self.hoverIndexPath];
        }
        
        self.hoverIndexPath = indexPath;
        self.hoverCollectionView = collectionView;
        
        if (collectionView && indexPath) {
            [self collectionView:collectionView didBeginHoveringItemAtIndexPath:indexPath];
        }
    }
    
}

#pragma mark Manage Collection Views

- (NSUInteger)indexOfCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    
    __block NSUInteger index = NSNotFound;
    [self.arrayOfCollectionViews enumerateObjectsUsingBlock:^(UICollectionView * obj, NSUInteger idx, BOOL *stop) {
        if (collectionView == obj) {
            index = idx;
            *stop = YES;
        }
    }];
    
    return index;
}

- (BOOL)hasCollectionView:(UICollectionView *)collectionView {
    return (NSNotFound != [self indexOfCollectionView:collectionView]);
}

- (BOOL)addCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    BOOL hasCollectionView = [self hasCollectionView:collectionView];
    BOOL containsCollectionView = [self containsCollectionView:collectionView];
    if (!hasCollectionView && containsCollectionView) {
        [self.arrayOfCollectionViews addObject:collectionView];
        
        for (UIGestureRecognizer * gestureRecognizer in collectionView.gestureRecognizers) {
            if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
                [gestureRecognizer requireGestureRecognizerToFail:self.longPressGesture];
            }
        }
    }
    
    return !hasCollectionView && containsCollectionView;
}

- (BOOL)removeCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    BOOL hasCollectionView = [self hasCollectionView:collectionView];
    if (hasCollectionView) {
        [self.arrayOfCollectionViews removeObject:collectionView];
    }
    
    return hasCollectionView;
}

#pragma mark Gesture Callbacks

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            UICollectionView * collectionView = [self collectionViewForGesture:gestureRecognizer];
            if (!collectionView) {
                return;
            }
            
            CGPoint point = [gestureRecognizer locationInView:collectionView];
            NSIndexPath * indexPath = [collectionView indexPathForItemAtPoint:point];
            if (!indexPath) {
                return;
            }
            
            if (![self collectionView:collectionView canReorderItemAtIndexPath:indexPath]) {
                return;
            }
            
            self.dragging = YES;
            self.insideBounds = YES;
            [self allowsScrollToTop:NO];
            self.currentIndexPath = indexPath;
            self.currentCollectionView = collectionView;
            
            UICollectionViewCell * cell = [collectionView cellForItemAtIndexPath:indexPath];
            UIView * viewPlaceholder = [self viewPlaceholderFromCollectionViewCell:cell];
            viewPlaceholder.frame = [cell convertRect:cell.bounds toView:self.viewContainer];
            [self.viewContainer addSubview:viewPlaceholder];
            self.viewPlaceholder = viewPlaceholder;
            self.centerPointPlaceholder = viewPlaceholder.center;
            
            [self updateLastCollectionView:collectionView withItemAtIndexPath:indexPath];
            [self collectionView:collectionView willBeginDraggingItemAtIndexPath:indexPath];
            
            [self animateLongPressBeginForCollectionView:collectionView
                                               indexPath:indexPath
                                             placeholder:viewPlaceholder
                                              completion:nil];
            
            [self collectionView:collectionView didBeginDraggingItemAtIndexPath:indexPath];
            [self updateHoveringItemInCollectionView:collectionView atIndexPath:indexPath];
            
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (!self.isDragging) {
                return;
            }
            
            BOOL shouldReorderContinously = self.shouldReorderContinously;
            if (self.lastCollectionView && [self.dataSource respondsToSelector:@selector(canReorderContinouslyInCollectionView:)]) {
                shouldReorderContinously = [self.dataSource canReorderContinouslyInCollectionView:self.lastCollectionView];
            }
            
            if (!shouldReorderContinously) {
                [self performUpdatesForCollectionView:self.hoverCollectionView];
            }
            
            NSIndexPath * indexPath = self.currentIndexPath;
            UICollectionView * collectionView = self.currentCollectionView;
            UIView * viewPlaceholder = self.viewPlaceholder;
            
            [self updateHoveringItemInCollectionView:collectionView atIndexPath:nil];
            [self collectionView:collectionView willEndDraggingItemAtIndexPath:indexPath];
            
            self.dragging = NO;
            self.insideBounds = NO;
            self.itemCopied = NO;
            [self allowsScrollToTop:YES];
            self.centerPointPlaceholder = CGPointZero;
            self.viewPlaceholder = nil;
            self.lastIndexPath = nil;
            self.lastCollectionView = nil;
            self.hoverIndexPath = nil;
            self.hoverCollectionView = nil;
            self.currentIndexPath = nil;
            self.currentCollectionView = nil;
            
            __weak typeof(self)weakSelf = self;
            void (^completion)(BOOL) = ^(BOOL finished) {
                [viewPlaceholder removeFromSuperview];
                [collectionView.collectionViewLayout invalidateLayout];
                
                if (finished) {
                    [weakSelf collectionView:collectionView didEndDraggingItemAtIndexPath:indexPath];
                }
            };

            [self animateLongPressEndForCollectionView:collectionView
                                             indexPath:indexPath
                                           placeholder:viewPlaceholder
                                            completion:completion];
        } break;
        default: break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    if (!self.isDragging) {
        return;
    }
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateChanged: {
            NSIndexPath * indexPath = nil;
            UICollectionView * collectionView = [self collectionViewForGesture:gestureRecognizer];

            UIView * translationView = self.viewContainer;
            UIView * viewPlaceholder = self.viewPlaceholder;
            CGPoint centerPoint = self.centerPointPlaceholder;
            CGPoint translationPoint = [gestureRecognizer translationInView:translationView];
            CGPoint center = CGPointMake(centerPoint.x + translationPoint.x, centerPoint.y + translationPoint.y);
            viewPlaceholder.center = center;
            
            if (collectionView) {
                indexPath = [self indexPathFromGesture:gestureRecognizer inCollectionView:collectionView];
            }

            [self updateLastCollectionView:collectionView withItemAtIndexPath:indexPath];
            [self updateHoveringItemInCollectionView:collectionView atIndexPath:indexPath];
            
            BOOL shouldReorderContinously = self.shouldReorderContinously;
            if (self.lastCollectionView && [self.dataSource respondsToSelector:@selector(canReorderContinouslyInCollectionView:)]) {
                shouldReorderContinously = [self.dataSource canReorderContinouslyInCollectionView:self.lastCollectionView];
            }

            if (shouldReorderContinously) {
                [self performUpdatesForCollectionView:collectionView];
            }
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
        } break;
        default: break;
    }
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.panGesture isEqual:gestureRecognizer]) {
        UICollectionView * collectionView = [self collectionViewForGesture:gestureRecognizer];
        NSParameterAssert(collectionView);
        
        if (UIGestureRecognizerStatePossible == self.longPressGesture.state ||
            UIGestureRecognizerStateFailed == self.longPressGesture.state) {
            return NO;
        }
    }
    else if ([self.longPressGesture isEqual:gestureRecognizer]) {
        UICollectionView * collectionView = [self collectionViewForGesture:gestureRecognizer];
        NSParameterAssert(collectionView);
        
        if (UIGestureRecognizerStatePossible != collectionView.panGestureRecognizer.state &&
            UIGestureRecognizerStateFailed != collectionView.panGestureRecognizer.state) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([self.panGesture isEqual:gestureRecognizer]) {
        if (UIGestureRecognizerStatePossible != self.longPressGesture.state &&
            UIGestureRecognizerStateFailed != self.longPressGesture.state) {
            return [self.longPressGesture isEqual:otherGestureRecognizer];
        }
    }
    else if ([self.longPressGesture isEqual:gestureRecognizer]) {
        return [self.panGesture isEqual:otherGestureRecognizer];
    }
    else if ([gestureRecognizer.view isKindOfClass:[UICollectionView class]]) {
        UICollectionView * collectionView = (UICollectionView *)gestureRecognizer.view;
        
        if ([collectionView.panGestureRecognizer isEqual:gestureRecognizer]) {
            if (UIGestureRecognizerStatePossible == self.longPressGesture.state ||
                UIGestureRecognizerStateFailed == self.longPressGesture.state) {
                return NO;
            }
        }
    }

    return YES;
}

#pragma mark Operations

- (void)performUpdatesForCollectionView:(UICollectionView *)collectionView {
    BOOL shouldUpdateInsideBounds = NO;
    BOOL shouldUpdateCurrentCollectionView = NO;
    BOOL isGestureInsideBounds = (nil != collectionView);
    BOOL hasChangedBounds = (isGestureInsideBounds != self.isInsideBounds);
    BOOL isChangingCollectionView = (isGestureInsideBounds && self.currentCollectionView != collectionView);
    
    if (isChangingCollectionView) {
        BOOL isItemDeleted = (nil == self.currentIndexPath);
        
        if (isItemDeleted) {
            shouldUpdateInsideBounds = shouldUpdateCurrentCollectionView = [self insertItemToCollectionView:collectionView];
        }
        else {
            UICollectionView * fromCollectionView = self.currentCollectionView;
            [self transferOrCopyOrReplaceFromCollectionView:fromCollectionView toCollectionView:collectionView];
        }
    }
    else if (isGestureInsideBounds && hasChangedBounds) {
        shouldUpdateInsideBounds = [self insertItemToCollectionView:collectionView];
    }
    else if (!isGestureInsideBounds && hasChangedBounds){
        shouldUpdateInsideBounds = [self deleteItemFromCollectionView:self.currentCollectionView];
    }
    else if (isGestureInsideBounds) {
        [self replaceOrMoveItemInCollectionView:collectionView];
    }
    
    if (shouldUpdateInsideBounds) {
        self.insideBounds = isGestureInsideBounds;
    }
    
    if (shouldUpdateCurrentCollectionView) {
        self.currentCollectionView = collectionView;
    }
}

- (BOOL)insertItemToCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    NSIndexPath * indexPath = [self indexPathForNewItemInCollectionView:collectionView];
    NSParameterAssert(indexPath);
    
    if (![self collectionView:collectionView canInsertItemAtIndexPath:indexPath]) {
        return NO;
    }
    
    BOOL hasCollectionViewChanged = (self.currentCollectionView != collectionView);
    UICollectionView * fromCollectionView = self.currentCollectionView;
    NSIndexPath * fromIndexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:NSNotFound];
    UICollectionView * toCollectionView = collectionView;
    NSIndexPath * toIndexPath = indexPath;
    
    [self collectionView:collectionView willInsertItemAtIndexPath:indexPath];
    [collectionView performBatchUpdates:^{
        self.currentIndexPath = indexPath;
        [collectionView insertItemsAtIndexPaths:@[indexPath]];
        [self collectionView:collectionView didInsertItemAtIndexPath:indexPath];
    } completion:^(BOOL finished) {
        UIView * viewPlaceholder = self.viewPlaceholder;
        if (finished && hasCollectionViewChanged && viewPlaceholder) {
            [self animateFromCollectionView:fromCollectionView
                            itemAtIndexPath:fromIndexPath
                           toCollectionView:toCollectionView
                                  indexPath:toIndexPath
                                placeholder:viewPlaceholder
                                 completion:nil];
        }
    }];
    
    return YES;
}

- (BOOL)deleteItemFromCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    NSIndexPath * indexPath = self.currentIndexPath;
    if (!indexPath) {
        return NO;
    }
    
    if (![self collectionView:collectionView canDeleteItemAtIndexPath:indexPath]) {
        return NO;
    }
    
    [self collectionView:collectionView willDeleteItemAtIndexPath:indexPath];
    [collectionView performBatchUpdates:^{
        self.currentIndexPath = nil;
        [collectionView deleteItemsAtIndexPaths:@[indexPath]];
        [self collectionView:collectionView didDeleteItemAtIndexPath:indexPath];
    } completion:nil];
    
    return YES;
}

- (BOOL)replaceOrMoveItemInCollectionView:(UICollectionView *)collectionView {
    if (![self replaceItemInCollectionView:collectionView]) {
        if (![self moveItemInCollectionView:collectionView]) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)replaceItemInCollectionView:(UICollectionView *)collectionView {
    NSAssert(self.viewPlaceholder, @"View placeholder should be set when replacing item in collection view!");
    NSParameterAssert(collectionView);
    NSIndexPath * fromIndexPath = self.currentIndexPath;
    NSIndexPath * toIndexPath = self.hoverIndexPath;
    
    if (!fromIndexPath || !toIndexPath || [fromIndexPath isEqual:toIndexPath]) {
        return NO;
    }
    
    if (![self collectionView:collectionView itemAtIndexPath:fromIndexPath canReplaceWithIndexPath:toIndexPath]) {
        return NO;
    }
    
    [self collectionView:collectionView itemAtIndexPath:fromIndexPath willReplaceWithIndexPath:toIndexPath];
    [collectionView performBatchUpdates:^{
        self.currentIndexPath = toIndexPath;
        [collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
        [collectionView moveItemAtIndexPath:toIndexPath toIndexPath:fromIndexPath];
        [self collectionView:collectionView itemAtIndexPath:fromIndexPath didReplaceWithIndexPath:toIndexPath];
    } completion:nil];
    
    return YES;
}

- (BOOL)moveItemInCollectionView:(UICollectionView *)collectionView {
    NSAssert(self.viewPlaceholder, @"View placeholder should be set when moving item in collection view!");
    NSParameterAssert(collectionView);
    CGPoint point = [self.viewContainer convertPoint:self.viewPlaceholder.center toView:collectionView];
    NSIndexPath * fromIndexPath = self.currentIndexPath;
    NSIndexPath * toIndexPath = [collectionView indexPathForItemAtPoint:point];
    
    if (!fromIndexPath || !toIndexPath || [fromIndexPath isEqual:toIndexPath]) {
        return NO;
    }
    
    if (![self collectionView:collectionView itemAtIndexPath:fromIndexPath canMoveToIndexPath:toIndexPath]) {
        return NO;
    }
    
    [self collectionView:collectionView itemAtIndexPath:fromIndexPath willMoveToIndexPath:toIndexPath];
    [collectionView performBatchUpdates:^{
        self.currentIndexPath = toIndexPath;
        [collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
        [self collectionView:collectionView itemAtIndexPath:fromIndexPath didMoveToIndexPath:toIndexPath];
    } completion:nil];
    
    return YES;
}

- (BOOL)transferOrCopyOrReplaceFromCollectionView:(UICollectionView *)fromCollectionView toCollectionView:(UICollectionView *)toCollectionView {
    if (![self transferItemFromCollectionView:fromCollectionView toCollectionView:toCollectionView]) {
        if (![self copyItemFromCollectionView:fromCollectionView toCollectionView:toCollectionView]) {
            if (![self replaceItemFromCollectionView:fromCollectionView withCollectionView:toCollectionView]) {
                return NO;
            }
        }
    }
    
    return YES;
}

- (BOOL)transferItemFromCollectionView:(UICollectionView *)fromCollectionView toCollectionView:(UICollectionView *)toCollectionView {
    NSParameterAssert(fromCollectionView);
    NSParameterAssert(toCollectionView);
    NSIndexPath * fromIndexPath = self.currentIndexPath;
    if (!fromIndexPath) {
        return NO;
    }
    
    NSIndexPath * toIndexPath = [self indexPathForNewItemInCollectionView:toCollectionView];
    NSParameterAssert(toIndexPath);
    
    if (![self collectionView:fromCollectionView itemAtIndexPath:fromIndexPath canTransferToCollectionView:toCollectionView indexPath:toIndexPath]) {
        return NO;
    }
    
    [self collectionView:fromCollectionView itemAtIndexPath:fromIndexPath willTransferToCollectionView:toCollectionView indexPath:toIndexPath];
    [self collectionView:fromCollectionView willDeleteItemAtIndexPath:fromIndexPath];
    
    [fromCollectionView performBatchUpdates:^{
        [fromCollectionView deleteItemsAtIndexPaths:@[fromIndexPath]];
        [self collectionView:fromCollectionView didDeleteItemAtIndexPath:fromIndexPath];
    } completion:nil];
    
    [self collectionView:toCollectionView willInsertItemAtIndexPath:toIndexPath];
    
    [toCollectionView performBatchUpdates:^{
        self.currentIndexPath = toIndexPath;
        self.currentCollectionView = toCollectionView;
        [toCollectionView insertItemsAtIndexPaths:@[toIndexPath]];
        [self collectionView:toCollectionView didInsertItemAtIndexPath:toIndexPath];
        [self collectionView:fromCollectionView itemAtIndexPath:fromIndexPath didTransferToCollectionView:toCollectionView indexPath:toIndexPath];
    } completion:^(BOOL finished) {
        UIView * viewPlaceholder = self.viewPlaceholder;
        if (finished && viewPlaceholder) {
            [self animateFromCollectionView:fromCollectionView
                            itemAtIndexPath:fromIndexPath
                           toCollectionView:toCollectionView
                                  indexPath:toIndexPath
                                placeholder:viewPlaceholder
                                 completion:nil];
        }
    }];
    
    return YES;
}

- (BOOL)copyItemFromCollectionView:(UICollectionView *)fromCollectionView toCollectionView:(UICollectionView *)toCollectionView {
    NSParameterAssert(fromCollectionView);
    NSParameterAssert(toCollectionView);
    if (self.isItemCopied) {
        return NO;
    }
    
    NSIndexPath * fromIndexPath = self.currentIndexPath;
    if (!fromIndexPath) {
        return NO;
    }
    
    NSIndexPath * toIndexPath = [self indexPathForNewItemInCollectionView:toCollectionView];
    NSParameterAssert(toIndexPath);
    
    if (![self collectionView:fromCollectionView itemAtIndexPath:fromIndexPath canCopyToCollectionView:toCollectionView indexPath:toIndexPath]) {
        return NO;
    }
    
    [self collectionView:fromCollectionView itemAtIndexPath:fromIndexPath willCopyToCollectionView:toCollectionView indexPath:toIndexPath];
    [self collectionView:toCollectionView willInsertItemAtIndexPath:toIndexPath];
    
    [toCollectionView performBatchUpdates:^{
        self.itemCopied = YES;
        self.currentIndexPath = toIndexPath;
        self.currentCollectionView = toCollectionView;
        [toCollectionView insertItemsAtIndexPaths:@[toIndexPath]];
        [self collectionView:toCollectionView didInsertItemAtIndexPath:toIndexPath];
        [self collectionView:fromCollectionView itemAtIndexPath:fromIndexPath didCopyToCollectionView:toCollectionView indexPath:toIndexPath];
    } completion:^(BOOL finished) {
        UIView * viewPlaceholder = self.viewPlaceholder;
        if (finished && viewPlaceholder) {
            [self animateFromCollectionView:fromCollectionView
                            itemAtIndexPath:fromIndexPath
                           toCollectionView:toCollectionView
                                  indexPath:toIndexPath
                                placeholder:viewPlaceholder
                                 completion:nil];
        }
    }];
    
    return YES;
}

- (BOOL)replaceItemFromCollectionView:(UICollectionView *)fromCollectionView withCollectionView:(UICollectionView *)toCollectionView {
    NSParameterAssert(fromCollectionView);
    NSParameterAssert(toCollectionView);
    NSIndexPath * fromIndexPath = self.currentIndexPath;
    if (!fromIndexPath) {
        return NO;
    }
    
    NSIndexPath * toIndexPath = self.hoverIndexPath;
    if (!toIndexPath) {
        return NO;
    }

    if (![self collectionView:fromCollectionView itemAtIndexPath:fromIndexPath canReplaceWithCollectionView:toCollectionView indexPath:toIndexPath]) {
        return NO;
    }
    
    [self collectionView:fromCollectionView itemAtIndexPath:fromIndexPath willReplaceWithCollectionView:toCollectionView indexPath:toIndexPath];
    [self collectionView:fromCollectionView itemAtIndexPath:fromIndexPath willReplaceWithIndexPath:fromIndexPath];
    
    [fromCollectionView performBatchUpdates:^{
        [fromCollectionView reloadItemsAtIndexPaths:@[fromIndexPath]];
        [self collectionView:fromCollectionView itemAtIndexPath:fromIndexPath didReplaceWithIndexPath:fromIndexPath];
    } completion:nil];
    
    [self collectionView:toCollectionView itemAtIndexPath:toIndexPath willReplaceWithIndexPath:toIndexPath];
    
    [toCollectionView performBatchUpdates:^{
        self.currentIndexPath = toIndexPath;
        self.currentCollectionView = toCollectionView;
        [toCollectionView reloadItemsAtIndexPaths:@[toIndexPath]];
        [self collectionView:toCollectionView itemAtIndexPath:toIndexPath didReplaceWithIndexPath:toIndexPath];
        [self collectionView:fromCollectionView itemAtIndexPath:fromIndexPath didReplaceWithCollectionView:toCollectionView indexPath:toIndexPath];
    } completion:^(BOOL finished) {
        UIView * viewPlaceholder = self.viewPlaceholder;
        if (finished && viewPlaceholder) {
            [self animateFromCollectionView:fromCollectionView
                            itemAtIndexPath:fromIndexPath
                           toCollectionView:toCollectionView
                                  indexPath:toIndexPath
                                placeholder:viewPlaceholder
                                 completion:nil];
        }
    }];
    
    return YES;
}

#pragma mark Animations

- (void)animateLongPressBeginForCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath placeholder:(UIView *)viewPlaceholder completion:(void(^)(BOOL))completion {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    NSParameterAssert(viewPlaceholder);
    
    [self.animator collectionView:collectionView
   beginsAnimationItemAtIndexPath:indexPath
                 usingPlaceholder:viewPlaceholder
                       completion:completion];
}

- (void)animateLongPressEndForCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath placeholder:(UIView *)viewPlaceholder completion:(void(^)(BOOL))completion {
    NSParameterAssert(collectionView);
    NSParameterAssert(viewPlaceholder);
    
    [self.animator collectionView:collectionView
     endsAnimationItemAtIndexPath:indexPath
                 usingPlaceholder:viewPlaceholder
                       completion:completion];
}

- (void)animateFromCollectionView:(UICollectionView *)fromCollectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath toCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath placeholder:(UIView *)viewPlaceholder completion:(void(^)(BOOL))completion {
    NSParameterAssert(fromCollectionView);
    NSParameterAssert(fromIndexPath);
    NSParameterAssert(toCollectionView);
    NSParameterAssert(toIndexPath);
    NSParameterAssert(viewPlaceholder);
    
    toIndexPath = ([toCollectionView isEqual:self.lastCollectionView] && self.lastIndexPath) ? self.lastIndexPath : toIndexPath;
    [self.animator collectionView:fromCollectionView
                  itemAtIndexPath:fromIndexPath
         animatesToCollectionView:toCollectionView
                        indexPath:toIndexPath
                 usingPlaceholder:viewPlaceholder
                       completion:completion];
}

#pragma mark Private Methods

- (BOOL)containsCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    UIView * viewContainer = self.viewContainer;
    BOOL containsCollectionView = (collectionView == viewContainer);
    
    if (viewContainer && !containsCollectionView) {
        UIView * superview = collectionView;
        while (nil != superview) {
            if (viewContainer == superview) {
                containsCollectionView = YES;
                break;
            }
            
            superview = superview.superview;
        }
    }
    
    return containsCollectionView;
}

- (UICollectionView *)collectionViewForGesture:(UIGestureRecognizer *)gesture {
    NSParameterAssert(gesture);
    CGPoint touchPoint = [gesture locationInView:self.viewContainer];
    return [self collectionViewAtPoint:touchPoint];
}

- (UICollectionView *)collectionViewAtPoint:(CGPoint)point {
    __block UICollectionView * collectionView = nil;
    UIView * viewContainer = self.viewContainer;
    
    [self.arrayOfCollectionViews enumerateObjectsUsingBlock:^(UICollectionView * obj, NSUInteger idx, BOOL *stop) {
        CGRect visibleRect = CGRectZero;
        visibleRect.origin = obj.contentOffset;
        visibleRect.size = obj.frame.size;
        CGRect collectionViewRect = [obj convertRect:visibleRect toView:viewContainer];
        
        if (CGRectContainsPoint(collectionViewRect, point)) {
            collectionView = obj;
            *stop = YES;
        }
    }];
    
    return collectionView;
}

- (UIView *)viewPlaceholderFromCollectionViewCell:(UICollectionViewCell *)cell {
    NSParameterAssert(cell);
    UIView * viewPlaceholder = [self.animator viewPlaceholderFromCollectionViewCell:cell];
    NSAssert(viewPlaceholder, @"View placeholder cannot be nil!");
    return viewPlaceholder;
}

- (NSIndexPath *)indexPathFromGesture:(UIGestureRecognizer *)gesture inCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(gesture);
    NSParameterAssert(collectionView);
    CGPoint touchPoint = [gesture locationInView:self.viewContainer];
    CGPoint point = [self.viewContainer convertPoint:touchPoint toView:collectionView];
    NSIndexPath * indexPath = [collectionView indexPathForItemAtPoint:point];
    return indexPath;
}

@end

#pragma mark -

@implementation MLReorderableCollectionController (Delegate)

#pragma mark Delegate Dragging

- (void)collectionView:(UICollectionView *)collectionView willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    if ([self.delegate respondsToSelector:@selector(collectionView:willBeginDraggingItemAtIndexPath:)]) {
        [self.delegate collectionView:collectionView willBeginDraggingItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    if ([self.delegate respondsToSelector:@selector(collectionView:didBeginDraggingItemAtIndexPath:)]) {
        [self.delegate collectionView:collectionView didBeginDraggingItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(collectionView);
    if ([self.delegate respondsToSelector:@selector(collectionView:willEndDraggingItemAtIndexPath:)]) {
        [self.delegate collectionView:collectionView willEndDraggingItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(collectionView);
    if ([self.delegate respondsToSelector:@selector(collectionView:didEndDraggingItemAtIndexPath:)]) {
        [self.delegate collectionView:collectionView didEndDraggingItemAtIndexPath:indexPath];
    }
}

#pragma mark Hover Item Delegates

- (void)collectionView:(UICollectionView *)collectionView didBeginHoveringItemAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    if ([self.delegate respondsToSelector:@selector(collectionView:didBeginHoveringItemAtIndexPath:)]) {
        [self.delegate collectionView:collectionView didBeginHoveringItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndHoveringItemAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    if ([self.delegate respondsToSelector:@selector(collectionView:didEndHoveringItemAtIndexPath:)]) {
        [self.delegate collectionView:collectionView didEndHoveringItemAtIndexPath:indexPath];
    }
}

@end

#pragma mark -

@implementation MLReorderableCollectionController (DataSource)

#pragma mark Data Source Reorder

- (BOOL)collectionView:(UICollectionView *)collectionView canReorderItemAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    BOOL canReorder = NO;
    if ([self.dataSource respondsToSelector:@selector(collectionView:canReorderItemAtIndexPath:)]) {
        canReorder = [self.dataSource collectionView:collectionView canReorderItemAtIndexPath:indexPath];
    }
    
    return canReorder;
}

- (NSIndexPath *)indexPathForNewItemInCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    NSIndexPath * indexPath = nil;
    
    if ([self.dataSource respondsToSelector:@selector(indexPathForNewItemInCollectionView:)]) {
        indexPath = [self.dataSource indexPathForNewItemInCollectionView:collectionView];
    }
    
    if (!indexPath) {
        CGPoint point = [self.viewContainer convertPoint:self.viewPlaceholder.center toView:collectionView];
        indexPath = [collectionView indexPathForItemAtPoint:point];
        
        if (!indexPath) {
            indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        }
    }

    return indexPath;
}

#pragma mark Data Source Insert

- (BOOL)collectionView:(UICollectionView *)collectionView canInsertItemAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    BOOL canInsert = NO;
    if ([self.dataSource respondsToSelector:@selector(collectionView:canInsertItemAtIndexPath:)]) {
        canInsert = [self.dataSource collectionView:collectionView canInsertItemAtIndexPath:indexPath];
    }
    
    return canInsert;
}

- (void)collectionView:(UICollectionView *)collectionView willInsertItemAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    if ([self.dataSource respondsToSelector:@selector(collectionView:willInsertItemAtIndexPath:)]) {
        [self.dataSource collectionView:collectionView willInsertItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didInsertItemAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    if ([self.dataSource respondsToSelector:@selector(collectionView:didInsertItemAtIndexPath:)]) {
        [self.dataSource collectionView:collectionView didInsertItemAtIndexPath:indexPath];
    }
}

#pragma mark Data Source Delete

- (BOOL)collectionView:(UICollectionView *)collectionView canDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    BOOL canDelete = NO;
    if ([self.dataSource respondsToSelector:@selector(collectionView:canDeleteItemAtIndexPath:)]) {
        canDelete = [self.dataSource collectionView:collectionView canDeleteItemAtIndexPath:indexPath];
    }
    
    return canDelete;
}

- (void)collectionView:(UICollectionView *)collectionView willDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    if ([self.dataSource respondsToSelector:@selector(collectionView:willDeleteItemAtIndexPath:)]) {
        [self.dataSource collectionView:collectionView willDeleteItemAtIndexPath:indexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeleteItemAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    if ([self.dataSource respondsToSelector:@selector(collectionView:didDeleteItemAtIndexPath:)]) {
        [self.dataSource collectionView:collectionView didDeleteItemAtIndexPath:indexPath];
    }
}

#pragma mark Data Source Replace

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canReplaceWithIndexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(fromIndexPath);
    NSParameterAssert(toIndexPath);
    BOOL canRepalce = NO;
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:canReplaceWithIndexPath:)]) {
        canRepalce = [self.dataSource collectionView:collectionView itemAtIndexPath:fromIndexPath canReplaceWithIndexPath:toIndexPath];
    }
    
    return canRepalce;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willReplaceWithIndexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(fromIndexPath);
    NSParameterAssert(toIndexPath);
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:willReplaceWithIndexPath:)]) {
        [self.dataSource collectionView:collectionView itemAtIndexPath:fromIndexPath willReplaceWithIndexPath:toIndexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didReplaceWithIndexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(fromIndexPath);
    NSParameterAssert(toIndexPath);
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:didReplaceWithIndexPath:)]) {
        [self.dataSource collectionView:collectionView itemAtIndexPath:fromIndexPath didReplaceWithIndexPath:toIndexPath];
    }
}

#pragma mark Data Source Move

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(fromIndexPath);
    NSParameterAssert(toIndexPath);
    BOOL canMove = NO;
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)]) {
        canMove = [self.dataSource collectionView:collectionView itemAtIndexPath:fromIndexPath canMoveToIndexPath:toIndexPath];
    }
    
    return canMove;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(fromIndexPath);
    NSParameterAssert(toIndexPath);
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:willMoveToIndexPath:)]) {
        [self.dataSource collectionView:collectionView itemAtIndexPath:fromIndexPath willMoveToIndexPath:toIndexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(fromIndexPath);
    NSParameterAssert(toIndexPath);
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:didMoveToIndexPath:)]) {
        [self.dataSource collectionView:collectionView itemAtIndexPath:fromIndexPath didMoveToIndexPath:toIndexPath];
    }
}

#pragma mark Data Source Transfer

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath canTransferToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    NSParameterAssert(toCollectionView);
    NSParameterAssert(toIndexPath);
    BOOL canTransfer = NO;
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:canTransferToCollectionView:indexPath:)]) {
        canTransfer = [self.dataSource collectionView:collectionView itemAtIndexPath:indexPath canTransferToCollectionView:toCollectionView indexPath:toIndexPath];
    }
    
    return canTransfer;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath willTransferToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    NSParameterAssert(toCollectionView);
    NSParameterAssert(toIndexPath);
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:willTransferToCollectionView:indexPath:)]) {
        [self.dataSource collectionView:collectionView itemAtIndexPath:indexPath willTransferToCollectionView:toCollectionView indexPath:toIndexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath didTransferToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    NSParameterAssert(toCollectionView);
    NSParameterAssert(toIndexPath);
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:didTransferToCollectionView:indexPath:)]) {
        [self.dataSource collectionView:collectionView itemAtIndexPath:indexPath didTransferToCollectionView:toCollectionView indexPath:toIndexPath];
    }
}

#pragma mark Data Source Copy

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath canCopyToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    NSParameterAssert(toCollectionView);
    NSParameterAssert(toIndexPath);
    BOOL canCopy = NO;
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:canCopyToCollectionView:indexPath:)]) {
        canCopy = [self.dataSource collectionView:collectionView itemAtIndexPath:indexPath canCopyToCollectionView:toCollectionView indexPath:toIndexPath];
    }
    
    return canCopy;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath willCopyToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    NSParameterAssert(toCollectionView);
    NSParameterAssert(toIndexPath);
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:willCopyToCollectionView:indexPath:)]) {
        [self.dataSource collectionView:collectionView itemAtIndexPath:indexPath willCopyToCollectionView:toCollectionView indexPath:toIndexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath didCopyToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    NSParameterAssert(toCollectionView);
    NSParameterAssert(toIndexPath);
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:didCopyToCollectionView:indexPath:)]) {
        [self.dataSource collectionView:collectionView itemAtIndexPath:indexPath didCopyToCollectionView:toCollectionView indexPath:toIndexPath];
    }
}

#pragma mark Data Source Replace

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath canReplaceWithCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    NSParameterAssert(toCollectionView);
    NSParameterAssert(toIndexPath);
    BOOL canReplace = NO;
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:canReplaceWithCollectionView:indexPath:)]) {
        canReplace = [self.dataSource collectionView:collectionView itemAtIndexPath:indexPath canReplaceWithCollectionView:toCollectionView indexPath:toIndexPath];
    }
    
    return canReplace;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath willReplaceWithCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    NSParameterAssert(toCollectionView);
    NSParameterAssert(toIndexPath);
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:willReplaceWithCollectionView:indexPath:)]) {
        [self.dataSource collectionView:collectionView itemAtIndexPath:indexPath willReplaceWithCollectionView:toCollectionView indexPath:toIndexPath];
    }
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)indexPath didReplaceWithCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    NSParameterAssert(toCollectionView);
    NSParameterAssert(toIndexPath);
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:didReplaceWithCollectionView:indexPath:)]) {
        [self.dataSource collectionView:collectionView itemAtIndexPath:indexPath didReplaceWithCollectionView:toCollectionView indexPath:toIndexPath];
    }
}

@end
