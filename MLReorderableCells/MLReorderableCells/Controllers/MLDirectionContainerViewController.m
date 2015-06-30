//
//  MLDirectionContainerViewController.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 30.06.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLDirectionContainerViewController.h"

#pragma mark - MLDirectionContainerViewController

@interface MLDirectionContainerViewController ()

@property (nonatomic, readwrite, weak) IBOutlet UIView * viewSeparator;

@end

#pragma mark -

@implementation MLDirectionContainerViewController

#pragma mark View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.viewSeparator.backgroundColor = [UIColor lightGrayColor];
}

@end
