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
        let targetType: OSType
        switch depthDataType {
        case kCVPixelFormatType_DisparityFloat16:
            targetType = kCVPixelFormatType_DepthFloat16
        case kCVPixelFormatType_DisparityFloat32:
            targetType = kCVPixelFormatType_DepthFloat32
        default:
            return self
        }
        return converting(toDepthDataType: targetType)
    }

    func convertToDisparity() -> AVDepthData {
        let targetType: OSType
        switch depthDataType {
        case kCVPixelFormatType_DepthFloat16:
            targetType = kCVPixelFormatType_DisparityFloat16
        case kCVPixelFormatType_DepthFloat32:
            targetType = kCVPixelFormatType_DisparityFloat32
        default:
            return self
        }
        return converting(toDepthDataType: targetType)
    }
}
