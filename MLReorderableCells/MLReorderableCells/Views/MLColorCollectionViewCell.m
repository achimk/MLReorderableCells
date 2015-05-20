//
//  MLColorCollectionViewCell.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 20.05.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLColorCollectionViewCell.h"
#import "MLColorModel.h"

@implementation MLColorCollectionViewCell

#pragma mark Initialize

- (void)finishInitialize {
    self.backgroundView = [[UIView alloc] init];
    self.backgroundView.backgroundColor = [UIColor blackColor];
}

#pragma mark Reuse

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.backgroundView.backgroundColor = [UIColor blackColor];
}

#pragma mark Cell Configuration

- (void)configureWithObject:(id)anObject context:(id)context {
    MLColorModel * model = (MLColorModel *)anObject;
    self.backgroundView.backgroundColor = model.color;
}

@end
