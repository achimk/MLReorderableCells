//
//  MLReorderableCollection.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 20.05.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLReorderableCollection.h"

typedef NS_ENUM(NSUInteger, MLScrollDirection) {
    MLScrollDirectionNone,
    MLScrollDirectionUp,
    MLScrollDirectionDown
#warning Add support for horizontal direction scrolling
};

#pragma mark - MLReorderableCollection

@interface MLReorderableCollection ()

@property (nonatomic, readonly, strong) UIView * cellFakeView;
@property (nonatomic, readonly, strong) CADisplayLink * displayLink;
@property (nonatomic, readonly, strong) NSIndexPath * reorderingCellIndexPath;
@property (nonatomic, readonly, assign) CGPoint reorderingCellCenter;
@property (nonatomic, readonly, assign) CGPoint cellFakeViewCenter;
@property (nonatomic, readonly, assign) CGPoint panTranslation;
@property (nonatomic, readonly, assign) UIEdgeInsets scrollTrigerEdgeInsets;
@property (nonatomic, readonly, assign) UIEdgeInsets scrollTrigerPadding;
@property (nonatomic, readonly, assign) MLScrollDirection scrollDirection;

@property (nonatomic, readwrite, assign) BOOL insideCollectionFrame;
@property (nonatomic, readwrite, assign) BOOL itemInserted;
@property (nonatomic, readwrite, assign) BOOL itemDeleted;
@property (nonatomic, readwrite, strong) UIView * reorderableCollectionContainer;

@end

#pragma mark -

@implementation MLReorderableCollection

#pragma mark Init

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    
    if (self = [super init]) {
        _collectionView = collectionView;
        
        if ([collectionView.delegate conformsToProtocol:@protocol(MLReorderableCollectionDelegate)]) {
            id delegate = collectionView.delegate;
            __weak typeof(delegate)weakDelegate = delegate;
            _delegate = weakDelegate;
        }
        
        if ([collectionView.dataSource conformsToProtocol:@protocol(MLReorderableCollectionDataSource)]) {
            id dataSource = collectionView.dataSource;
            __weak typeof(dataSource)weakDataSource = dataSource;
            _dataSource = weakDataSource;
        }
        
        _scrollTrigerEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
        _scrollTrigerPadding = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
        
        [self setupCollectionViewGestures];
    }
    
    return self;
}

#pragma mark Accessors

- (void)setInsideCollectionFrame:(BOOL)insideCollectionFrame {
    if (insideCollectionFrame != _insideCollectionFrame) {
        _insideCollectionFrame = insideCollectionFrame;
        
        if (insideCollectionFrame) {
            if (!self.reorderingCellIndexPath) {
                self.itemInserted = [self insertItemIfNeeded];
            }
        }
        else {
            if (self.reorderingCellIndexPath) {
                self.itemDeleted = [self deleteItemIfNeeded];
            }
        }
    }
}

