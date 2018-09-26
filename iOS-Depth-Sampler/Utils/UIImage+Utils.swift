//
//  UIImage+CVPixelBuffer.swift
//
//  Created by Shuichi Tsutsumi on 2018/08/28.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
//import VideoToolbox

extension UIImage {
    // https://github.com/hollance/CoreMLHelpers
//    NOTE: This only works for RGB pixel buffers, not for grayscale.
//    public convenience init?(pixelBuffer: CVPixelBuffer) {
//        var cgImage: CGImage?
//        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
//
//        if let cgImage = cgImage {
//            self.init(cgImage: cgImage)
//        } else {
//            return nil
//        }
//    }
//
//    /**
//     Creates a new UIImage from a CVPixelBuffer, using Core Image.
//     */
//    public convenience init?(pixelBuffer: CVPixelBuffer, context: CIContext) {
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        let rect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer),
//                          height: CVPixelBufferGetHeight(pixelBuffer))
//        if let cgImage = context.createCGImage(ciImage, from: rect) {
//            self.init(cgImage: cgImage)
//        } else {
//            return nil
//        }
//    }

    public convenience init?(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let imageRect:CGRect = CGRect(x: 0, y: 0, width: pixelBufferWidth, height: pixelBufferHeight)
        let ciContext = CIContext.init()
        guard let cgImage = ciContext.createCGImage(ciImage, from: imageRect) else {
            return nil
        }
        self.init(cgImage: cgImage)
    }

    func adjustedCIImage(targetSize: CGSize) -> CIImage? {
        guard let cgImage = cgImage else { fatalError() }
        
        let imageWidth = cgImage.width
        let imageHeight = cgImage.height
        
        // Video preview is running at 1280x720. Downscale background to same resolution
        let videoWidth = Int(targetSize.width)
        let videoHeight = Int(targetSize.height)
        
        let scaleX = CGFloat(imageWidth) / CGFloat(videoWidth)
        let scaleY = CGFloat(imageHeight) / CGFloat(videoHeight)
        
        let scale = min(scaleX, scaleY)
        
        // crop the image to have the right aspect ratio
        let cropSize = CGSize(width: CGFloat(videoWidth) * scale, height: CGFloat(videoHeight) * scale)
        let croppedImage = cgImage.cropping(to: CGRect(origin: CGPoint(
            x: (imageWidth - Int(cropSize.width)) / 2,
            y: (imageHeight - Int(cropSize.height)) / 2), size: cropSize))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil,
                                      width: videoWidth,
                                      height: videoHeight,
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                                        print("error")
                                        return nil
        }
        
        let bounds = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: videoWidth, height: videoHeight))
        context.clear(bounds)
        
        context.draw(croppedImage!, in: bounds)
        
        guard let scaledImage = context.makeImage() else {
            print("failed")
            return nil
        }
        
        return CIImage(cgImage: scaledImage)
    }
}
