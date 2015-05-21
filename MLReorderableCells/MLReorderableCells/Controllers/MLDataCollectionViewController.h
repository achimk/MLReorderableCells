//
//  MLDataCollectionViewController.h
//  MLReorderableCells
//
//  Created by Joachim Kret on 20.05.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLCollectionViewController.h"

@interface MLDataCollectionViewController : MLCollectionViewController

@property (nonatomic, readwrite, assign) BOOL canReorderItems;
@property (nonatomic, readwrite, assign) BOOL canMoveItems;
@property (nonatomic, readwrite, assign) BOOL canReplaceItems;

@end
