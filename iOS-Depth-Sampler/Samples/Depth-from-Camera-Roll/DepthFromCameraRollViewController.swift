//
//  DepthFromCameraRollViewController.swift
//
//  Created by Shuichi Tsutsumi on 2018/08/22.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import Photos
import SwiftAssetsPickerController

class DepthFromCameraRollViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var typeSegmentedCtl: UISegmentedControl!

    private var image: UIImage?
    private var disparityPixelBuffer: CVPixelBuffer?
    private var depthPixelBuffer: CVPixelBuffer?

    override func viewDidLoad() {
        super.viewDidLoad()

        PHPhotoLibrary.requestAuthorization({ status in
            switch status {
            case .authorized:
                let url = Bundle.main.url(forResource: "image-with-depth", withExtension: "jpg")!
                let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)!
                self.getDisparity(from: imageSource)
                self.getDepth(from: imageSource)
                guard let image = UIImage(contentsOfFile: url.path) else { fatalError() }
                self.image = image
                self.drawImage(image)
            default:
                fatalError()
            }
        })
    }
    
    private func drawImage(_ image: UIImage?) {
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
    
    private func draw(pixelBuffer: CVPixelBuffer?) {
        var image: UIImage? = nil
        if let pixelBuffer = pixelBuffer {
            if let depthMapImage = UIImage(pixelBuffer: pixelBuffer) {
                image = depthMapImage
            }
            // Histogram Equalization
//            if let cgImage = image?.cgImage {
//                var ciImage = CIImage(cgImage: cgImage)
//                ciImage = ciImage.applyingFilter("YUCIHistogramEqualization")
//                image = UIImage(ciImage: ciImage)
//            }
        }
        drawImage(image)
    }
    
    private func getDisparity(from imageSource: CGImageSource) {
        var depthDataMap: CVPixelBuffer? = nil
        if let disparityData = imageSource.getDisparityData() {
            depthDataMap = disparityData.depthDataMap
        } else if let depthData = imageSource.getDepthData() {
            // Depthの場合はDisparityに変換
            depthDataMap = depthData.convertToDisparity().depthDataMap
        }
        disparityPixelBuffer = depthDataMap
    }

    private func getDepth(from imageSource: CGImageSource) {
        var depthDataMap: CVPixelBuffer? = nil
        if let depthData = imageSource.getDepthData() {
            depthDataMap = depthData.depthDataMap
        } else if let depthData = imageSource.getDisparityData() {
            // Disparityの場合はDepthに変換
            depthDataMap = depthData.convertToDepth().depthDataMap
        }
        depthPixelBuffer = depthDataMap
    }

    private func update() {
        switch typeSegmentedCtl.selectedSegmentIndex {
        case 0:
            drawImage(image)
        case 1:
            draw(pixelBuffer: disparityPixelBuffer)
        case 2:
            draw(pixelBuffer: depthPixelBuffer)
        default:
            fatalError()
        }
    }
    
    // MARK: - Actions

    @IBAction func typeSegmentChanged(_ sender: UISegmentedControl) {
        update()
    }
    
    @IBAction func pickerBtnTapped() {
        let rootListAssets = AssetsPickerController()
        rootListAssets.didSelectAssets = {(assets: Array<PHAsset?>) -> () in
            guard let asset_ = assets.first, let asset = asset_ else { return }
            asset.requestColorImage { image in
                self.image = image
                self.drawImage(image)
            }
            asset.requestContentEditingInput(with: nil) { contentEditingInput, info in
                let imageSource = contentEditingInput!.createImageSource()
                self.getDisparity(from: imageSource)
                self.getDepth(from: imageSource)
            }
            self.typeSegmentedCtl.selectedSegmentIndex = 0
        }
        let navigationController = UINavigationController(rootViewController: rootListAssets)
        present(navigationController, animated: true, completion: nil)
    }
}
