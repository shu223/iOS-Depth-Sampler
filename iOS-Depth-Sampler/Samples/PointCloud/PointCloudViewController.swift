//
//  PointCloudlViewController.swift
//  iOS-Depth-Sampler
//
//  Created by Shuichi Tsutsumi on 2018/08/22.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import Photos
import SceneKit
import Accelerate
import PhotosUI

class PointCloudlViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var typeSegmentedCtl: UISegmentedControl!
    
    private var image: UIImage?
    private var depthData: AVDepthData?
    
    @IBOutlet weak var scnView: SCNView!
    private let scene = SCNScene()
    
    private var pointCloud: PointCloud?
    private var pointCloudNode: SCNNode?
    
    private let zCamera: Float = -0.1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        
        PHPhotoLibrary.requestAuthorization({ status in
            switch status {
            case .authorized:
                let url = Bundle.main.url(forResource: "image-with-depth", withExtension: "jpg")!
                self.loadImage(at: url)
            default:
                fatalError()
            }
        })
        
        update()
    }
    
    private func setupScene() {
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.black
        
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.zNear = 0.1
        cameraNode.camera = camera
        cameraNode.rotation = SCNVector4(1, 0, 0, Float.pi)
        scene.rootNode.addChildNode(cameraNode)
        
        cameraNode.position = SCNVector3(x: 0, y: 0, z: zCamera)
    }
    
    private func loadImage(at url: URL) {
        let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)!
        //        depthData = imageSource.getDisparityData()
        depthData = imageSource.getDepthData()
        guard let image = UIImage(contentsOfFile: url.path) else { fatalError() }
        self.image = image
        update()
    }

    private func drawImage(_ image: UIImage?) {
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
    
    private func convertRGBDtoXYZ(colorImage: CGImage, depthValues: [Float32], depthWidth: Int, cameraCalibrationData: AVCameraCalibrationData) -> [SCNVector3] {
        
        var intrinsics = cameraCalibrationData.intrinsicMatrix
        let referenceDimensions = cameraCalibrationData.intrinsicMatrixReferenceDimensions
        
        let ratio = Float(referenceDimensions.width) / Float(depthWidth)
        intrinsics.columns.0[0] /= ratio
        intrinsics.columns.1[1] /= ratio
        intrinsics.columns.2[0] /= ratio
        intrinsics.columns.2[1] /= ratio
        
        return depthValues.enumerated().map {
            let z = Float($0.element)
            let index = $0.offset
            let u = Float(index % depthWidth)
            let v = Float(index / depthWidth)
            
            let x = (u - intrinsics.columns.2[0]) * z / intrinsics.columns.0[0];
            let y = (v - intrinsics.columns.2[1]) * z / intrinsics.columns.1[1];
            
            return SCNVector3(x, y, z)
        }
    }
    
    private func drawPointCloud() {
        guard let colorImage = image, let cgColorImage = colorImage.cgImage else { return }
        guard let depthData = depthData else { return }
        
        let depthPixelBuffer = depthData.depthDataMap
        let depthWidth  = CVPixelBufferGetWidth(depthPixelBuffer)
        let resizeScale = CGFloat(depthWidth) / CGFloat(colorImage.size.width)
        let resizedColorImage = CIImage(cgImage: cgColorImage).transformed(by: CGAffineTransform(scaleX: resizeScale, y: resizeScale))
        guard let pixelDataColor = resizedColorImage.createCGImage().pixelData() else { fatalError() }
        
        let depthValues: [Float32] = depthPixelBuffer.depthValues()
        
        guard let cameraCalibrationData = depthData.cameraCalibrationData else { return }
        let points = convertRGBDtoXYZ(colorImage: cgColorImage, depthValues: depthValues, depthWidth: depthWidth, cameraCalibrationData: cameraCalibrationData)
        
        // 奥の方にある点群をカット
        //        let zFarthest = depthValues.max()!
        let zNearest = depthValues.min()!
        var reducedPoints: [SCNVector3] = []
        var reducedColors: [UInt8] = []
        points.enumerated().forEach {
            if abs($1.z) < zNearest + 1.0 {
                reducedPoints.append($1)
                
                reducedColors.append(pixelDataColor[$0 * 4])
                reducedColors.append(pixelDataColor[$0 * 4 + 1])
                reducedColors.append(pixelDataColor[$0 * 4 + 2])
                reducedColors.append(pixelDataColor[$0 * 4 + 3])
            }
        }
        
        // Draw as a custom geometry
        let pc = PointCloud()
        //        pc.points = points
        //        pc.colors = pixelDataColor
        pc.points = reducedPoints
        pc.colors = reducedColors
        let pcNode = pc.pointCloudNode()
        pcNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(pcNode)
        
        pointCloud = pc
        pointCloudNode = pcNode
    }

    private func update() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            pointCloudNode?.removeFromParentNode()

            switch typeSegmentedCtl.selectedSegmentIndex {
            case 0:
                scnView.isHidden = true
                drawImage(image)
            case 1:
                scnView.isHidden = false
                drawPointCloud()
            default:
                fatalError()
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func typeSegmentChanged(_ sender: UISegmentedControl) {
        update()
    }
    
    @IBAction func pickerBtnTapped() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .depthEffectPhotos
        configuration.selectionLimit = 1
//        configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
}

extension PointCloudlViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let provider = results.first?.itemProvider else { return }
        guard let typeIdentifier = provider.registeredContentTypes.contains(UTType.heic) ? UTType.heic.identifier :  provider.registeredTypeIdentifiers.first else { return }
        guard provider.hasItemConformingToTypeIdentifier(typeIdentifier) else { return }

        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] (url, error) in
            guard let self = self else { return }
            if let error = error {
                print("loadFileRepresentation failed with error: \(error)")
            }
            if let url = url {
                self.loadImage(at: url)
            }
        }

        picker.dismiss(animated: true, completion: nil)
    }
}