#pragma mark Gesture Callbacks

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            // indexPath
            NSIndexPath * indexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
            if (!indexPath) {
                return;
            }
            
            // can move
            if ([self.dataSource respondsToSelector:@selector(collectionView:canReorderItemAtIndexPath:)]) {
                if (![self.dataSource collectionView:self.collectionView canReorderItemAtIndexPath:indexPath]) {
                    return;
                }
            }
            
            // will begin dragging
            if ([self.delegate respondsToSelector:@selector(collectionView:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView willBeginDraggingItemAtIndexPath:indexPath];
            }
            
            // indexPath
            _reorderingCellIndexPath = indexPath;
            _insideCollectionFrame = YES;

            // scrolls top off
            self.collectionView.scrollsToTop = NO;
            
            // cell fake view
            UICollectionViewCell * cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            _cellFakeView = [[UIView alloc] initWithFrame:cell.frame];
            _cellFakeView.layer.shadowColor = [UIColor blackColor].CGColor;
            _cellFakeView.layer.shadowOffset = CGSizeMake(0, 0);
            _cellFakeView.layer.shadowOpacity = .5f;
            _cellFakeView.layer.shadowRadius = 3.f;
            
            UIImageView * cellFakeImageView = [[UIImageView alloc] initWithFrame:cell.bounds];
            UIImageView * highlightedImageView = [[UIImageView alloc] initWithFrame:cell.bounds];
            cellFakeImageView.contentMode = UIViewContentModeScaleAspectFill;
            highlightedImageView.contentMode = UIViewContentModeScaleAspectFill;
            cellFakeImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            highlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            cell.highlighted = YES;
            highlightedImageView.image = [self imageFromCollectionViewCell:cell];
            cell.highlighted = NO;
            cellFakeImageView.image = [self imageFromCollectionViewCell:cell];

            UIView * reorderableCollectionContainer = [self reorderableCollectionContainer];
            CGRect fakeViewRect = [cell convertRect:cell.bounds toView:reorderableCollectionContainer];
            _cellFakeView.frame = fakeViewRect;
            
            [reorderableCollectionContainer addSubview:_cellFakeView];
            [_cellFakeView addSubview:cellFakeImageView];
            [_cellFakeView addSubview:highlightedImageView];
            
            // set center
            _reorderingCellCenter = cell.center;
            _cellFakeViewCenter = _cellFakeView.center;
            [self.collectionView.collectionViewLayout invalidateLayout];

            // animation
            [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                _cellFakeView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                highlightedImageView.alpha = 0;
            } completion:^(BOOL finished) {
                [highlightedImageView removeFromSuperview];
            }];
            
            // did begin dragging
            if ([self.delegate respondsToSelector:@selector(collectionView:didBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView didBeginDraggingItemAtIndexPath:indexPath];
            }
        } break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            NSIndexPath * currentCellIndexPath = _reorderingCellIndexPath;
            
            // will end dragging
            if ([self.delegate respondsToSelector:@selector(collectionView:willEndDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView willEndDraggingItemAtIndexPath:currentCellIndexPath];
            }
            
            // scrolls top on
            self.collectionView.scrollsToTop = YES;
            
            // disable auto scroll
            [self invalidateDisplayLink];
            
            // remove fake view
            CGRect frame = CGRectZero;
            CGAffineTransform transform = CGAffineTransformIdentity;
            
            // back to current frame
            if (currentCellIndexPath) {
                UICollectionViewLayoutAttributes * attributes = [self.collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:currentCellIndexPath];
                UIView * reorderableCollectionContainer = [self reorderableCollectionContainer];
                frame = [self.collectionView convertRect:attributes.frame toView:reorderableCollectionContainer];
            }
            
            [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                if (currentCellIndexPath) { // move animation to original frame
                    _cellFakeView.transform = transform;
                    _cellFakeView.frame = frame;
                }
                else { // delete animation
                    _cellFakeView.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
                    _cellFakeView.alpha = 0.0f;
                }
            } completion:^(BOOL finished) {
                [_cellFakeView removeFromSuperview];
                _cellFakeView = nil;
                _reorderingCellIndexPath = nil;
                _reorderingCellCenter = CGPointZero;
                _cellFakeViewCenter = CGPointZero;

                self.insideCollectionFrame = NO;
                self.itemInserted = NO;
                self.itemDeleted = NO;
                
                self.reorderableCollectionContainer = nil;
                [self.collectionView.collectionViewLayout invalidateLayout];
                
                if (finished) {
                    //did end dragging
                    if ([self.delegate respondsToSelector:@selector(collectionView:didEndDraggingItemAtIndexPath:)]) {
                        [self.delegate collectionView:self.collectionView didEndDraggingItemAtIndexPath:currentCellIndexPath];
                    }
                }
            }];
        } break;
            
        default: break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateChanged: {
            // translation
            _panTranslation = [gestureRecognizer translationInView:self.collectionView];
            _cellFakeView.center = CGPointMake(_cellFakeViewCenter.x + _panTranslation.x, _cellFakeViewCenter.y + _panTranslation.y);
            
            // item is delete already
            if (self.itemDeleted) {
                return;
            }
            
            // move layout
            if (![self moveItemIfNeeded]) {
                [self replaceItemIfNeeded];
            }
            
            UIView * reorderableCollectionContainer = [self reorderableCollectionContainer];
            CGPoint fakeCellCenter = CGPointMake(CGRectGetMidX(_cellFakeView.frame), CGRectGetMidY(_cellFakeView.frame));
            CGRect fakeCellRect = [reorderableCollectionContainer convertRect:_cellFakeView.frame toView:self.collectionView];
            CGRect visibleRect = CGRectZero;
            visibleRect.origin = self.collectionView.contentOffset;
            visibleRect.size = self.collectionView.frame.size;
            CGRect collectionViewRect = [self.collectionView convertRect:visibleRect toView:reorderableCollectionContainer];
            self.insideCollectionFrame = CGRectContainsPoint(collectionViewRect, fakeCellCenter);
            
            // Check dragged center point is inside of collection view frame
            if (self.insideCollectionFrame) {
                // Scrolls down
                if (CGRectGetMaxY(fakeCellRect) >= self.collectionView.contentOffset.y + (self.collectionView.bounds.size.height - _scrollTrigerEdgeInsets.bottom -_scrollTrigerPadding.bottom)) {
                    if (ceilf(self.collectionView.contentOffset.y) < self.collectionView.contentSize.height - self.collectionView.bounds.size.height) {
                        _scrollDirection = MLScrollDirectionDown;
                        [self setupDisplayLink];
                    }
                }
                // Scrolls up
                else if (CGRectGetMinY(fakeCellRect) <= self.collectionView.contentOffset.y + _scrollTrigerEdgeInsets.top + _scrollTrigerPadding.top) {
                    if (self.collectionView.contentOffset.y > -self.collectionView.contentInset.top) {
                        _scrollDirection = MLScrollDirectionUp;
                        [self setupDisplayLink];
                    }
                }
                // Ignore scrolling
                else {
                    _scrollDirection = MLScrollDirectionNone;
                    [self invalidateDisplayLink];
                }
            }
            else { // Center poiny outside of collection view frame
                _scrollDirection = MLScrollDirectionNone;
                [self invalidateDisplayLink];
            }
        
        } break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            [self invalidateDisplayLink];
        } break;
            
        default: break;
    }
}

