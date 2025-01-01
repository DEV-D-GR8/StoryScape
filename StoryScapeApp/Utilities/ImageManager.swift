//
//  ImageManager.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import Foundation
import SwiftUI

/// A manager for downloading/caching images, if you need more sophisticated logic.
class ImageManager {
    
    static let shared = ImageManager()
    private init() {}
    
    /// Download an image from a remote URL
    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
}
