import Foundation
import UIKit

actor ImageManager {
    static let shared = ImageManager()
    private let documentsDirectory: URL
    private static let imageCache = NSCache<NSString, UIImage>()

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("log_images", isDirectory: true)
        self.documentsDirectory = docs
        try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        Self.imageCache.countLimit = 100
    }

    func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
        let filename = "\(UUID().uuidString).jpg"
        let url = documentsDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            Self.imageCache.setObject(image, forKey: filename as NSString)
            return filename
        } catch {
            return nil
        }
    }

    func loadImage(_ filename: String) -> UIImage? {
        if let cached = Self.imageCache.object(forKey: filename as NSString) { return cached }
        let url = documentsDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { return nil }
        Self.imageCache.setObject(image, forKey: filename as NSString)
        return image
    }

    nonisolated func cachedImage(_ filename: String) -> UIImage? {
        Self.imageCache.object(forKey: filename as NSString)
    }

    func deleteImage(_ filename: String) {
        let url = documentsDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
        Self.imageCache.removeObject(forKey: filename as NSString)
    }

    func deleteImages(_ filenames: [String]) {
        for name in filenames { deleteImage(name) }
    }
}
