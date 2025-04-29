import Foundation
import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let diskCacheDirectory: URL
    
    private init() {
        // 设置内存缓存限制
        memoryCache.countLimit = 100 // 最多缓存100张图片
        memoryCache.totalCostLimit = 1024 * 1024 * 100 // 100 MB
        
        // 设置磁盘缓存目录
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheDirectory = cacheDirectory.appendingPathComponent("ImageCache")
        
        // 创建缓存目录
        try? fileManager.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
    }
    
    // 从缓存获取图片
    func image(for url: URL) -> UIImage? {
        let key = url.absoluteString as NSString
        
        // 先从内存缓存中查找
        if let cachedImage = memoryCache.object(forKey: key) {
            return cachedImage
        }
        
        // 从磁盘缓存中查找
        let diskCacheURL = diskCacheDirectory.appendingPathComponent(key.hash.description)
        if let data = try? Data(contentsOf: diskCacheURL),
           let image = UIImage(data: data) {
            // 找到后加入内存缓存
            memoryCache.setObject(image, forKey: key)
            return image
        }
        
        return nil
    }
    
    // 保存图片到缓存
    func cache(image: UIImage, for url: URL) {
        let key = url.absoluteString as NSString
        
        // 保存到内存缓存
        memoryCache.setObject(image, forKey: key)
        
        // 保存到磁盘缓存
        let diskCacheURL = diskCacheDirectory.appendingPathComponent(key.hash.description)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: diskCacheURL)
        }
    }
    
    // 清理过期缓存
    func clearExpiredCache() {
        // 清理内存缓存
        memoryCache.removeAllObjects()
        
        // 清理过期的磁盘缓存
        let expirationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7天
        
        guard let contents = try? fileManager.contentsOfDirectory(
            at: diskCacheDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        ) else { return }
        
        let expired = Date().timeIntervalSince1970 - expirationInterval
        
        for fileURL in contents {
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let creationDate = attributes[.creationDate] as? Date else { continue }
            
            if creationDate.timeIntervalSince1970 < expired {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    // 获取缓存大小
    func getCacheSize() -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: diskCacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        
        return contents.reduce(0) { result, url in
            guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                  let size = attributes[.size] as? Int64 else { return result }
            return result + size
        }
    }
} 