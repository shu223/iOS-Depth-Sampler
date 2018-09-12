//
//  PhotosUtils.swift
//  iOS-Depth-Sampler
//
//  Created by Shuichi Tsutsumi on 2018/09/12.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import Photos

extension PHAsset {
    class func fetchAssetsWithDepth() -> [PHAsset] {
        let resultCollections = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumDepthEffect,
            options: nil)
        var assets: [PHAsset] = []
        resultCollections.enumerateObjects({ collection, index, stop in
            let result = PHAsset.fetchAssets(in: collection, options: nil)
            result.enumerateObjects({ asset, index, stop in
                assets.append(asset)
            })
        })
        return assets
    }
    
    func requestColorImage(handler: @escaping (UIImage?) -> Void) {
        PHImageManager.default().requestImage(for: self, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFit, options: nil) { (image, info) in
            handler(image)
        }
    }
    
    func hasPortraitMatte() -> Bool {
        var result: Bool = false
        let semaphore = DispatchSemaphore(value: 0)
        requestContentEditingInput(with: nil) { contentEditingInput, info in
            let imageSource = contentEditingInput?.createImageSource()
            result = imageSource?.getMatteData() != nil
            semaphore.signal()
        }
        semaphore.wait()
        return result
    }
}

extension PHContentEditingInput {
    func createDepthImage() -> CIImage {
        guard let url = fullSizeImageURL else { fatalError() }
        return CIImage(contentsOf: url, options: [CIImageOption.auxiliaryDisparity : true])!
    }
    
    func createImageSource() -> CGImageSource {
        guard let url = fullSizeImageURL else { fatalError() }
        return CGImageSourceCreateWithURL(url as CFURL, nil)!
    }
}
