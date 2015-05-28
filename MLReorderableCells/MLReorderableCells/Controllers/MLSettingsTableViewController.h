//
//  MLSettingsTableViewController.h
//  MLReorderableCells
//
//  Created by Joachim Kret on 21.05.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLTableViewController.h"

typedef NS_ENUM(NSUInteger, MLOptions) {
    MLOptionUseMainContainer,
    MLOptionReorderItems,
    MLOptionInsertItems,
    MLOptionDeleteItems,
    MLOptionReplaceItems,
    MLOptionMoveItems,
    MLOptionCount
};

@class MLDataCollectionViewController;

@interface MLSettingsTableViewController : MLTableViewController

@property (nonatomic, readwrite, weak) MLDataCollectionViewController * collectionViewController;

- (instancetype)initWithCollectionViewController:(MLDataCollectionViewController *)collectionViewController NS_DESIGNATED_INITIALIZER;

@end
