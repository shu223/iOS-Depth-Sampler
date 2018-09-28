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
import SwiftAssetsPickerController

class PointCloudlViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var typeSegmentedCtl: UISegmentedControl!

    private var image: UIImage?
    private var depthData: AVDepthData?

    @IBOutlet weak var scnView: SCNView!
    private let scene = SCNScene()
    private var pointNode: SCNNode!

    private let zCamera: Float = 0.3
    
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
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.0
        cameraNode.camera?.zFar = 10.0
        scene.rootNode.addChildNode(cameraNode)
        
        cameraNode.position = SCNVector3(x: 0, y: 0, z: zCamera)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 3, z: 3)
        scene.rootNode.addChildNode(lightNode)
        
        let sphere = SCNSphere(radius: 0.001)
        sphere.firstMaterial?.diffuse.contents = UIColor.blue
        pointNode = SCNNode(geometry: sphere)
        
        
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.black
    }
    
    private func loadImage(at url: URL) {
        let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)!
        depthData = imageSource.getDisparityData()
//        depthData = imageSource.getDepthData()
        guard let image = UIImage(contentsOfFile: url.path) else { fatalError() }
        self.image = image
        drawImage(image)
    }
    
    private func loadAsset(_ asset: PHAsset) {
        asset.requestColorImage { image in
            self.image = image
            self.update()
        }
        asset.requestContentEditingInput(with: nil) { contentEditingInput, info in
            let imageSource = contentEditingInput!.createImageSource()
            self.depthData = imageSource.getDisparityData()
        }
    }
    
    private func drawImage(_ image: UIImage?) {
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
    
    private func drawPointCloud() {
        guard let colorImage = image, let cgColorImage = colorImage.cgImage else { fatalError() }
        guard let depthData = depthData else { fatalError() }
        
        let depthPixelBuffer = depthData.depthDataMap
        let width  = CVPixelBufferGetWidth(depthPixelBuffer)
        let height = CVPixelBufferGetHeight(depthPixelBuffer)

        let resizeScale = CGFloat(width) / colorImage.size.width
        let resizedColorImage = CIImage(cgImage: cgColorImage).transformed(by: CGAffineTransform(scaleX: resizeScale, y: resizeScale))
        guard let pixelDataColor = resizedColorImage.createCGImage().pixelData() else { fatalError() }

        // Applying Histogram Equalization
//        let depthImage = CIImage(cvPixelBuffer: depthPixelBuffer).applyingFilter("YUCIHistogramEqualization")
//        let context = CIContext(options: nil)
//        context.render(depthImage, to: depthPixelBuffer, bounds: depthImage.extent, colorSpace: nil)

        let pixelDataDepth: [Float32]
        pixelDataDepth = depthPixelBuffer.grayPixelData()
        
        // Sometimes the z values of the depth are bigger than the camera's z
        // So, determine a z scale factor to make it visible
        let zMax = pixelDataDepth.max()!
        let zNear = zCamera - 0.2
        let zScale = zMax > zNear ? zNear / zMax : 1.0
        print("z scale: \(zScale)")
        let xyScale: Float = 0.0002

        let pointCloud: [SCNVector3] = pixelDataDepth.enumerated().map {
            let index = $0.offset
            // Adjusting scale and translating to the center
            let x = Float(index % width - width / 2) * xyScale
            let y = Float(height / 2 - index / width) * xyScale
            // z comes as Float32 value
            let z = Float($0.element) * zScale
            return SCNVector3(x, y, z)
        }

        // Draw as a custom geometry
        let pc = PointCloud()
        pc.pointCloud = pointCloud
        pc.colors = pixelDataColor
        let pcNode = pc.pointCloudNode()
        pcNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(pcNode)
//        pcNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))

        // Draw with Sphere nodes
//        pointCloud.enumerated().forEach {
//            let index = $0.offset * 4
//            let r = pixelDataColor[index]
//            let g = pixelDataColor[index + 1]
//            let b = pixelDataColor[index + 2]
//
//            let pos = $0.element
//            // reducing the points
//            guard Int(pos.x / scale) % 10 == 0 else { return }
//            guard Int(pos.y / scale) % 10 == 0 else { return }
//            let clone = pointNode.clone()
//            clone.position = SCNVector3(pos.x, pos.y, pos.z)
//
//            // Creating a new geometry and a new material to color for each
//            // https://stackoverflow.com/questions/39902802/stop-sharing-nodes-geometry-with-its-clone-programmatically
//            guard let newGeometry = pointNode.geometry?.copy() as? SCNGeometry else { fatalError() }
//            guard let newMaterial = newGeometry.firstMaterial?.copy() as? SCNMaterial else { fatalError() }
//            newMaterial.diffuse.contents = UIColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
//            newGeometry.materials = [newMaterial]
//            clone.geometry = newGeometry
//
//            scene.rootNode.addChildNode(clone)
//        }
    }
    
    private func update() {
        scene.rootNode.childNodes.forEach { childNode in
            childNode.removeFromParentNode()
        }
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
    
    // MARK: - Actions

    @IBAction func typeSegmentChanged(_ sender: UISegmentedControl) {
        update()
    }
    
    @IBAction func pickerBtnTapped() {
        let picker = AssetsPickerController()
        picker.didSelectAssets = {(assets: Array<PHAsset?>) -> () in
            guard let asset_ = assets.first, let asset = asset_ else { return }
            self.loadAsset(asset)
            self.typeSegmentedCtl.selectedSegmentIndex = 0
        }
        let navigationController = UINavigationController(rootViewController: picker)
        present(navigationController, animated: true, completion: nil)
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

    func grayPixelData() -> [Float32] {
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        var pixelData = [Float32](repeating: 0, count: Int(width * height))
        for yMap in 0 ..< height {
            let rowData = CVPixelBufferGetBaseAddress(self)! + yMap * CVPixelBufferGetBytesPerRow(self)
            let data = UnsafeMutableBufferPointer<Float>(start: rowData.assumingMemoryBound(to: Float.self), count: width)
            for index in 0 ..< width {
                // ???: index/2しないと同じ画像が2回繰り返す感じで読まれる。ピクセルの読み方を何か勘違いしてるかもしれない
                pixelData[index +  width * yMap] = Float32(data[index / 2])
            }
        }
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        return pixelData
    }
}
