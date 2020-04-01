//
//  PointCloud.swift
//
//  Created by Shuichi Tsutsumi on 2018/09/14.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//
//  Reference: https://github.com/eugeneu/PoindCloudRenderer

import SceneKit

struct PointCloudVertex {
    var x: Float, y: Float, z: Float
    var r: Float, g: Float, b: Float
}

@objc class PointCloud: NSObject {
    
    var points: [SCNVector3] = []
    var colors: [UInt8] = []
    
    public func pointCloudNode() -> SCNNode {
        var vertices = Array(repeating: PointCloudVertex(x: 0,y: 0,z: 0,r: 0,g: 0,b: 0), count: points.count)
        
        for i in 0...(points.count-1) {
            let p = points[i]
            vertices[i].x = Float(p.x)
            vertices[i].y = Float(p.y)
            vertices[i].z = Float(p.z)
            vertices[i].r = Float(colors[i * 4]) / 255.0
            vertices[i].g = Float(colors[i * 4 + 1]) / 255.0
            vertices[i].b = Float(colors[i * 4 + 2]) / 255.0
        }
        
        let node = buildNode(points: vertices)
        return node
    }
    
    private func buildNode(points: [PointCloudVertex]) -> SCNNode {
        let vertexData = NSData(
            bytes: points,
            length: MemoryLayout<PointCloudVertex>.size * points.count
        )
        let positionSource = SCNGeometrySource(
            data: vertexData as Data,
            semantic: SCNGeometrySource.Semantic.vertex,
            vectorCount: points.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        let colorSource = SCNGeometrySource(
            data: vertexData as Data,
            semantic: SCNGeometrySource.Semantic.color,
            vectorCount: points.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: MemoryLayout<Float>.size * 3,
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        let element = SCNGeometryElement(
            data: nil,
            primitiveType: .point,
            primitiveCount: points.count,
            bytesPerIndex: MemoryLayout<Int>.size
        )

        // for bigger dots
        element.pointSize = 1
        element.minimumPointScreenSpaceRadius = 1
        element.maximumPointScreenSpaceRadius = 7

        let pointsGeometry = SCNGeometry(sources: [positionSource, colorSource], elements: [element])
        
        return SCNNode(geometry: pointsGeometry)
    }
}
