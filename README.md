# iOS-Depth-Sampler

[![Platform](http://img.shields.io/badge/platform-ios-blue.svg?style=flat
)](https://developer.apple.com/iphone/index.action)
[![Language](http://img.shields.io/badge/language-swift-brightgreen.svg?style=flat
)](https://developer.apple.com/swift)
[![License](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat
)](http://mit-license.org)
[![Twitter](https://img.shields.io/badge/twitter-@shu223-blue.svg?style=flat)](http://twitter.com/shu223)

Code examples of Depth APIs in iOS

## Requirement

Use devices which has a **dual camera** (e.g. iPhone 8 Plus) or a **TrueDepth camera** (e.g. iPhone X)

## How to build

Open `ARKit-Sampler.xcworkspace` with Xcode 10 and build it!

It can **NOT** run on **Simulator**. (Because it uses Metal.)


## Contents

### Real-time Depth

Depth visualization in real time using AV Foundation.

![](README_resources/depth_1.gif)

### Real-time Depth Mask

Blending a background image with a mask created from depth.

![](README_resources/blend.gif)

### Depth from Camera Roll

Depth visualization from pictures in the camera roll.

<img src="README_resources/depth_baby_histoeq.jpg" width="600">

Plaease try this after taking **a picture with the Camera app using the PORTRAIT mode**.

### Portrait Matte

Background removal demo using Portrait Effect Matte (or Portrait Effect Matte). 

![](README_resources/portraitmatte.gif)

Plaease try this after taking **a picture of a HUMAN with PORTRAIT mode**.

Available in iOS 12 or later.

### ARKit Depth

Depth visualization on ARKit. The depth on ARKit is available only when using `ARFaceTrackingConfiguration`.

![](README_resources/arkit-depth.gif)

### 2D image in 3D space

A demo to render a 2D image in 3D space.

![](README_resources/3d.gif)


### AR occlusion

[WIP] An occlusion sample on ARKit using depth.

## Author

**Shuichi Tsutsumi**

Freelance iOS programmer from Japan.

<a href="https://paypal.me/shu223">
  <img alt="Support via PayPal" src="https://cdn.rawgit.com/twolfson/paypal-github-button/1.0.0/dist/button.svg"/>
</a>


- PAST WORKS:  [My Profile Summary](https://medium.com/@shu223/my-profile-summary-f14bfc1e7099#.vdh0i7clr)
- PROFILES: [LinkedIn](https://www.linkedin.com/in/shuichi-tsutsumi-525b755b/)
- BLOGS: [English](https://medium.com/@shu223/) / [Japanese](http://d.hatena.ne.jp/shu223/)
- CONTACTS: [Twitter](https://twitter.com/shu223) / [Facebook](https://www.facebook.com/shuichi.tsutsumi)