- (BOOL)insertItemIfNeeded {
    return NO;
}

- (BOOL)deleteItemIfNeeded {
    NSIndexPath * atIndexPath = _reorderingCellIndexPath;
    
    // can delete
    if ([self.dataSource respondsToSelector:@selector(collectionView:canDeleteItemAtIndexPath:)]) {
        if (![self.dataSource collectionView:self.collectionView canDeleteItemAtIndexPath:atIndexPath]) {
            return NO;
        }
    }
    
    // will delete
    if ([self.dataSource respondsToSelector:@selector(collectionView:willDeleteItemAtIndexPath:)]) {
        [self.dataSource collectionView:self.collectionView willDeleteItemAtIndexPath:atIndexPath];
    }
    
    // delete
    [self.collectionView performBatchUpdates:^{
        // delete cell indexPath
        _reorderingCellIndexPath = nil;
        [self.collectionView deleteItemsAtIndexPaths:@[atIndexPath]];
        
        // did delete
        if ([self.dataSource respondsToSelector:@selector(collectionView:didDeleteItemAtIndexPath:)]) {
            [self.dataSource collectionView:self.collectionView didDeleteItemAtIndexPath:atIndexPath];
        }
    } completion:nil];
    
    return YES;
}

- (BOOL)moveItemIfNeeded {
    UIView * reorderableCollectionContainer = [self reorderableCollectionContainer];
    CGPoint point = [reorderableCollectionContainer convertPoint:_cellFakeView.center toView:self.collectionView];
    NSIndexPath * atIndexPath = _reorderingCellIndexPath;
    NSIndexPath * toIndexPath = [self.collectionView indexPathForItemAtPoint:point];
    
    if (nil == toIndexPath || [atIndexPath isEqual:toIndexPath]) {
        return NO;
    }
    
    // can move
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)]) {
        if (![self.dataSource collectionView:self.collectionView itemAtIndexPath:atIndexPath canMoveToIndexPath:toIndexPath]) {
            return NO;
        }
    }
    
    // will move
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:willMoveToIndexPath:)]) {
        [self.dataSource collectionView:self.collectionView itemAtIndexPath:atIndexPath willMoveToIndexPath:toIndexPath];
    }
    
    // move
    [self.collectionView performBatchUpdates:^{
        // update cell indexPath
        _reorderingCellIndexPath = toIndexPath;
        [self.collectionView moveItemAtIndexPath:atIndexPath toIndexPath:toIndexPath];
        
        // did move
        if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:didMoveToIndexPath:)]) {
            [self.dataSource collectionView:self.collectionView itemAtIndexPath:atIndexPath didMoveToIndexPath:toIndexPath];
        }
    } completion:nil];
    
    return YES;
}

