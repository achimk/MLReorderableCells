//
//  MLReorderableCollectionController.h
//  MLReorderableCells
//
//  Created by Joachim Kret on 08.07.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol MLReorderableCollectionControllerAnimator <NSObject>

@required
- (UIView *)viewPlaceholderFromCollectionViewCell:(UICollectionViewCell *)cell;
- (void)collectionView:(UICollectionView *)collectionView beginsAnimationItemAtIndexPath:(NSIndexPath *)indexPath usingPlaceholder:(UIView *)viewPlaceholder completion:(void(^)(BOOL))completion;
- (void)collectionView:(UICollectionView *)collectionView endsAnimationItemAtIndexPath:(NSIndexPath *)indexPath usingPlaceholder:(UIView *)viewPlaceholder completion:(void(^)(BOOL))completion;
- (void)collectionView:(UICollectionView *)fromCollectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath animatesToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath usingPlaceholder:(UIView *)viewPlaceholder completion:(void(^)(BOOL))completion;

@end

@protocol MLReorderableCollectionControllerDelegate <NSObject>

@optional
// Dragging delegates
- (void)collectionView:(UICollectionView *)collectionView willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@protocol MLReorderableCollectionControllerDataSource <NSObject>

@optional
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

@interface MLReorderableCollectionController : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, readonly, strong) UIView * viewContainer;
@property (nonatomic, readonly, strong) UICollectionView * currentCollectionView;
@property (nonatomic, readonly, strong) UILongPressGestureRecognizer * longPressGesture;
@property (nonatomic, readonly, strong) UIPanGestureRecognizer * panGesture;
@property (nonatomic, readwrite, weak) id <MLReorderableCollectionControllerDelegate> delegate;
@property (nonatomic, readwrite, weak) id <MLReorderableCollectionControllerDataSource> dataSource;
@property (nonatomic, readwrite, strong) id <MLReorderableCollectionControllerAnimator> animator;

- (instancetype)initWithViewContainer:(UIView *)viewContainer NS_DESIGNATED_INITIALIZER;

- (BOOL)addCollectionView:(UICollectionView *)collectionView;
- (BOOL)removeCollectionView:(UICollectionView *)collectionView;

@end
