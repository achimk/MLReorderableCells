//
//  MLDirectionCollectionViewController.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 30.06.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLDirectionCollectionViewController.h"

#define NUMBER_OF_INITIAL_ITEMS     3

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
        [self randomAction:@(NUMBER_OF_INITIAL_ITEMS)];
    }
}

@end
