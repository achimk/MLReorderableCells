//
//  MLReorderableCollections.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 08.07.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLReorderableCollections.h"
#import "MLReorderableCollection+Private.h"

#pragma mark - MLReorderableCollectionContainer

@interface MLReorderableCollectionContainer : MLReorderableCollection

@property (nonatomic, readwrite, strong) UIView * viewContainer;

@end

#pragma mark -

@implementation MLReorderableCollectionContainer

#pragma mark Init

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView {
    if (self = [super initWithCollectionView:collectionView]) {
        self.panGesture = nil;
    }
    
    return self;
}

#pragma mark Private Methods

- (UIView *)reorderableCollectionContainer {
    return self.viewContainer;
}

- (void)addGesturesForCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    UIGestureRecognizer * longPressGesture = self.longPressGesture;
    
    for (UIGestureRecognizer * gestureRecognizer in collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:longPressGesture];
        }
    }
    
    [collectionView addGestureRecognizer:longPressGesture];
}

- (void)removeGesturesForCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    UIGestureRecognizer * longPressGesture = self.longPressGesture;
    [collectionView removeGestureRecognizer:longPressGesture];
}

@end

#pragma mark - MLReorderableCollections

@interface MLReorderableCollections ()

@property (nonatomic, readonly, strong) NSMutableArray * arrayOfReorderableCollections;
@property (nonatomic, readonly, strong) UIPanGestureRecognizer * panGesture;

@end

#pragma mark -

@implementation MLReorderableCollections

#pragma mark Init

- (instancetype)initWithContainerView:(UIView *)viewContainer {
    NSParameterAssert(viewContainer);
    
    if (self = [super init]) {
        _viewContainer = viewContainer;
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        _panGesture.delegate = self;
        [viewContainer addGestureRecognizer:_panGesture];
        _arrayOfReorderableCollections = [[NSMutableArray alloc] init];
    }
    
    return self;
}

#pragma mark Collection View Managment

- (MLReorderableCollectionContainer *)reorderableCollectionWithCollectionView:(UICollectionView *)collectionView {
    NSUInteger index = [self indexForCollectionView:collectionView];
    return (NSNotFound != index) ? self.arrayOfReorderableCollections[index] : nil;
}

- (NSUInteger)indexForCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    
    __block NSUInteger index = NSNotFound;
    [self.arrayOfReorderableCollections enumerateObjectsUsingBlock:^(MLReorderableCollectionContainer * obj, NSUInteger idx, BOOL *stop) {
        if (collectionView == obj.collectionView) {
            index = idx;
            *stop = YES;
        }
    }];
    
    return index;
}

- (BOOL)hasCollectionView:(UICollectionView *)collectionView {
    return (NSNotFound != [self indexForCollectionView:collectionView]);
}

- (MLReorderableCollection *)addCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    MLReorderableCollection * reorderableCollection = [self reorderableCollectionWithCollectionView:collectionView];
    if (!reorderableCollection) {
        reorderableCollection = [self newReorderableCollectionWithCollectionView:collectionView];
        
        if (reorderableCollection) {
            [self.arrayOfReorderableCollections addObject:reorderableCollection];
        }
    }
    
    return reorderableCollection;
}

- (MLReorderableCollection *)removeCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    MLReorderableCollection * reorderableCollection = [self reorderableCollectionWithCollectionView:collectionView];
    if (reorderableCollection) {
        [self.arrayOfReorderableCollections removeObject:reorderableCollection];
    }
    
    return reorderableCollection;
}

