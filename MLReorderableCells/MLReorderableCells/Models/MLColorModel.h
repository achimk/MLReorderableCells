//
//  MLColorModel.h
//  MLReorderableCells
//
//  Created by Joachim Kret on 20.05.2015.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MLColorModel : NSObject

@property (nonatomic, readonly, copy) NSString * identifier;
@property (nonatomic, readonly, copy) UIColor * color;

+ (instancetype)model;

- (instancetype)initWithColor:(UIColor *)color;
- (instancetype)initWithIdentifier:(NSString *)identifier color:(UIColor *)color;

@end
