//
//  MLReorderableCollection+Private.h
//  MLReorderableCells
//
//  Created by Joachim Kret on 07.07.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLReorderableCollection.h"

/**
 Available scroll directions for collection view
 */
typedef NS_ENUM(NSUInteger, MLScrollDirection) {
    MLScrollDirectionNone,
    MLScrollDirectionUp,
    MLScrollDirectionDown,
    MLScrollDirectionLeft,
    MLScrollDirectionRight
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

@property (nonatomic, readwrite, strong) UICollectionView * collectionView;
@property (nonatomic, readwrite, strong) UILongPressGestureRecognizer * longPressGesture;
@property (nonatomic, readwrite, strong) UIPanGestureRecognizer * panGesture;
@property (nonatomic, readwrite, assign) BOOL insideCollectionFrame;
@property (nonatomic, readwrite, strong) UIView * reorderableCollectionContainer;

- (void)addGesturesForCollectionView:(UICollectionView *)collectionView;
- (void)removeGesturesForCollectionView:(UICollectionView *)collectionView;

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer;

- (UIView *)reorderableCollectionContainer;

@end