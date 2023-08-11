//
//  DepthFromCameraRollViewController.swift
//
//  Created by Shuichi Tsutsumi on 2018/08/22.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import Photos

class DepthFromCameraRollViewController: DepthImagePickableViewController {

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
                self.loadImage(at: url)
            default:
                fatalError()
            }
        })
    }

    override func loadImage(at url: URL) {
        let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)!
        processImageSource(imageSource)
        guard let image = UIImage(contentsOfFile: url.path) else { fatalError() }
        self.image = image

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            typeSegmentedCtl.selectedSegmentIndex = 0
        }
        drawImage(image)
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
    
    private func processImageSource(_ imageSource: CGImageSource) {
        self.disparityPixelBuffer = imageSource.getDisparityData()?.depthDataMap
        self.depthPixelBuffer = imageSource.getDepthData()?.depthDataMap
    }
    
    private func updateView() {
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
        updateView()
    }
}
