//
//  YUCIFilmBurnTransition.h
//  Pods
//
//  Created by YuAo on 22/05/2017.
//
//

#import <CoreImage/CoreImage.h>

@interface YUCIFilmBurnTransition : CIFilter

@property (nonatomic, strong, nullable) CIImage *inputImage;
@property (nonatomic, strong, nullable) CIImage *inputTargetImage;

@property (nonatomic, copy, nullable) CIVector *inputExtent;

@property (nonatomic, copy, null_resettable) NSNumber *inputTime; /* 0 to 1 */

@end
