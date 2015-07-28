//
//  MLColorModel.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 20.05.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLColorModel.h"
#import <UIColor+MLPFlatColors/UIColor+MLPFlatColors.h>

#pragma mark - MLColorModel

@interface MLColorModel ()

@property (nonatomic, readwrite, copy) NSString * identifier;
@property (nonatomic, readwrite, copy) UIColor * color;

@end

#pragma mark -

@implementation MLColorModel

+ (instancetype)model {
    return [[MLColorModel alloc] init];
}

#pragma mark Init

- (instancetype)init {
    return [self initWithIdentifier:nil color:nil];
}

- (instancetype)initWithColor:(UIColor *)color {
    return [self initWithIdentifier:nil color:color];
}

- (instancetype)initWithIdentifier:(NSString *)identifier color:(UIColor *)color {
    if (self = [super init]) {
        _identifier = (identifier) ? [identifier copy] : [[[NSUUID UUID] UUIDString] copy];
        _color = (color) ? [color copy] : [[UIColor randomFlatColor] copy];
    }
    
    return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    MLColorModel * model = [[[self class] alloc] init];
    model.identifier = [self.identifier copy];
    model.color = [self.color copy];
    return model;
}

@end
