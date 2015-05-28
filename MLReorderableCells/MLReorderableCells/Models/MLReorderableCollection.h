//
//  MLReorderableCollection.h
//  MLReorderableCells
//
//  Created by Joachim Kret on 20.05.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol MLReorderableCollectionDelegate <NSObject>

@optional
// Dragging delegates
- (void)collectionView:(UICollectionView *)collectionView willBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView didBeginDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView willEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionView:(UICollectionView *)collectionView didEndDraggingItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@protocol MLReorderableCollectionDataSource <NSObject>

@optional
// Reorder data source
- (BOOL)collectionView:(UICollectionView *)collectionView canReorderItemAtIndexPath:(NSIndexPath *)indexPath;
- (UIView *)reorderableCollectionContainerForCollectionView:(UICollectionView *)collectionView;
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

@end

@interface MLReorderableCollection : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, readonly, strong) UICollectionView * collectionView;
@property (nonatomic, readonly, strong) UILongPressGestureRecognizer * longPressGesture;
@property (nonatomic, readonly, strong) UIPanGestureRecognizer * panGesture;
@property (nonatomic, readwrite, weak) id <MLReorderableCollectionDelegate> delegate;
@property (nonatomic, readwrite, weak) id <MLReorderableCollectionDataSource> dataSource;

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView NS_DESIGNATED_INITIALIZER;

@end
