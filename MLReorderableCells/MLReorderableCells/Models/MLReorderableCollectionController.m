//
//  MLReorderableCollectionController.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 08.07.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLReorderableCollectionController.h"

#define ANIMATION_DURATION  0.3f
#define ANIMATION_DELAY     0.0f

#pragma mark - MLReorderableCollectionController (Delegate)

@interface MLReorderableCollectionController (Delegate)

// Dragging delegates
- (void)collectionView:(UICollectionView *)collectionView willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

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

@end

#pragma mark - MLReorderableCollectionController

@interface MLReorderableCollectionController ()

@property (nonatomic, readonly, strong) NSMutableArray * arrayOfCollectionViews;
@property (nonatomic, readwrite, assign, getter=isInside) BOOL inside;
@property (nonatomic, readwrite, strong) UIView * viewPlaceholder;
@property (nonatomic, readwrite, strong) NSIndexPath * currentIndexPath;
@property (nonatomic, readwrite, strong) UICollectionView * currentCollectionView;

@end

#pragma mark -

@implementation MLReorderableCollectionController

#pragma mark Init

- (instancetype)initWithViewContainer:(UIView *)viewContainer {
    NSParameterAssert(viewContainer);
    
    if (self = [super init]) {
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
            
            UICollectionViewCell * cell = [collectionView cellForItemAtIndexPath:indexPath];
            UIView * viewPlaceholder = [self viewPlaceholderFromCollectionViewCell:cell];
            
            self.inside = YES;
            [self allowsScrollToTop:NO];
            self.viewPlaceholder = viewPlaceholder;
            self.currentIndexPath = indexPath;
            self.currentCollectionView = collectionView;
            
            [self collectionView:collectionView willBeginDraggingItemAtIndexPath:indexPath];
            
            [self animateLongPressBeginForCollectionView:collectionView
                                               indexPath:indexPath
                                             placeholder:viewPlaceholder
                                              completion:nil];
            
            [self collectionView:collectionView didBeginDraggingItemAtIndexPath:indexPath];
            
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            NSIndexPath * indexPath = self.currentIndexPath;
            UICollectionView * collectionView = self.currentCollectionView;
            UIView * viewPlaceholder = self.viewPlaceholder;
            
            self.inside = NO;
            [self allowsScrollToTop:YES];
            self.viewPlaceholder = nil;
            self.currentIndexPath = nil;
            self.currentCollectionView = nil;
            
            __weak typeof(self)weakSelf = self;
            void (^completion)(BOOL) = ^(BOOL finished) {
                if (finished) {
                    [weakSelf collectionView:collectionView didEndDraggingItemAtIndexPath:indexPath];
                }
            };
            
            [self collectionView:collectionView willEndDraggingItemAtIndexPath:indexPath];

            [self animateLongPressEndForCollectionView:collectionView
                                             indexPath:indexPath
                                           placeholder:viewPlaceholder
                                            completion:completion];
        } break;
        default: break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateChanged: {
            UICollectionView * collectionView = [self collectionViewForGesture:gestureRecognizer];
            BOOL shouldUpdateInside = NO;
            BOOL shouldUpdateCollectionView = NO;
            BOOL isInside = (nil != collectionView);
            BOOL hasChanged = (isInside != self.isInside);
            BOOL hasCollectionViewChanged = (isInside && self.currentCollectionView != collectionView);
            
            CGPoint point = [gestureRecognizer locationInView:self.viewContainer];
            UIView * viewPlaceholder = self.viewPlaceholder;
            viewPlaceholder.center = point;

            if (hasCollectionViewChanged) {
                if (self.currentIndexPath) {
                    NSLog(@"-> change collection view");
                    UICollectionView * fromCollectionView = self.currentCollectionView;
                    [self transferItemFromCollectionView:fromCollectionView toCollectionView:collectionView];
                }
                else {
                    NSLog(@"-> inside new collection view");
                    shouldUpdateInside = shouldUpdateCollectionView = [self insertItemToCollectionView:collectionView];
                }
            }
            else if (isInside && hasChanged) {
                NSLog(@"-> inside");
                shouldUpdateInside = [self insertItemToCollectionView:collectionView];
            }
            else if (!isInside && hasChanged){
                NSLog(@"-> outside");
                shouldUpdateInside = [self deleteItemFromCollectionView:self.currentCollectionView];
            }
            else if (isInside) {
                NSLog(@"-> replace/move");
                [self replaceOrMoveItemInCollectionView:collectionView];
            }
            
            if (shouldUpdateInside) {
                self.inside = isInside;
            }
            
            if (shouldUpdateCollectionView) {
                self.currentCollectionView = collectionView;
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
        
        if (!collectionView) {
            return NO;
        }
        
        if (UIGestureRecognizerStatePossible == self.longPressGesture.state ||
            UIGestureRecognizerStateFailed == self.longPressGesture.state) {
            return NO;
        }
    }
    else if ([self.longPressGesture isEqual:gestureRecognizer]) {
        UICollectionView * collectionView = [self collectionViewForGesture:gestureRecognizer];
        
        if (!collectionView) {
            return NO;
        }
        
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
            if ([self.longPressGesture isEqual:otherGestureRecognizer]) {
                return YES;
            }
            
            return NO;
        }
    }
    else if ([self.longPressGesture isEqual:gestureRecognizer]) {
        if ([self.panGesture isEqual:otherGestureRecognizer]) {
            return YES;
        }
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

- (BOOL)insertItemToCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    NSIndexPath * indexPath = [self indexPathForNewItemInCollectionView:collectionView];
    if (!indexPath) {
        return NO;
    }
    
    if (![self collectionView:collectionView canInsertItemAtIndexPath:indexPath]) {
        return NO;
    }
    
    [self collectionView:collectionView willInsertItemAtIndexPath:indexPath];
    [collectionView performBatchUpdates:^{
        self.currentIndexPath = indexPath;
        [collectionView insertItemsAtIndexPaths:@[indexPath]];
        [self collectionView:collectionView didInsertItemAtIndexPath:indexPath];
    } completion:nil];
    
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
    CGPoint point = [self.viewContainer convertPoint:self.viewPlaceholder.center toView:collectionView];
    NSIndexPath * fromIndexPath = self.currentIndexPath;
    NSIndexPath * toIndexPath = [collectionView indexPathForItemAtPoint:point];
    
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

- (BOOL)transferItemFromCollectionView:(UICollectionView *)fromCollectionView toCollectionView:(UICollectionView *)toCollectionView {
    NSParameterAssert(fromCollectionView);
    NSParameterAssert(toCollectionView);
    NSIndexPath * fromIndexPath = self.currentIndexPath;
    if (!fromIndexPath) {
        return NO;
    }
    
    NSIndexPath * toIndexPath = [self indexPathForNewItemInCollectionView:toCollectionView];
    if (!toIndexPath) {
        return NO;
    }
    
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
        [self animateTransferFromCollectionView:fromCollectionView
                                itemAtIndexPath:fromIndexPath
                               toCollectionView:toCollectionView
                                      indexPath:toIndexPath
                                    placeholder:viewPlaceholder
                                     completion:nil];
    }];
    
    return YES;
}

