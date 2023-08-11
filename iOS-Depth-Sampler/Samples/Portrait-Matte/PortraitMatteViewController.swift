//
//  DepthFromCameraRollViewController.swift
//
//  Created by Shuichi Tsutsumi on 2018/08/22.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import Photos

class PortraitMatteViewController: DepthImagePickableViewController {

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
    
    override func loadImage(at url: URL) {
        imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)!
        getPortraitMatte()
        guard let image = UIImage(contentsOfFile: url.path) else { fatalError() }
        self.image = image

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            typeSegmentedCtl.selectedSegmentIndex = 0
        }
        drawImage(image)
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
    
    private func updateView() {
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
        updateView()
    }
}
