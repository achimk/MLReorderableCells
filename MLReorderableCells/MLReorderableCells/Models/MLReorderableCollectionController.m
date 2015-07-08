//
//  MLReorderableCollectionController.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 08.07.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLReorderableCollectionController.h"

#pragma mark - MLReorderableCollectionController

@interface MLReorderableCollectionController ()

@property (nonatomic, readonly, strong) NSMutableArray * arrayOfCollectionViews;
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
#warning Implement!
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
#warning Implement!
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.panGesture isEqual:gestureRecognizer]) {
        CGPoint touchPoint = [self.panGesture locationOfTouch:0 inView:self.viewContainer];
        UICollectionView * collectionView = [self collectionViewAtPoint:touchPoint];
        
        if (!collectionView) {
            return NO;
        }
        
        if (UIGestureRecognizerStatePossible == self.longPressGesture.state ||
            UIGestureRecognizerStateFailed == self.longPressGesture.state) {
            return NO;
        }
    }
    else if ([self.longPressGesture isEqual:gestureRecognizer]) {
        CGPoint touchPoint = [self.longPressGesture locationOfTouch:0 inView:self.viewContainer];
        UICollectionView * collectionView = [self collectionViewAtPoint:touchPoint];
        
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
#warning Implement!
    return YES;
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

@end
