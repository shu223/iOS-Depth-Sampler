//
//  DepthImagePickableViewController.swift
//  iOS-Depth-Sampler
//
//  Created by Shuichi Tsutsumi on 2023/08/11.
//  Copyright © 2023 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import PhotosUI

class DepthImagePickableViewController: UIViewController {

    // override
    func loadImage(at url: URL) {
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

extension DepthImagePickableViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        defer {
            picker.dismiss(animated: true, completion: nil)
        }
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
    }
}
