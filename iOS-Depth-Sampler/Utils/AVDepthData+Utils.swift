//
//  AVDepthData+Utils.swift
//  iOS-Depth-Sampler
//
//  Created by Shuichi Tsutsumi on 2018/09/12.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import AVFoundation

extension AVDepthData {
    
    func convertToDepth() -> AVDepthData {
        switch depthDataType {
        case kCVPixelFormatType_DisparityFloat16:
            return converting(toDepthDataType: kCVPixelFormatType_DepthFloat16)
        case kCVPixelFormatType_DisparityFloat32:
            return converting(toDepthDataType: kCVPixelFormatType_DepthFloat32)
        default:
            return self
        }
    }

    func convertToDisparity() -> AVDepthData {
        switch depthDataType {
        case kCVPixelFormatType_DepthFloat16:
            return converting(toDepthDataType: kCVPixelFormatType_DisparityFloat16)
        case kCVPixelFormatType_DepthFloat32:
            return converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
        default:
            return self
        }
    }
}
