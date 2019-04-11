//
//  RootListAssetsViewController.swift
//  SwiftAssetsPickerController
//
//  Created by Maxim Bilan on 6/5/15.
//  Copyright (c) 2015 Maxim Bilan. All rights reserved.
//

import UIKit
import Photos

open class AssetsPickerController: UITableViewController, PHPhotoLibraryChangeObserver {
	
	enum AlbumType: Int {
//        case allPhotos
//        case favorites
//        case panoramas
//        case videos
//        case timeLapse
//        case recentlyDeleted
//        case userAlbum
        case depthEffect
		
//        static let titles = ["All Photos", "Favorites", "Panoramas", "Videos", "Time Lapse", "Recently Deleted", "User Album", "Depth Effect"]
        static let titles = ["Depth Effect"]
	}
	
	struct RootListItem {
		var title: String!
		var albumType: AlbumType
		var image: UIImage!
		var collection: PHAssetCollection?
	}
	
	fileprivate var items: Array<RootListItem>!
	fileprivate var activityIndicator: UIActivityIndicatorView!
	fileprivate let thumbnailSize = CGSize(width: 64, height: 64)
	fileprivate let reuseIdentifier = "RootListAssetsCell"
	
	open var didSelectAssets: ((Array<PHAsset?>) -> ())?
	
	// MARK: View controllers methods
	
	override open func viewDidLoad() {
		super.viewDidLoad()
		
		// Navigation bar
		navigationItem.title = NSLocalizedString("Photos", comment: "")
		navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(AssetsPickerController.cancelAction))
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: UIBarButtonItem.Style.done, target: self, action: #selector(AssetsPickerController.doneAction))
		navigationItem.rightBarButtonItem?.isEnabled = false
		
		// Activity indicator
		activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
		activityIndicator.hidesWhenStopped = true
		activityIndicator.center = self.view.center
		self.view.addSubview(activityIndicator)
		
		// Data
		items = Array()
		
		// Notifications
		PHPhotoLibrary.shared().register(self)
		
