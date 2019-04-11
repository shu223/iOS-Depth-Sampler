//
//  AssetsGridViewController.swift
//  SwiftAssetsPickerController
//
//  Created by Maxim Bilan on 6/5/15.
//  Copyright (c) 2015 Maxim Bilan. All rights reserved.
//

import UIKit
import Photos
import CheckMarkView

class AssetsPickerGridController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
	
	fileprivate var assetGridThumbnailSize: CGSize = CGSize(width: 0, height: 0)
	fileprivate let reuseIdentifier = "AssetsGridCell"
	fileprivate let typeIconSize = CGSize(width: 20, height: 20)
	fileprivate let checkMarkSize = CGSize(width: 28, height: 28)
	fileprivate let iconOffset: CGFloat = 3
	fileprivate let collectionViewEdgeInset: CGFloat = 2
	fileprivate let assetsInRow: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 4 : 8
	
	let cachingImageManager = PHCachingImageManager()
	var collection: PHAssetCollection?
	var selectedIndexes: Set<Int> = Set()
	var didSelectAssets: ((Array<PHAsset?>) -> ())?
	fileprivate var assets: [PHAsset]! {
		willSet {
			cachingImageManager.stopCachingImagesForAllAssets()
		}
		
		didSet {
			cachingImageManager.startCachingImages(for: self.assets, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFill, options: nil)
		}
	}
	
	// MARK: - Initialization
	
	override init(collectionViewLayout layout: UICollectionViewLayout) {
		super.init(collectionViewLayout: layout)
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let flowLayout = UICollectionViewFlowLayout()
		flowLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
		
		collectionView?.collectionViewLayout = flowLayout
		collectionView?.backgroundColor = UIColor.white
		collectionView?.register(UICollectionViewCell.classForCoder(), forCellWithReuseIdentifier: reuseIdentifier)
		
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: UIBarButtonItem.Style.done, target: self, action: #selector(AssetsPickerGridController.doneAction))
		navigationItem.rightBarButtonItem?.isEnabled = false
		
		let scale = UIScreen.main.scale
		let cellSize = flowLayout.itemSize
		assetGridThumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
		
		let assetsFetchResult = (collection == nil) ? PHAsset.fetchAssets(with: .image, options: nil) : PHAsset.fetchAssets(in: collection!, options: nil)
		assets = assetsFetchResult.objects(at: IndexSet(integersIn: Range(NSMakeRange(0, assetsFetchResult.count))!))
	}
	
	// MARK: - UICollectionViewDataSource
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return assets.count
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) 
		cell.backgroundColor = UIColor.black
		
		let currentTag = cell.tag + 1
		cell.tag = currentTag
		
		var thumbnail: UIImageView!
		var typeIcon: UIImageView!
		var checkMarkView: CheckMarkView!
		
		if cell.contentView.subviews.count == 0 {
			thumbnail = UIImageView(frame: cell.contentView.frame)
			thumbnail.contentMode = .scaleAspectFill
			thumbnail.clipsToBounds = true
			cell.contentView.addSubview(thumbnail)
			
			typeIcon = UIImageView(frame: CGRect(x: iconOffset, y: cell.contentView.frame.size.height - iconOffset - typeIconSize.height, width: typeIconSize.width, height: typeIconSize.height))
			typeIcon.contentMode = .scaleAspectFill
			typeIcon.clipsToBounds = true
			cell.contentView.addSubview(typeIcon)
			
			checkMarkView = CheckMarkView(frame: CGRect(x: cell.contentView.frame.size.width - iconOffset - checkMarkSize.width, y: iconOffset, width: checkMarkSize.width, height: checkMarkSize.height))
			checkMarkView.backgroundColor = UIColor.clear
			checkMarkView.style = CheckMarkView.Style.nothing
			cell.contentView.addSubview(checkMarkView)
		}
		else {
            thumbnail = (cell.contentView.subviews[0] as! UIImageView)
            typeIcon = (cell.contentView.subviews[1] as! UIImageView)
            checkMarkView = (cell.contentView.subviews[2] as! CheckMarkView)
		}
		
		let asset = assets[(indexPath as NSIndexPath).row]
		
		typeIcon.image = nil
		if asset.mediaType == .video {
			if asset.mediaSubtypes == .videoTimelapse {
				typeIcon.image = UIImage(named: "timelapse-icon.png")
			}
			else {
				typeIcon.image = UIImage(named: "video-icon.png")
			}
		}
		else if asset.mediaType == .image {
			if asset.mediaSubtypes == .photoPanorama {
				typeIcon.image = UIImage(named: "panorama-icon.png")
			}
		}

		checkMarkView.checked = selectedIndexes.contains(indexPath.row)
		
		cachingImageManager.requestImage(for: asset, targetSize: assetGridThumbnailSize, contentMode: PHImageContentMode.aspectFill, options: nil, resultHandler: { (image: UIImage?, info :[AnyHashable: Any]?) -> Void in
			if cell.tag == currentTag {
				thumbnail.image = image
			}
		})
		
		return cell
	}
	
	// MARK: - UICollectionViewDelegate
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if selectedIndexes.contains((indexPath as NSIndexPath).row) {
			selectedIndexes.remove((indexPath as NSIndexPath).row)
			navigationItem.rightBarButtonItem?.isEnabled = selectedIndexes.count > 0 ? true : false
		}
		else {
			navigationItem.rightBarButtonItem?.isEnabled = true
			selectedIndexes.insert((indexPath as NSIndexPath).row)
		}
		collectionView.reloadItems(at: [indexPath])
	}
	
	// MARK: - UICollectionViewDelegateFlowLayout
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let a = (self.view.frame.size.width - assetsInRow * 1 - 2 * collectionViewEdgeInset) / assetsInRow
		return CGSize(width: a, height: a)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsets.init(top: collectionViewEdgeInset, left: collectionViewEdgeInset, bottom: collectionViewEdgeInset, right: collectionViewEdgeInset)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return 1
	}
	
	// MARK: - Navigation bar actions
	
	@objc func doneAction() {
		
		var selectedAssets: Array<PHAsset?> = Array()
		for index in selectedIndexes {
			let asset = assets[index]
			selectedAssets.append(asset)
		}
		
		if didSelectAssets != nil {
			didSelectAssets!(selectedAssets)
		}
		
		navigationController!.dismiss(animated: true, completion: nil)
	}
	
}
