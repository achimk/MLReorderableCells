//
//  MLColorsCollectionViewController.h
//  MLReorderableCells
//
//  Created by Joachim Kret on 30.06.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLCollectionViewController.h"
#import <RZCollectionList/RZCollectionList.h>
#import "MLColorModel.h"

@interface MLColorsCollectionViewController : MLCollectionViewController

@property (nonatomic, readonly, strong) RZArrayCollectionList * resultsController;

- (IBAction)addAction:(id)sender;
- (IBAction)clearAction:(id)sender;
- (IBAction)randomAction:(id)sender;

@end
