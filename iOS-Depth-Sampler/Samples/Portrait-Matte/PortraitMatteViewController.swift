//
//  DepthFromCameraRollViewController.swift
//
//  Created by Shuichi Tsutsumi on 2018/08/22.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import Photos
import SwiftAssetsPickerController

class PortraitMatteViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var typeSegmentedCtl: UISegmentedControl!

    private var image: UIImage?
    private var imageSource: CGImageSource? {
        didSet {
            let isEnabled = imageSource != nil
            DispatchQueue.main.async(execute: {
                self.typeSegmentedCtl.isEnabled = isEnabled
            })
        }
    }
    private var mattePixelBuffer: CVPixelBuffer?

    override func viewDidLoad() {
        super.viewDidLoad()

        resetControls()

        PHPhotoLibrary.requestAuthorization({ status in
            switch status {
            case .authorized:
                let url = Bundle.main.url(forResource: "image-with-matte", withExtension: "jpg")!
                self.loadImage(at: url)
            default:
                fatalError()
            }
        })
    }
    
    private func loadImage(at url: URL) {
        self.imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)!
        self.getPortraitMatte()
        guard let image = UIImage(contentsOfFile: url.path) else { fatalError() }
        self.image = image
        self.drawImage(image)
    }
    
    private func loadAsset(_ asset: PHAsset) {
        asset.requestColorImage { image in
            self.image = image
            self.drawImage(image)
        }
        asset.requestContentEditingInput(with: nil) { contentEditingInput, info in
            self.imageSource = contentEditingInput?.createImageSource()
            self.getPortraitMatte()
        }
    }
    
    private func showNoPortraitMatteAlert() {
        UIAlertController.showAlert(title: "No Portrait Matte", message: "This picture doesn't have portrait matte info. Plaease take a picture of a HUMAN with PORTRAIT mode.", on: self)
    }
    
    private func resetControls() {
        typeSegmentedCtl.isEnabled = false
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
        }
        drawImage(image)
    }
    
    private func getPortraitMatte() {
        var depthDataMap: CVPixelBuffer? = nil
        if let matteData = imageSource?.getMatteData() {
            depthDataMap = matteData.mattingImage
        }
        mattePixelBuffer = depthDataMap
    }
    
    private func update() {
        switch typeSegmentedCtl.selectedSegmentIndex {
        case 0:
            drawImage(image)
        case 1:
            guard let matte = mattePixelBuffer else {
                showNoPortraitMatteAlert()
                return
            }
            draw(pixelBuffer: matte)
        case 2:
            guard let cgOriginalImage = image?.cgImage else { return }
            guard let matte = mattePixelBuffer else {
                showNoPortraitMatteAlert()
                return
            }
            let orgImage = CIImage(cgImage: cgOriginalImage)
            let maskImage = CIImage(cvPixelBuffer: matte).resizeToSameSize(as: orgImage)
            let filter = CIFilter(name: "CIBlendWithMask", parameters: [
                kCIInputImageKey: orgImage,
                kCIInputMaskImageKey: maskImage])!
            let outputImage = filter.outputImage!
            drawImage(UIImage(ciImage: outputImage))
        default:
            fatalError()
        }
    }
    
    // MARK: - Actions

    @IBAction func typeSegmentChanged(_ sender: UISegmentedControl) {
        update()
    }
    
    @IBAction func pickerBtnTapped() {
        let picker = AssetsPickerController()
        picker.didSelectAssets = {(assets: Array<PHAsset?>) -> () in
            if let asset_ = assets.first, let asset = asset_ {
                self.loadAsset(asset)
                self.typeSegmentedCtl.selectedSegmentIndex = 0
            }
        }
        let navigationController = UINavigationController(rootViewController: picker)
        present(navigationController, animated: true, completion: nil)
    }
}
