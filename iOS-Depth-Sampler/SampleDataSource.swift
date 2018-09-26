//
//  SampleDataSource.swift
//  iOS-Depth-Sampler
//
//  Created by Shuichi Tsutsumi on 2018/09/11.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit

struct Sample {
    let title: String
    let detail: String
    let classPrefix: String
    
    func controller() -> UIViewController {
        let storyboard = UIStoryboard(name: classPrefix, bundle: nil)
        guard let controller = storyboard.instantiateInitialViewController() else {fatalError()}
        controller.title = title
        return controller
    }
}

struct SampleDataSource {
    let samples = [
        Sample(
            title: "Real-time Depth",
            detail: "Depth visualization in real time using AV Foundation",
            classPrefix: "RealtimeDepth"
        ),
        Sample(
            title: "Real-time Depth Mask",
            detail: "Blending a background image with a mask created from depth",
            classPrefix: "RealtimeDepthMask"
        ),
        Sample(
            title: "Depth from Camera Roll",
            detail: "Depth visualization from pictures in the camera roll",
            classPrefix: "DepthFromCameraRoll"
        ),
        Sample(
            title: "Portrait Matte",
            detail: "Background removal demo using Portrait Matte",
            classPrefix: "PortraitMatte"
        ),
        Sample(
            title: "ARKit Depth",
            detail: "Depth visualization on ARKit",
            classPrefix: "ARKitDepth"
        ),
        Sample(
            title: "2D image in 3D space",
            detail: "A demo to render a 2D image in 3D space",
            classPrefix: "PointCloud"
        ),
        ]
}