- (BOOL)replaceItemIfNeeded {
    UIView * reorderableCollectionContainer = [self reorderableCollectionContainer];
    CGPoint point = [reorderableCollectionContainer convertPoint:_cellFakeView.center toView:self.collectionView];
    NSIndexPath * atIndexPath = _reorderingCellIndexPath;
    NSIndexPath * toIndexPath = [self.collectionView indexPathForItemAtPoint:point];
    
    if (nil == toIndexPath || [atIndexPath isEqual:toIndexPath]) {
        return NO;
    }
    
    // can replace
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:canReplaceWithIndexPath:)]) {
        if (![self.dataSource collectionView:self.collectionView itemAtIndexPath:atIndexPath canReplaceWithIndexPath:toIndexPath]) {
            return NO;
        }
    }
    
    // will replace
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:willReplaceWithIndexPath:)]) {
        [self.dataSource collectionView:self.collectionView itemAtIndexPath:atIndexPath willReplaceWithIndexPath:toIndexPath];
    }
    
    // replace
    [self.collectionView performBatchUpdates:^{
        // update cell indexPath
        _reorderingCellIndexPath = toIndexPath;
        [self.collectionView moveItemAtIndexPath:atIndexPath toIndexPath:toIndexPath];
        [self.collectionView moveItemAtIndexPath:toIndexPath toIndexPath:atIndexPath];
        
        // did replace
        if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:didReplaceWithIndexPath:)]) {
            [self.dataSource collectionView:self.collectionView itemAtIndexPath:atIndexPath didReplaceWithIndexPath:toIndexPath];
        }
    } completion:nil];
    
    return YES;
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.panGesture isEqual:gestureRecognizer]) {
        if (UIGestureRecognizerStatePossible == self.longPressGesture.state ||
            UIGestureRecognizerStateFailed == self.longPressGesture.state) {
            return NO;
        }
    }
    else if ([self.longPressGesture isEqual:gestureRecognizer]) {
        if (UIGestureRecognizerStatePossible != self.collectionView.panGestureRecognizer.state &&
            UIGestureRecognizerStateFailed != self.collectionView.panGestureRecognizer.state) {
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
    else if ([self.collectionView.panGestureRecognizer isEqual:gestureRecognizer]) {
        if (UIGestureRecognizerStatePossible == self.longPressGesture.state ||
            UIGestureRecognizerStateFailed == self.longPressGesture.state) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark Private Methods

- (UIView *)reorderableCollectionContainer {
    if (_reorderableCollectionContainer) {
        return _reorderableCollectionContainer;
    }
    
    UIView * collectionContainer = nil;
    if ([self.dataSource respondsToSelector:@selector(reorderableCollectionContainerForCollectionView:)]) {
        collectionContainer = [self.dataSource reorderableCollectionContainerForCollectionView:self.collectionView];
        
#if DEBUG
        if (collectionContainer) {
            UIView * superview = self.collectionView;
            while (nil != superview) {
                if (collectionContainer == superview) {
                    break;
                }
                
                superview = superview.superview;
            }
            
            NSAssert(superview, @"Reorderable collection container doesn't contains collection view as a child view.");
        }
#endif
    }
    
    if (!collectionContainer) {
        collectionContainer = self.collectionView;
    }
    
    _reorderableCollectionContainer = collectionContainer;
    
    return collectionContainer;
}

- (void)setupCollectionViewGestures {
    _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    _longPressGesture.delegate = self;
    _panGesture.delegate = self;
    
    for (UIGestureRecognizer * gestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:_longPressGesture];
        }
    }
    
    [self.collectionView addGestureRecognizer:_longPressGesture];
    [self.collectionView addGestureRecognizer:_panGesture];
}

- (void)setupDisplayLink {
    if (_displayLink) {
        return;
    }
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(autoScroll)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)invalidateDisplayLink {
    [_displayLink invalidate];
    _displayLink = nil;
}


- (void)autoScroll {
    if (self.collectionView == self.reorderableCollectionContainer) {
        [self collectionViewAutoScroll];
    }
    else {
        [self reorderableCollectionContainerAutoScroll];
    }
}

- (void)reorderableCollectionContainerAutoScroll {
    CGPoint contentOffset = self.collectionView.contentOffset;
    UIEdgeInsets contentInset = self.collectionView.contentInset;
    CGSize contentSize = self.collectionView.contentSize;
    CGSize boundsSize = self.collectionView.bounds.size;
    CGFloat increment = 0;
    
    UIView * reorderableCollectionContainer = [self reorderableCollectionContainer];
    CGRect fakeCellRect = [reorderableCollectionContainer convertRect:_cellFakeView.frame toView:self.collectionView];
    
    if (MLScrollDirectionDown == _scrollDirection) {
        CGFloat percentage = (((CGRectGetMaxY(fakeCellRect) - contentOffset.y) - (boundsSize.height - _scrollTrigerEdgeInsets.bottom - _scrollTrigerPadding.bottom)) / _scrollTrigerEdgeInsets.bottom);
        increment = 10 * percentage;
        
        if (increment >= 10.f) {
            increment = 10.f;
        }
    }
    else if (MLScrollDirectionUp == _scrollDirection) {
        CGFloat percentage = (1.f - ((CGRectGetMinY(fakeCellRect) - contentOffset.y - _scrollTrigerPadding.top) / _scrollTrigerEdgeInsets.top));
        increment = -10.f * percentage;
        
        if (increment <= -10.f) {
            increment = -10.f;
        }
    }
    
    if (contentOffset.y + increment <= -contentInset.top) {
        [UIView animateWithDuration:.07f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.collectionView.contentOffset = CGPointMake(contentOffset.x, -contentInset.top);
        } completion:nil];
        
        [self invalidateDisplayLink];
        return;
    }
    else if (contentOffset.y + increment >= contentSize.height - boundsSize.height - contentInset.bottom) {
        [UIView animateWithDuration:.07f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.collectionView.contentOffset = CGPointMake(contentOffset.x, contentSize.height - boundsSize.height - contentInset.bottom);
        } completion:nil];
        
        [self invalidateDisplayLink];
        return;
    }
    
    [self.collectionView performBatchUpdates:^{
        self.collectionView.contentOffset = CGPointMake(contentOffset.x, contentOffset.y + increment);
    } completion:nil];
    
    if (![self moveItemIfNeeded]) {
        [self replaceItemIfNeeded];
    }

}

