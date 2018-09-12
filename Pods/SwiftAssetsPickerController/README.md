# SwiftAssetsPickerController

[![Version](https://img.shields.io/cocoapods/v/SwiftAssetsPickerController.svg?style=flat)](http://cocoadocs.org/docsets/SwiftAssetsPickerController)
[![License](https://img.shields.io/cocoapods/l/SwiftAssetsPickerController.svg?style=flat)](http://cocoadocs.org/docsets/SwiftAssetsPickerController)
[![Platform](https://img.shields.io/cocoapods/p/SwiftAssetsPickerController.svg?style=flat)](http://cocoadocs.org/docsets/SwiftAssetsPickerController)
[![CocoaPods](https://img.shields.io/cocoapods/dt/SwiftAssetsPickerController.svg)](https://cocoapods.org/pods/SwiftAssetsPickerController)
[![CocoaPods](https://img.shields.io/cocoapods/dm/SwiftAssetsPickerController.svg)](https://cocoapods.org/pods/SwiftAssetsPickerController)

Simple assets picker controller based on <i>Photos</i> framework. Supports <i>iCloud</i> photos and videos.

![alt tag](https://raw.github.com/maximbilan/SwiftAssetsPickerController/master/img/img1.png)
![alt tag](https://raw.github.com/maximbilan/SwiftAssetsPickerController/master/img/img2.png)

# Installation

<b>CocoaPods:</b>
<pre>
<b>Swift 3.0</b>:
pod 'SwiftAssetsPickerController', '0.3.2'

<b>Swift 4.0</b>:
pod 'SwiftAssetsPickerController', '~> 0.4.0'
</pre>

<b>Manual:</b>
<pre>
Copy <i>AssetsPickerController.swift</i> and <i>AssetsPickerGridController.swift</i> to your project.
Also framework uses <i>CheckMarkView</i>, you can found <a href="https://github.com/maximbilan/CheckMarkView">here</a>.
</pre>

## Using

It's really simple. Just see the example:

<pre>
let assetsPickerController = AssetsPickerController()
assetsPickerController.didSelectAssets = {(assets: Array<PHAsset!>) -> () in
    println(assets)
}
let navigationController = UINavigationController(rootViewController: rootListAssets)
presentViewController(navigationController, animated: true, completion: nil)
</pre>

## License

SwiftAssetsPickerController is available under the MIT license. See the LICENSE file for more info.
