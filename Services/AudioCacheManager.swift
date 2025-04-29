import Foundation
import AVFoundation

class AudioCacheManager {
    static let shared = AudioCacheManager()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 1024 * 1024 * 1024 // 1GB
    private var preloadQueue = OperationQueue()
    private var downloadTasks: [URL: URLSessionDownloadTask] = [:]
    
    private init() {
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cacheDirectory.appendingPathComponent("AudioCache")
        
        // 创建缓存目录
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // 配置预加载队列
        preloadQueue.maxConcurrentOperationCount = 2
    }
    
    // 获取缓存文件路径
    func cachedFileURL(for url: URL) -> URL {
        return cacheDirectory.appendingPathComponent(url.lastPathComponent)
    }
    
    // 检查是否已缓存
    func isAudioCached(for url: URL) -> Bool {
        return fileManager.fileExists(atPath: cachedFileURL(for: url).path)
    }
    
    // 获取缓存文件
    func getCachedAudio(for url: URL) -> URL? {
        let cachedURL = cachedFileURL(for: url)
        return fileManager.fileExists(atPath: cachedURL.path) ? cachedURL : nil
    }
    
    // 缓存音频文件
    func cacheAudio(from url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let destinationURL = cachedFileURL(for: url)
        
        // 如果已经缓存，直接返回
        if fileManager.fileExists(atPath: destinationURL.path) {
            completion(.success(destinationURL))
            return
        }
        
        // 创建下载任务
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let tempURL = tempURL else {
                completion(.failure(NSError(domain: "AudioCache", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download failed"])))
                return
            }
            
            do {
                // 如果文件已存在，先删除
                if self.fileManager.fileExists(atPath: destinationURL.path) {
                    try self.fileManager.removeItem(at: destinationURL)
                }
                
                // 移动文件到缓存目录
                try self.fileManager.moveItem(at: tempURL, to: destinationURL)
                
                // 检查并清理缓存
                self.cleanCacheIfNeeded()
                
                completion(.success(destinationURL))
            } catch {
                completion(.failure(error))
            }
        }
        
        downloadTasks[url] = task
        task.resume()
    }
    
    // 预加载音频
    func preloadAudio(urls: [URL]) {
        for url in urls {
            guard !isAudioCached(for: url) else { continue }
            
            preloadQueue.addOperation { [weak self] in
                let semaphore = DispatchSemaphore(value: 0)
                
                self?.cacheAudio(from: url) { _ in
                    semaphore.signal()
                }
                
                semaphore.wait()
            }
        }
    }
    
    // 取消预加载
    func cancelPreloading(for url: URL) {
        downloadTasks[url]?.cancel()
        downloadTasks[url] = nil
    }
    
    // 清理缓存
    private func cleanCacheIfNeeded() {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]
        ) else { return }
        
        let cacheSize = contents.reduce(0) { result, url in
            guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                  let size = attributes[.size] as? Int64 else { return result }
            return result + size
        }
        
        // 如果缓存超过限制，删除最旧的文件
        if cacheSize > maxCacheSize {
            let sortedFiles = contents.compactMap { url -> (URL, Date)? in
                guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                      let creationDate = attributes[.creationDate] as? Date else { return nil }
                return (url, creationDate)
            }
            .sorted { $0.1 < $1.1 }
            
            for (fileURL, _) in sortedFiles {
                try? fileManager.removeItem(at: fileURL)
                
                // 重新计算缓存大小
                if let currentSize = try? fileManager.attributesOfItem(atPath: cacheDirectory.path)[.size] as? Int64,
                   currentSize <= maxCacheSize {
                    break
                }
            }
        }
    }
    
    // 获取缓存大小
    func getCacheSize() -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        
        return contents.reduce(0) { result, url in
            guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                  let size = attributes[.size] as? Int64 else { return result }
            return result + size
        }
    }
    
    // 清空缓存
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
} 