//
//  MLReorderableCollectionAnimator.m
//  MLReorderableCells
//
//  Created by Joachim Kret on 05/08/15.
//  Copyright (c) 2015 Joachim Kret. All rights reserved.
//

#import "MLReorderableCollectionAnimator.h"

static const NSTimeInterval MLReorderableCollectionAnimationDuration    = 0.3f;
static const NSTimeInterval MLReorderableCollectionAnimationDelay       = 0.0f;
static const CGFloat MLReorderableCollectionScaleEnlarge                = 1.1f;
static const CGFloat MLReorderableCollectionScaleShrink                 = 0.01f;
static const CGFloat MLReorderableCollectionImageScale                  = 4.0f;

#pragma mark - MLReorderableCollectionAnimator

@implementation MLReorderableCollectionAnimator

+ (instancetype)animator {
    return [[[self class] alloc] init];
}

#pragma mark MLReorderableCollectionControllerAnimator

- (UIView *)viewPlaceholderFromCollectionViewCell:(UICollectionViewCell *)cell {
    NSParameterAssert(cell);
    UIView * viewPlaceholder = [[UIView alloc] initWithFrame:cell.bounds];
    viewPlaceholder.layer.shadowColor = [UIColor blackColor].CGColor;
    viewPlaceholder.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    viewPlaceholder.layer.shadowOpacity = 0.5f;
    viewPlaceholder.layer.shadowRadius = 3.0f;
    return viewPlaceholder;
}

- (void)collectionView:(UICollectionView *)collectionView beginsAnimationItemAtIndexPath:(NSIndexPath *)indexPath usingPlaceholder:(UIView *)viewPlaceholder completion:(void(^)(BOOL))completion {
    NSParameterAssert(collectionView);
    NSParameterAssert(indexPath);
    NSParameterAssert(viewPlaceholder);
    
    UIView * viewContainer = viewPlaceholder.superview;
    UICollectionViewCell * cell = [collectionView cellForItemAtIndexPath:indexPath];
    viewPlaceholder.frame = [cell convertRect:cell.bounds toView:viewContainer];
    
    cell.highlighted = YES;
    UIImageView * highlightedImageView = [self imageViewFromCollectionViewCell:cell];
    cell.highlighted = NO;
    UIImageView * normalImageView = [self imageViewFromCollectionViewCell:cell];
    
    [viewPlaceholder addSubview:normalImageView];
    [viewPlaceholder addSubview:highlightedImageView];
    
    [collectionView.collectionViewLayout invalidateLayout];
    
    [UIView animateWithDuration:MLReorderableCollectionAnimationDuration delay:MLReorderableCollectionAnimationDelay options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
        viewPlaceholder.transform = CGAffineTransformMakeScale(MLReorderableCollectionScaleEnlarge, MLReorderableCollectionScaleEnlarge);
        highlightedImageView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [highlightedImageView removeFromSuperview];
        
        if (completion) {
            completion(finished);
        }
    }];
}

- (void)collectionView:(UICollectionView *)collectionView endsAnimationItemAtIndexPath:(NSIndexPath *)indexPath usingPlaceholder:(UIView *)viewPlaceholder completion:(void(^)(BOOL))completion {
    NSParameterAssert(collectionView);
    NSParameterAssert(viewPlaceholder);
    
    UIView * viewContainer = viewPlaceholder.superview;
    CGRect frame = CGRectZero;
    
    if (indexPath) {
        UICollectionViewLayoutAttributes * attributes = [collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
        frame = [collectionView convertRect:attributes.frame toView:viewContainer];
    }
    
    [UIView animateWithDuration:MLReorderableCollectionAnimationDuration delay:MLReorderableCollectionAnimationDelay options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
        if (indexPath) {
            viewPlaceholder.transform = CGAffineTransformIdentity;
            viewPlaceholder.frame = frame;
        }
        else {
            viewPlaceholder.transform = CGAffineTransformMakeScale(MLReorderableCollectionScaleShrink, MLReorderableCollectionScaleShrink);
            viewPlaceholder.alpha = 0.0f;
        }
    } completion:^(BOOL finished) {
        if (completion) {
            completion(finished);
        }
    }];
}

- (void)collectionView:(UICollectionView *)fromCollectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath animatesToCollectionView:(UICollectionView *)toCollectionView indexPath:(NSIndexPath *)toIndexPath usingPlaceholder:(UIView *)viewPlaceholder completion:(void(^)(BOOL))completion {
    NSParameterAssert(fromCollectionView);
    NSParameterAssert(fromIndexPath);
    NSParameterAssert(toCollectionView);
    NSParameterAssert(toIndexPath);
    NSParameterAssert(viewPlaceholder);

    UICollectionViewCell * toCell = [toCollectionView cellForItemAtIndexPath:toIndexPath];
    for (UIView * subview in viewPlaceholder.subviews) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            UIImageView * imageView = (UIImageView *)subview;
            imageView.image = [self imageFromCollectionViewCell:toCell];
            break;
        }
    }
    
    UICollectionViewLayoutAttributes * toAttribs = [toCollectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:toIndexPath];
    CGRect frame = toAttribs.frame;
    frame.size.width *= MLReorderableCollectionScaleEnlarge;
    frame.size.height *= MLReorderableCollectionScaleEnlarge;
    CGPoint center = viewPlaceholder.center;
    
    [UIView animateKeyframesWithDuration:MLReorderableCollectionAnimationDuration delay:MLReorderableCollectionAnimationDelay options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
        viewPlaceholder.frame = frame;
        viewPlaceholder.center = center;
    } completion:^(BOOL finished) {
        if (completion) {
            completion(finished);
        }
    }];
}

#pragma mark Private Methods

- (UIImageView *)imageViewFromCollectionViewCell:(UICollectionViewCell *)cell {
    NSParameterAssert(cell);
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:cell.bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    imageView.image = [self imageFromCollectionViewCell:cell];
    return imageView;
}

- (UIImage *)imageFromCollectionViewCell:(UICollectionViewCell *)cell {
    NSParameterAssert(cell);
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, NO, MLReorderableCollectionImageScale);
    [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