extension CGImage {

    func pixelData() -> [UInt8]? {
        guard let colorSpace = colorSpace else { return nil }
        
        let totalBytes = height * bytesPerRow
        var pixelData = [UInt8](repeating: 0, count: totalBytes)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue)
            else { fatalError() }
        context.draw(self, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
        
        return pixelData
    }
}

extension CVPixelBuffer {

    // デプスが16bitで得られていることを前提
    func depthValues() -> [Float32] {
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        var pixelData = [Float32](repeating: 0, count: Int(width * height))
        let baseAddress = CVPixelBufferGetBaseAddress(self)!
        guard
            CVPixelBufferGetPixelFormatType(self) == kCVPixelFormatType_DepthFloat16 ||
                CVPixelBufferGetPixelFormatType(self) == kCVPixelFormatType_DisparityFloat16
            else { fatalError() }

        // Float16という型がない（Floatは32bit）ので、UInt16として読み出す
        let data = UnsafeMutableBufferPointer<UInt16>(start: baseAddress.assumingMemoryBound(to: UInt16.self), count: width * height)
        for yMap in 0 ..< height {
            for index in 0 ..< width {
                let baseAddressIndex = index + yMap * width
                // UInt16として読みだした値をFloat32に変換する
                var f16Pixel = data[baseAddressIndex]  // Read as UInt16
                var f32Pixel = Float32(0.0)
                var src = vImage_Buffer(data: &f16Pixel, height: 1, width: 1, rowBytes: 2)
                var dst = vImage_Buffer(data: &f32Pixel, height: 1, width: 1, rowBytes: 4)
                vImageConvert_Planar16FtoPlanarF(&src, &dst, 0)
                
                // Float32の配列に格納
                pixelData[baseAddressIndex] = f32Pixel
            }
        }
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        return pixelData
    }
}
