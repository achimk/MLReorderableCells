//
//  MLFlowLayout.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 20.05.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLFlowLayout.h"

@implementation MLFlowLayout

#pragma mark Init

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self finishInitialize];
    }
    
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [self finishInitialize];
    }
    
    return self;
}

- (void)finishInitialize {
    self.scrollDirection = UICollectionViewScrollDirectionVertical;
    self.minimumInteritemSpacing = 20.0f;
    self.minimumLineSpacing = 20.0f;
    self.itemSize = CGSizeMake(200.0f, 200.0f);
    self.sectionInset = UIEdgeInsetsMake(20.0f, 20.0f, 20.0f, 20.0f);
}

@end