#pragma mark Gesture Callbacks

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
#warning Implement!
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateChanged: {
            NSLog(@"-> pan gesture: %@", gestureRecognizer);
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
        
        } break;
        default: break;
    }
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isEqual:self.panGesture]) {
        CGPoint touchPoint = [self.panGesture locationOfTouch:0 inView:self.viewContainer];
        UICollectionView * collectionView = [self collectionViewAtPoint:touchPoint];
        
        if (!collectionView) {
            return NO;
        }
        
        MLReorderableCollectionContainer * reorderableCollection = [self reorderableCollectionWithCollectionView:collectionView];
        UILongPressGestureRecognizer * longPressGesture = reorderableCollection.longPressGesture;
        
        if (UIGestureRecognizerStatePossible == longPressGesture.state ||
            UIGestureRecognizerStateFailed == longPressGesture.state) {
            return NO;
        }
    }
    else if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        UICollectionView * collectionView = (UICollectionView *)gestureRecognizer.view;
        if (UIGestureRecognizerStatePossible != collectionView.panGestureRecognizer.state &&
            UIGestureRecognizerStateFailed != collectionView.panGestureRecognizer.state) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isEqual:self.panGesture]) {
        CGPoint touchPoint = [self.panGesture locationOfTouch:0 inView:self.viewContainer];
        UICollectionView * collectionView = [self collectionViewAtPoint:touchPoint];
        
        if (!collectionView) {
            return NO;
        }

        MLReorderableCollectionContainer * reorderableCollection = [self reorderableCollectionWithCollectionView:collectionView];
        UILongPressGestureRecognizer * longPressGesture = reorderableCollection.longPressGesture;
        
        if (UIGestureRecognizerStatePossible != longPressGesture.state &&
            UIGestureRecognizerStateFailed != longPressGesture.state) {
            if ([longPressGesture isEqual:otherGestureRecognizer]) {
                return YES;
            }
            
            return NO;
        }
    }
    else if ([gestureRecognizer.view isKindOfClass:[UICollectionView class]]) {
        UICollectionView * collectionView = (UICollectionView *)gestureRecognizer.view;
        MLReorderableCollectionContainer * reorderableCollection = [self reorderableCollectionWithCollectionView:collectionView];
        UILongPressGestureRecognizer * longPressGesture = reorderableCollection.longPressGesture;
        UIPanGestureRecognizer * panGesture = self.panGesture;
        
        if ([gestureRecognizer isEqual:longPressGesture]) {
            if ([panGesture isEqual:otherGestureRecognizer]) {
                return YES;
            }
        }
        else if ([gestureRecognizer isEqual:collectionView.panGestureRecognizer]) {
            if (UIGestureRecognizerStatePossible == longPressGesture.state ||
                UIGestureRecognizerStateFailed == longPressGesture.state) {
                return NO;
            }
        }
    }
    
    return YES;
}

#pragma mark Private Methods

- (MLReorderableCollectionContainer *)newReorderableCollectionWithCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    NSAssert([self containsCollectionView:collectionView], @"View container doesn't contains collection view as a child view.");
    MLReorderableCollectionContainer * reorderableCollection = [[MLReorderableCollectionContainer alloc] initWithCollectionView:collectionView];
    reorderableCollection.viewContainer = self.viewContainer;
    reorderableCollection.longPressGesture.delegate = self;
    return reorderableCollection;
}

- (BOOL)containsCollectionView:(UICollectionView *)collectionView {
    NSParameterAssert(collectionView);
    UIView * viewContainer = self.viewContainer;
    BOOL containsCollectionView = NO;
    
    if (viewContainer) {
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

- (UICollectionView *)collectionViewAtPoint:(CGPoint)point {
    __block UICollectionView * collectionView = nil;
    [self.arrayOfReorderableCollections enumerateObjectsUsingBlock:^(MLReorderableCollectionContainer * obj, NSUInteger idx, BOOL *stop) {
        CGRect visibleRect = CGRectZero;
        visibleRect.origin = obj.collectionView.contentOffset;
        visibleRect.size = obj.collectionView.frame.size;
        CGRect collectionViewRect = [obj.collectionView convertRect:visibleRect toView:obj.viewContainer];
        
        if (CGRectContainsPoint(collectionViewRect, point)) {
            collectionView = obj.collectionView;
            *stop = YES;
        }
    }];
    
    return collectionView;
}

@end
