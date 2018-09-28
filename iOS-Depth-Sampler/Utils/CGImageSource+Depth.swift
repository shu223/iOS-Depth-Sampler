//
//  CGImageSource+Depth.swift
//
//  Created by Shuichi Tsutsumi on 2018/08/30.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import ImageIO
import AVFoundation

extension CGImageSource {
    
    var auxiliaryDataProperties: [[String : AnyObject]]? {
        guard let sourceProperties = CGImageSourceCopyProperties(self, nil) as? [String: AnyObject] else { fatalError() }
        guard let fileContentsProperties = sourceProperties[String(kCGImagePropertyFileContentsDictionary)] as? [String : AnyObject] else { fatalError() }
        guard let images = fileContentsProperties[String(kCGImagePropertyImages)] as? [AnyObject] else { return nil }
        for imageProperties in images {
            guard let auxiliaryDataProperties = imageProperties[String(kCGImagePropertyAuxiliaryData)] as? [[String : AnyObject]] else { continue }
            return auxiliaryDataProperties
        }
        return nil
    }
    
    /* Depth data support for JPEG, HEIF, and DNG images.
     * The returned CFDictionary contains:
     *   - the depth data (CFDataRef) - (kCGImageAuxiliaryDataInfoData),
     *   - the depth data description (CFDictionary) - (kCGImageAuxiliaryDataInfoDataDescription)
     *   - metadata (CGImageMetadataRef) - (kCGImageAuxiliaryDataInfoMetadata)
     * CGImageSourceCopyAuxiliaryDataInfoAtIndex returns nil if the image did not contain ‘auxiliaryImageDataType’ data.
     */
    private var disparityDataInfo: [String : AnyObject]? {
        return CGImageSourceCopyAuxiliaryDataInfoAtIndex(self, 0, kCGImageAuxiliaryDataTypeDisparity) as? [String : AnyObject]
    }
    
    private var depthDataInfo: [String : AnyObject]? {
        return CGImageSourceCopyAuxiliaryDataInfoAtIndex(self, 0, kCGImageAuxiliaryDataTypeDepth) as? [String : AnyObject]
    }
    
    @available(iOS 12.0, *)
    private var portraitEffectsMatteDataInfo: [String : AnyObject]? {
        return CGImageSourceCopyAuxiliaryDataInfoAtIndex(self, 0, kCGImageAuxiliaryDataTypePortraitEffectsMatte) as? [String : AnyObject]
    }
    
    var disparityData: AVDepthData? {
        if let disparityDataInfo = disparityDataInfo {
            return try! AVDepthData(fromDictionaryRepresentation: disparityDataInfo)
        }
        return nil
    }
    
    var depthData: AVDepthData? {
        if let depthDataInfo = depthDataInfo {
            return try! AVDepthData(fromDictionaryRepresentation: depthDataInfo)
        }
        return nil
    }
    
    @available(iOS 12.0, *)
    func getMatteData() -> AVPortraitEffectsMatte? {
        if let info = portraitEffectsMatteDataInfo {
            return try? AVPortraitEffectsMatte(fromDictionaryRepresentation: info)
        }
        return nil
    }
    
    func getDisparityData() -> AVDepthData? {
        var data: AVDepthData? = nil
        if let disparityData = disparityData {
            data = disparityData
        } else if let depthData = depthData {
            data = depthData.convertToDisparity()
        }
        return data
    }

    func getDepthData() -> AVDepthData? {
        var data: AVDepthData? = nil
        if let depthData = depthData {
            data = depthData
        } else if let depthData = disparityData {
            data = depthData.convertToDepth()
        }
        return data
    }
}
