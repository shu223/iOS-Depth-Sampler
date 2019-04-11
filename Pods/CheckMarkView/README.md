# CheckMarkView

[![Version](https://img.shields.io/cocoapods/v/CheckMarkView.svg?style=flat)](http://cocoadocs.org/docsets/CheckMarkView)
[![License](https://img.shields.io/cocoapods/l/CheckMarkView.svg?style=flat)](http://cocoadocs.org/docsets/CheckMarkView)
[![Platform](https://img.shields.io/cocoapods/p/CheckMarkView.svg?style=flat)](http://cocoadocs.org/docsets/CheckMarkView)
[![CocoaPods](https://img.shields.io/cocoapods/dt/CheckMarkView.svg)](https://cocoapods.org/pods/CheckMarkView)
[![CocoaPods](https://img.shields.io/cocoapods/dm/CheckMarkView.svg)](https://cocoapods.org/pods/CheckMarkView)

Unfortunately <i>Apple</i> doesn't provide accessory type property for <i>UICollectionViewCell</i>, such as for <i>UITableViewCell</i>, so I provide custom way to create checkmark.
A just simple view which draws programmatically checkmark with some styles.

![alt tag](https://raw.github.com/maximbilan/CheckMarkView/master/img/img1.png)

# Installation

<b>CocoaPods:</b>
<pre>
pod 'CheckMarkView'
</pre>

<b>Manual:</b>
<pre>
Copy <i>CheckMarkView.swift</i> to your project.
</pre>

## Using

You can create from code or setup view in the <i>Storyboard</i>, <i>XIB</i>.

<pre>
let checkMarkView = CheckMarkView()
</pre>

For controlling you have <i>checked</i> property.
And <i>style</i> property for unchecked view. There are some styles:

<pre>
enum CheckMarkStyle: Int {
    case nothing
    case openCircle
    case grayedOut
}
</pre>

## License

CheckMarkView is available under the MIT license. See the LICENSE file for more info.
