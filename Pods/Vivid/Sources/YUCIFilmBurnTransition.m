//
//  YUCIFilmBurnTransition.m
//  Pods
//
//  Created by YuAo on 22/05/2017.
//
//

#import "YUCIFilmBurnTransition.h"
#import "YUCIFilterConstructor.h"

@implementation YUCIFilmBurnTransition

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            if ([CIFilter respondsToSelector:@selector(registerFilterName:constructor:classAttributes:)]) {
                [CIFilter registerFilterName:NSStringFromClass([YUCIFilmBurnTransition class])
                                 constructor:[YUCIFilterConstructor constructor]
                             classAttributes:@{kCIAttributeFilterCategories: @[kCICategoryStillImage,kCICategoryVideo,kCICategoryTransition],
                                               kCIAttributeFilterDisplayName: @"Film Burn Transition"}];
            }
        }
    });
}

+ (CIKernel *)filterKernel {
    static CIKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *kernelString = [[NSString alloc] initWithContentsOfURL:[[NSBundle bundleForClass:self] URLForResource:NSStringFromClass([YUCIFilmBurnTransition class]) withExtension:@"cikernel"] encoding:NSUTF8StringEncoding error:nil];
        kernel = [CIKernel kernelWithString:kernelString];
    });
    return kernel;
}

- (NSNumber *)inputTime {
    if (!_inputTime) {
        _inputTime = @(0.0);
    }
    return _inputTime;
}

- (void)setDefaults {
    self.inputExtent = nil;
    self.inputTime = nil;
}

- (CIImage *)outputImage {
    if (!self.inputImage || !self.inputTargetImage) {
        return nil;
    }
    
    CIVector *defaultInputExtent = [CIVector vectorWithCGRect:CGRectUnion(self.inputImage.extent, self.inputTargetImage.extent)];
    CIVector *extent = self.inputExtent?:defaultInputExtent;
    return [[YUCIFilmBurnTransition filterKernel] applyWithExtent:extent.CGRectValue
                                                      roiCallback:^CGRect(int index, CGRect destRect) {
                                                          return extent.CGRectValue;
                                                      }
                                                        arguments:@[self.inputImage,self.inputTargetImage,extent,self.inputTime]];
}

@end
