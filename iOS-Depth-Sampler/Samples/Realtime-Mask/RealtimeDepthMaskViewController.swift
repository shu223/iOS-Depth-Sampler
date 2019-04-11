//
//  RealtimeDepthViewController.swift
//
//  Created by Shuichi Tsutsumi on 2018/08/20.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import MetalKit
import AVFoundation

class RealtimeDepthMaskViewController: UIViewController {

    @IBOutlet weak var mtkView: MTKView!
    @IBOutlet weak var segmentedCtl: UISegmentedControl!
    @IBOutlet weak var binarizeSwitch: UISwitch!
    @IBOutlet weak var filterSwitch: UISwitch!
    @IBOutlet weak var gammaSwitch: UISwitch!

    private var videoCapture: VideoCapture!
    private var currentCameraType: CameraType = .front(true)
    private let serialQueue = DispatchQueue(label: "com.shu223.iOS-Depth-Sampler.queue")
    private var currentCaptureSize: CGSize = CGSize.zero

    private var renderer: MetalRenderer!
    
    private var bgUIImages: [UIImage] = []
    private var bgImages: [CIImage] = []
    private var bgImageIndex: Int = 0
    private var videoImage: CIImage?
    private var maskImage: CIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for index in 1...24 {
            let filename = String(format: "burn%06d", index)
            let image = UIImage(named: filename)!
            bgUIImages.append(image)
        }
        
        let device = MTLCreateSystemDefaultDevice()!
        mtkView.device = device
        mtkView.backgroundColor = UIColor.clear
        mtkView.delegate = self

        renderer = MetalRenderer(metalDevice: device, renderDestination: mtkView)

        videoCapture = VideoCapture(cameraType: currentCameraType,
                                    preferredSpec: nil,
                                    previewContainer: nil)
        
        videoCapture.syncedDataBufferHandler = { [weak self] videoPixelBuffer, depthData, face in
            guard let self = self else { return }
            
            self.videoImage = CIImage(cvPixelBuffer: videoPixelBuffer)
            
            let videoWidth = CVPixelBufferGetWidth(videoPixelBuffer)
            let videoHeight = CVPixelBufferGetHeight(videoPixelBuffer)
            
            let captureSize = CGSize(width: videoWidth, height: videoHeight)
            guard self.currentCaptureSize == captureSize else {
                // Update the images' size
                self.bgImages.removeAll()
                self.bgImages = self.bgUIImages.map {
                    return $0.adjustedCIImage(targetSize: captureSize)!
                }
                self.currentCaptureSize = captureSize
                return
            }

            DispatchQueue.main.async(execute: {
                let binarize = self.binarizeSwitch.isOn
                let gamma = self.gammaSwitch.isOn
                self.serialQueue.async {
                    guard let depthPixelBuffer = depthData?.depthDataMap else { return }
                    self.processBuffer(videoPixelBuffer: videoPixelBuffer, depthPixelBuffer: depthPixelBuffer, face: face, shouldBinarize: binarize, shouldGamma: gamma)
                }
            })
        }

        videoCapture.setDepthFilterEnabled(filterSwitch.isOn)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let videoCapture = videoCapture else {return}
        videoCapture.startCapture()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let videoCapture = videoCapture else {return}
        videoCapture.resizePreview()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard let videoCapture = videoCapture else {return}
        videoCapture.imageBufferHandler = nil
        videoCapture.stopCapture()
        mtkView.delegate = nil
        super.viewWillDisappear(animated)
    }
    
    @IBAction func cameraSwitchBtnTapped(_ sender: UIButton) {
        switch currentCameraType {
        case .back:
            currentCameraType = .front(true)
        case .front:
            currentCameraType = .back(true)
        }
        bgImageIndex = 0
        videoCapture.changeCamera(with: currentCameraType)
    }
    
    @IBAction func filterSwitched(_ sender: UISwitch) {
        videoCapture.setDepthFilterEnabled(sender.isOn)
    }
}