		// Load photo library
		loadData()
	}
	
	deinit {
		PHPhotoLibrary.shared().unregisterChangeObserver(self)
	}
	
	// MARK: Data loading
	
	func loadData() {
		tableView.isUserInteractionEnabled = false
		activityIndicator.startAnimating()
		
		DispatchQueue.global(qos: .default).async {
		
			self.items.removeAll(keepingCapacity: false)
			
//            let allPhotosItem = RootListItem(title: AlbumType.titles[AlbumType.allPhotos.rawValue], albumType: AlbumType.allPhotos, image: self.lastImageFromCollection(nil), collection: nil)
//            let assetsCount = self.assetsCountFromCollection(nil)
//            if assetsCount > 0 {
//                self.items.append(allPhotosItem)
//            }
			
			let smartAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.smartAlbumDepthEffect, options: nil)
			for i: Int in 0 ..< smartAlbums.count {
				let smartAlbum = smartAlbums[i]
				var item: RootListItem? = nil
				
				let assetsCount = self.assetsCountFromCollection(smartAlbum)
				if assetsCount == 0 {
					continue
				}
				
				switch smartAlbum.assetCollectionSubtype {
                case .smartAlbumDepthEffect:
                    item = RootListItem(title: AlbumType.titles[AlbumType.depthEffect.rawValue], albumType: AlbumType.depthEffect, image: self.lastImageFromCollection(smartAlbum), collection: smartAlbum)
                    break
//                case .smartAlbumFavorites:
//                    item = RootListItem(title: AlbumType.titles[AlbumType.favorites.rawValue], albumType: AlbumType.favorites, image: self.lastImageFromCollection(smartAlbum), collection: smartAlbum)
//                    break
//                case .smartAlbumPanoramas:
//                    item = RootListItem(title: AlbumType.titles[AlbumType.panoramas.rawValue], albumType: AlbumType.panoramas, image: self.lastImageFromCollection(smartAlbum), collection: smartAlbum)
//                    break
//                case .smartAlbumVideos:
//                    item = RootListItem(title: AlbumType.titles[AlbumType.videos.rawValue], albumType: AlbumType.videos, image: self.lastImageFromCollection(smartAlbum), collection: smartAlbum)
//                    break
//                case .smartAlbumTimelapses:
//                    item = RootListItem(title: AlbumType.titles[AlbumType.timeLapse.rawValue], albumType: AlbumType.timeLapse, image: self.lastImageFromCollection(smartAlbum), collection: smartAlbum)
//                    break
					
				default:
					break
				}
				
				if item != nil {
					self.items.append(item!)
				}
			}
			
//            let topLevelUserCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
//            for i: Int in 0 ..< topLevelUserCollections.count {
//                if let userCollection = topLevelUserCollections[i] as? PHAssetCollection {
//                    let assetsCount = self.assetsCountFromCollection(userCollection)
//                    if assetsCount == 0 {
//                        continue
//                    }
//                    let item = RootListItem(title: userCollection.localizedTitle, albumType: AlbumType.userAlbum, image: self.lastImageFromCollection(userCollection), collection: userCollection)
//                    self.items.append(item)
//                }
//            }
			
			DispatchQueue.main.async {
				self.tableView.reloadData()
				self.activityIndicator.stopAnimating()
				self.tableView.isUserInteractionEnabled = true
			}
		}
	}
	
	// MARK: UITableViewDataSource
	
	override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return items.count
	}
	
	override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell: UITableViewCell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: reuseIdentifier)
		
		cell.imageView?.image = items[(indexPath as NSIndexPath).row].image
		cell.textLabel?.text = NSLocalizedString(items[(indexPath as NSIndexPath).row].title, comment: "")
		
		return cell
	}
	
	// MARK: UITableViewDelegate
	
	override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let assetsGrid = AssetsPickerGridController(collectionViewLayout: UICollectionViewLayout())
		assetsGrid.collection = items[(indexPath as NSIndexPath).row].collection
		assetsGrid.didSelectAssets = didSelectAssets
		assetsGrid.title = items[(indexPath as NSIndexPath).row].title
		navigationController?.pushViewController(assetsGrid, animated: true)
	}
	
	// MARK: Navigation bar actions
	
	@objc func cancelAction() {
		dismiss(animated: true, completion: nil)
	}
	
	@objc func doneAction() {
		
	}
	
	// MARK: PHPhotoLibraryChangeObserver
	
	open func photoLibraryDidChange(_ changeInstance: PHChange) {
		loadData()
	}
	
	// MARK: Other
	
	func assetsCountFromCollection(_ collection: PHAssetCollection?) -> Int {
		let fetchResult = (collection == nil) ? PHAsset.fetchAssets(with: .image, options: nil) : PHAsset.fetchAssets(in: collection!, options: nil)
		return fetchResult.count
	}
	
	func lastImageFromCollection(_ collection: PHAssetCollection?) -> UIImage? {
		
		var returnImage: UIImage? = nil
		
		let fetchOptions = PHFetchOptions()
		fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
		
		let fetchResult = (collection == nil) ? PHAsset.fetchAssets(with: .image, options: fetchOptions) : PHAsset.fetchAssets(in: collection!, options: fetchOptions)
		if let lastAsset = fetchResult.lastObject {
			
			let imageRequestOptions = PHImageRequestOptions()
			imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.fastFormat
			imageRequestOptions.resizeMode = PHImageRequestOptionsResizeMode.exact
			imageRequestOptions.isSynchronous = true
			
			let retinaScale = UIScreen.main.scale
			let retinaSquare = CGSize(width: thumbnailSize.width * retinaScale, height: thumbnailSize.height * retinaScale)
			
			let cropSideLength = min(lastAsset.pixelWidth, lastAsset.pixelHeight)
			let square = CGRect(x: CGFloat(0), y: CGFloat(0), width: CGFloat(cropSideLength), height: CGFloat(cropSideLength))
			let cropRect = square.applying(CGAffineTransform(scaleX: 1.0 / CGFloat(lastAsset.pixelWidth), y: 1.0 / CGFloat(lastAsset.pixelHeight)))
			
			imageRequestOptions.normalizedCropRect = cropRect
			
			PHImageManager.default().requestImage(for: lastAsset, targetSize: retinaSquare, contentMode: PHImageContentMode.aspectFit, options: imageRequestOptions, resultHandler: { (image: UIImage?, info :[AnyHashable: Any]?) -> Void in
				returnImage = image
			})
		}
		
		return returnImage
	}
	
}
