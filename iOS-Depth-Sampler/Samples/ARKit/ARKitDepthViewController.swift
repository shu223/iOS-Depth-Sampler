//
//  ARKitDepthViewController.swift
//
//  Created by Shuichi Tsutsumi on 2018/08/08.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import ARKit
import MetalKit

class ARKitDepthViewController: UIViewController {

    @IBOutlet weak var mtkView: MTKView!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var trackingStateLabel: UILabel!

    private var faceGeometry: ARSCNFaceGeometry!
    private let faceNode = SCNNode()

    private var renderer: MetalRenderer!
    private var depthImage: CIImage?
    private var currentDrawableSize: CGSize!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard ARFaceTrackingConfiguration.isSupported else { fatalError() }

        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.scene = SCNScene()
        
        guard let device = sceneView.device else { fatalError("This device doesn't support Metal.") }
        mtkView.device = device
        mtkView.backgroundColor = UIColor.clear
        mtkView.delegate = self
        renderer = MetalRenderer(metalDevice: device, renderDestination: mtkView)
        currentDrawableSize = mtkView.currentDrawable!.layer.drawableSize

        faceGeometry = ARSCNFaceGeometry(device: device, fillMesh: true)
        if let material = faceGeometry.firstMaterial {
            material.diffuse.contents = UIColor.green
            material.lightingModel = .physicallyBased
        }
        faceNode.geometry = faceGeometry

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sceneView.session.pause()
        mtkView.delegate = nil
        super.viewWillDisappear(animated)
    }
}

extension ARKitDepthViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.global(qos: .default).async {
            guard let frame = self.sceneView.session.currentFrame else { return }
            if let depthImage = frame.transformedDepthImage(targetSize: self.currentDrawableSize) {
                self.depthImage = depthImage
            }
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        trackingStateLabel.text = camera.trackingState.description
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        faceGeometry.update(from: faceAnchor.geometry)
        
        node.addChildNode(faceNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        faceGeometry.update(from: faceAnchor.geometry)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }
}

extension ARKitDepthViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        currentDrawableSize = size
    }
    
    func draw(in view: MTKView) {
        if let image = depthImage {
            renderer.update(with: image)
        }
    }
}

extension ARFrame {
    func transformedDepthImage(targetSize: CGSize) -> CIImage? {
        guard let depthData = capturedDepthData else { return nil }
        return depthData.depthDataMap.transformedImage(targetSize: CGSize(width: targetSize.height, height: targetSize.width), rotationAngle: -CGFloat.pi/2)
    }
}
