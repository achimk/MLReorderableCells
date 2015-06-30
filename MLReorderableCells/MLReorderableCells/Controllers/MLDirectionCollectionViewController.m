//
//  MLDirectionCollectionViewController.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 30.06.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLDirectionCollectionViewController.h"

#pragma mark - MLDirectionCollectionViewController

@interface MLDirectionCollectionViewController ()

@end

#pragma mark -

@implementation MLDirectionCollectionViewController

#pragma mark View

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.appearsFirstTime) {
        [self randomAction:nil];
    }
}

#pragma mark Accessors

- (BOOL)isVertical {
    UICollectionViewFlowLayout * flowLayout = (id)self.collectionViewLayout;
    return (UICollectionViewScrollDirectionVertical == flowLayout.scrollDirection);
}

- (BOOL)isHorizontal {
    UICollectionViewFlowLayout * flowLayout = (id)self.collectionViewLayout;
    return (UICollectionViewScrollDirectionHorizontal == flowLayout.scrollDirection);
}

@end
