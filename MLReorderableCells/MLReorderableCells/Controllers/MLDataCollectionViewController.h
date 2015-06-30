//
//  MLDataCollectionViewController.h
//  MLReorderableCells
//
//  Created by Joachim Kret on 20.05.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLColorsCollectionViewController.h"

@interface MLDataCollectionViewController : MLColorsCollectionViewController

@property (nonatomic, readwrite, assign) BOOL useMainContainer;
@property (nonatomic, readwrite, assign) BOOL canReorderItems;
@property (nonatomic, readwrite, assign) BOOL canInsertItems;
@property (nonatomic, readwrite, assign) BOOL canDeleteItems;
@property (nonatomic, readwrite, assign) BOOL canReplaceItems;
@property (nonatomic, readwrite, assign) BOOL canMoveItems;

@end
