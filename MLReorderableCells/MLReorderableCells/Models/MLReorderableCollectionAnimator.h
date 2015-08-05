//
//  MLReorderableCollectionAnimator.h
//  MLReorderableCells
//
//  Created by Joachim Kret on 05/08/15.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLReorderableCollectionController.h"

@interface MLReorderableCollectionAnimator : NSObject <MLReorderableCollectionControllerAnimator>

+ (instancetype)animator;

@end