- (void)collectionViewAutoScroll {
    CGPoint contentOffset = self.collectionView.contentOffset;
    UIEdgeInsets contentInset = self.collectionView.contentInset;
    CGSize contentSize = self.collectionView.contentSize;
    CGSize boundsSize = self.collectionView.bounds.size;
    CGFloat increment = 0;
    
    if (MLScrollDirectionDown == _scrollDirection) {
        CGFloat percentage = (((CGRectGetMaxY(_cellFakeView.frame) - contentOffset.y) - (boundsSize.height - _scrollTrigerEdgeInsets.bottom - _scrollTrigerPadding.bottom)) / _scrollTrigerEdgeInsets.bottom);
        increment = 10 * percentage;
        
        if (increment >= 10.f) {
            increment = 10.f;
        }
    }
    else if (MLScrollDirectionUp == _scrollDirection) {
        CGFloat percentage = (1.f - ((CGRectGetMinY(_cellFakeView.frame) - contentOffset.y - _scrollTrigerPadding.top) / _scrollTrigerEdgeInsets.top));
        increment = -10.f * percentage;
        
        if (increment <= -10.f) {
            increment = -10.f;
        }
    }
    
    if (contentOffset.y + increment <= -contentInset.top) {
        [UIView animateWithDuration:.07f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGFloat diff = -contentInset.top - contentOffset.y;
            self.collectionView.contentOffset = CGPointMake(contentOffset.x, -contentInset.top);
            _cellFakeViewCenter = CGPointMake(_cellFakeViewCenter.x, _cellFakeViewCenter.y + diff);
            _cellFakeView.center = CGPointMake(_cellFakeViewCenter.x + _panTranslation.x, _cellFakeViewCenter.y + _panTranslation.y);
        } completion:nil];
        
        [self invalidateDisplayLink];
        return;
    }
    else if (contentOffset.y + increment >= contentSize.height - boundsSize.height - contentInset.bottom) {
        [UIView animateWithDuration:.07f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGFloat diff = contentSize.height - boundsSize.height - contentInset.bottom - contentOffset.y;
            self.collectionView.contentOffset = CGPointMake(contentOffset.x, contentSize.height - boundsSize.height - contentInset.bottom);
            _cellFakeViewCenter = CGPointMake(_cellFakeViewCenter.x, _cellFakeViewCenter.y + diff);
            _cellFakeView.center = CGPointMake(_cellFakeViewCenter.x + _panTranslation.x, _cellFakeViewCenter.y + _panTranslation.y);
        } completion:nil];
        
        [self invalidateDisplayLink];
        return;
    }
    
    [self.collectionView performBatchUpdates:^{
        _cellFakeViewCenter = CGPointMake(_cellFakeViewCenter.x, _cellFakeViewCenter.y + increment);
        _cellFakeView.center = CGPointMake(_cellFakeViewCenter.x + _panTranslation.x, _cellFakeViewCenter.y + _panTranslation.y);
        self.collectionView.contentOffset = CGPointMake(contentOffset.x, contentOffset.y + increment);
    } completion:nil];
    
    if (![self moveItemIfNeeded]) {
        [self replaceItemIfNeeded];
    }
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