extension RealtimeDepthMaskViewController {
    private func readDepth(from depthPixelBuffer: CVPixelBuffer, at position: CGPoint, scaleFactor: CGFloat) -> Float {
        let pixelX = Int((position.x * scaleFactor).rounded())
        let pixelY = Int((position.y * scaleFactor).rounded())
        
        CVPixelBufferLockBaseAddress(depthPixelBuffer, .readOnly)
        
        let rowData = CVPixelBufferGetBaseAddress(depthPixelBuffer)! + pixelY * CVPixelBufferGetBytesPerRow(depthPixelBuffer)
        let faceCenterDepth = rowData.assumingMemoryBound(to: Float32.self)[pixelX]
        CVPixelBufferUnlockBaseAddress(depthPixelBuffer, .readOnly)
        
        return faceCenterDepth
    }
    
    func processBuffer(videoPixelBuffer: CVPixelBuffer, depthPixelBuffer: CVPixelBuffer, face: AVMetadataObject?, shouldBinarize: Bool, shouldGamma: Bool) {
        let videoWidth = CVPixelBufferGetWidth(videoPixelBuffer)
        let depthWidth = CVPixelBufferGetWidth(depthPixelBuffer)
        
        var depthCutOff: Float = 1.0
        if let face = face {
            let faceCenter = CGPoint(x: face.bounds.midX, y: face.bounds.midY)
            let scaleFactor = CGFloat(depthWidth) / CGFloat(videoWidth)
            let faceCenterDepth = readDepth(from: depthPixelBuffer, at: faceCenter, scaleFactor: scaleFactor)
            depthCutOff = faceCenterDepth + 0.25
        }
        
        // 二値化
        // Convert depth map in-place: every pixel above cutoff is converted to 1. otherwise it's 0
        if shouldBinarize {
            depthPixelBuffer.binarize(cutOff: depthCutOff)
        }
        
        // Create the mask from that pixel buffer.
        let depthImage = CIImage(cvPixelBuffer: depthPixelBuffer, options: [:])
        
        // Smooth edges to create an alpha matte, then upscale it to the RGB resolution.
        let alphaUpscaleFactor = Float(CVPixelBufferGetWidth(videoPixelBuffer)) / Float(depthWidth)
        let processedDepth: CIImage
        processedDepth = shouldGamma ? depthImage.applyBlurAndGamma() : depthImage

        self.maskImage = processedDepth.applyingFilter("CIBicubicScaleTransform", parameters: ["inputScale": alphaUpscaleFactor])
    }
}

extension CVPixelBuffer {
    
    func binarize(cutOff: Float) {
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        for yMap in 0 ..< height {
            let rowData = CVPixelBufferGetBaseAddress(self)! + yMap * CVPixelBufferGetBytesPerRow(self)
            let data = UnsafeMutableBufferPointer<Float32>(start: rowData.assumingMemoryBound(to: Float32.self), count: width)
            for index in 0 ..< width {
                let depth = data[index]
                if depth.isNaN {
                    data[index] = 1.0
                } else if depth <= cutOff {
                    // 前景
                    data[index] = 1.0
                } else {
                    // 背景
                    data[index] = 0.0
                }
            }
        }
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    }
}

extension CIImage {
    func applyBlurAndGamma() -> CIImage {
        return clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 3.0])
            .applyingFilter("CIGammaAdjust", parameters: ["inputPower": 0.5])
            .cropped(to: extent)
    }
}

extension RealtimeDepthMaskViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        switch segmentedCtl.selectedSegmentIndex {
        case 0:
            // original
            if let image = videoImage {
                renderer.update(with: image)
            }
        case 1:
            // depth
            if let image = maskImage {
                renderer.update(with: image)
            }
        case 2:
            // blended
            guard let image = videoImage, let maskImage = maskImage else { return }

            var parameters = ["inputMaskImage": maskImage]

            let index = self.bgImageIndex
            let bgImage = self.bgImages[index]
            parameters["inputBackgroundImage"] = bgImage
            self.bgImageIndex = index == self.bgImages.count - 1 ? 0 : index + 1
            
            let outputImage = image.applyingFilter("CIBlendWithMask", parameters: parameters)
            renderer.update(with: outputImage)
        default:
            return
        }
    }
}