#pragma mark Animations

- (void)animateLongPressBeginForCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath placeholder:(UIView *)viewPlaceholder completion:(void(^)(BOOL))completion {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    NSParameterAssert(viewPlaceholder);
    UICollectionViewCell * cell = [collectionView cellForItemAtIndexPath:indexPath];
    UIView * viewContainer = self.viewContainer;
    viewPlaceholder.frame = [cell convertRect:cell.bounds toView:viewContainer];
    
    cell.highlighted = YES;
    UIImageView * highlightedImageView = [self imageViewFromCollectionViewCell:cell];
    cell.highlighted = NO;
    UIImageView * normalImageView = [self imageViewFromCollectionViewCell:cell];
    
    [viewPlaceholder addSubview:normalImageView];
    [viewPlaceholder addSubview:highlightedImageView];
    [viewContainer addSubview:viewPlaceholder];
    
    [collectionView.collectionViewLayout invalidateLayout];
    
    [UIView animateWithDuration:ANIMATION_DURATION delay:ANIMATION_DELAY options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
        viewPlaceholder.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
        highlightedImageView.alpha = 0;
    } completion:^(BOOL finished) {
        [highlightedImageView removeFromSuperview];
        
        if (completion) {
            completion(finished);
        }
    }];
}

- (void)animateLongPressEndForCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath placeholder:(UIView *)viewPlaceholder completion:(void(^)(BOOL))completion {
    NSParameterAssert(collectionView);
    NSParameterAssert(viewPlaceholder);
    CGRect frame = CGRectZero;

    if (indexPath) {
        UICollectionViewLayoutAttributes * attributes = [collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
        frame = [collectionView convertRect:attributes.frame toView:self.viewContainer];
    }
    
    [UIView animateWithDuration:ANIMATION_DURATION delay:ANIMATION_DELAY options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
        if (indexPath) {
            viewPlaceholder.transform = CGAffineTransformIdentity;
            viewPlaceholder.frame = frame;
        }
        else {
            viewPlaceholder.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
            viewPlaceholder.alpha = 0.0f;
        }
    } completion:^(BOOL finished) {
        [viewPlaceholder removeFromSuperview];
        [collectionView.collectionViewLayout invalidateLayout];
        
        if (completion) {
            completion(finished);
        }
    }];
}

- (void)animateTransferFromCollectionView:(UICollectionView *)fromCollectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath toCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath placeholder:(UIView *)viewPlaceholder completion:(void(^)(BOOL))completion {
//    NSParameterAssert(fromCollectionView);
//    NSParameterAssert(fromIndexPath);
//    NSParameterAssert(toCollectionView);
//    NSParameterAssert(toIndexPath);
//    NSParameterAssert(viewPlaceholder);
    
#warning Implement!
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
    CGPoint touchPoint = [self.panGesture locationOfTouch:0 inView:self.viewContainer];
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
    UIView * viewPlaceholder = [[UIView alloc] initWithFrame:cell.bounds];
    viewPlaceholder.layer.shadowColor = [UIColor blackColor].CGColor;
    viewPlaceholder.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    viewPlaceholder.layer.shadowOpacity = 0.5f;
    viewPlaceholder.layer.shadowRadius = 3.0f;
    
    return viewPlaceholder;
}

- (UIImageView *)imageViewFromCollectionViewCell:(UICollectionViewCell *)cell {
    NSParameterAssert(cell);
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:cell.bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    imageView.image = [self imageFromCollectionViewCell:cell];
    
    return imageView;
}

- (UIImage *)imageFromCollectionViewCell:(UICollectionViewCell *)cell {
    NSParameterAssert(cell);
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, 4.0f);
    [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
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
    NSAssert(self.viewPlaceholder, @"View placeholder should be set when accessing new index path!");
    NSParameterAssert(collectionView);
    CGPoint point = [self.viewContainer convertPoint:self.viewPlaceholder.center fromView:collectionView];
    NSIndexPath * indexPath = [collectionView indexPathForItemAtPoint:point];
    
    if (!indexPath && [self.dataSource respondsToSelector:@selector(indexPathForNewItemInCollectionView:)]) {
        indexPath = [self.dataSource indexPathForNewItemInCollectionView:collectionView];
    }
    
#warning Should we always return a valid index path (non-nil)?
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

@end
