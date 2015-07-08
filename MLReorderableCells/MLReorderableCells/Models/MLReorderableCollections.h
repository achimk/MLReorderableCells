//
//  MLReorderableCollections.h
//  MLReorderableCells
//
//  Created by Joachim Kret on 08.07.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MLReorderableCollection.h"

@interface MLReorderableCollections : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, readonly, strong) UIView * viewContainer;

- (instancetype)initWithContainerView:(UIView *)viewContainer NS_DESIGNATED_INITIALIZER;

- (MLReorderableCollection *)addCollectionView:(UICollectionView *)collectionView;
- (MLReorderableCollection *)removeCollectionView:(UICollectionView *)collectionView;

@end
