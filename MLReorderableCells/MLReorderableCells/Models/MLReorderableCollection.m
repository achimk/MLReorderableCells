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

#pragma mark Gesture Callbacks

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            //indexPath
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
            
            //can move
            if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)]) {
                if (![self.dataSource collectionView:self.collectionView canMoveItemAtIndexPath:indexPath]) {
                    return;
                }
            }
            
            //will begin dragging
            if ([self.delegate respondsToSelector:@selector(collectionView:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView willBeginDraggingItemAtIndexPath:indexPath];
            }
            
            //indexPath
            _reorderingCellIndexPath = indexPath;
            //scrolls top off
            self.collectionView.scrollsToTop = NO;
            //cell fake view
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
            
            [self.collectionView addSubview:_cellFakeView];
            [_cellFakeView addSubview:cellFakeImageView];
            [_cellFakeView addSubview:highlightedImageView];
            
            //set center
            _reorderingCellCenter = cell.center;
            _cellFakeViewCenter = _cellFakeView.center;
            [self.collectionView.collectionViewLayout invalidateLayout];

            //animation
            [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                _cellFakeView.center = cell.center;
                _cellFakeView.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                highlightedImageView.alpha = 0;
            } completion:^(BOOL finished) {
                [highlightedImageView removeFromSuperview];
            }];
            
            //did begin dragging
            if ([self.delegate respondsToSelector:@selector(collectionView:didBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView didBeginDraggingItemAtIndexPath:indexPath];
            }
        } break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            NSIndexPath * currentCellIndexPath = _reorderingCellIndexPath;
            //will end dragging
            if ([self.delegate respondsToSelector:@selector(collectionView:willEndDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView willEndDraggingItemAtIndexPath:currentCellIndexPath];
            }
            
            //scrolls top on
            self.collectionView.scrollsToTop = YES;
            
            //disable auto scroll
            [self invalidateDisplayLink];
            
            //remove fake view
            UICollectionViewLayoutAttributes * attributes = [self.collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:currentCellIndexPath];
            [UIView animateWithDuration:.3f delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                _cellFakeView.transform = CGAffineTransformIdentity;
                _cellFakeView.frame = attributes.frame;
            } completion:^(BOOL finished) {
                [_cellFakeView removeFromSuperview];
                _cellFakeView = nil;
                _reorderingCellIndexPath = nil;
                _reorderingCellCenter = CGPointZero;
                _cellFakeViewCenter = CGPointZero;
                
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
            //translation
            _panTranslation = [gestureRecognizer translationInView:self.collectionView];
            _cellFakeView.center = CGPointMake(_cellFakeViewCenter.x + _panTranslation.x, _cellFakeViewCenter.y + _panTranslation.y);
            
            //move layout
            if (![self moveItemIfNeeded]) {
                [self replaceItemIfNeeded];
            }
            
            //scroll
            if (CGRectGetMaxY(_cellFakeView.frame) >= self.collectionView.contentOffset.y + (self.collectionView.bounds.size.height - _scrollTrigerEdgeInsets.bottom -_scrollTrigerPadding.bottom)) {
                if (ceilf(self.collectionView.contentOffset.y) < self.collectionView.contentSize.height - self.collectionView.bounds.size.height) {
                    _scrollDirection = MLScrollDirectionDown;
                    [self setupDisplayLink];
                }
            }
            else if (CGRectGetMinY(_cellFakeView.frame) <= self.collectionView.contentOffset.y + _scrollTrigerEdgeInsets.top + _scrollTrigerPadding.top) {
                if (self.collectionView.contentOffset.y > -self.collectionView.contentInset.top) {
                    _scrollDirection = MLScrollDirectionUp;
                    [self setupDisplayLink];
                }
            }
            else {
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

- (BOOL)moveItemIfNeeded {
    NSIndexPath * atIndexPath = _reorderingCellIndexPath;
    NSIndexPath * toIndexPath = [self.collectionView indexPathForItemAtPoint:_cellFakeView.center];
    
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
    NSIndexPath * atIndexPath = _reorderingCellIndexPath;
    NSIndexPath * toIndexPath = [self.collectionView indexPathForItemAtPoint:_cellFakeView.center];
    
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
