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
}
