import SwiftUI

struct AsyncImageView: View {
    let url: URL?
    let placeholder: Image
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(url: URL?, placeholder: Image = Image(systemName: "photo")) {
        self.url = url
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                            }
                        }
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = url else { return }
        
        // 检查缓存
        if let cachedImage = ImageCacheManager.shared.image(for: url) {
            self.image = cachedImage
            return
        }
        
        // 开始加载
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { isLoading = false }
            
            guard let data = data,
                  let loadedImage = UIImage(data: data) else {
                return
            }
            
            // 缓存图片
            ImageCacheManager.shared.cache(image: loadedImage, for: url)
            
            // 更新UI
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }.resume()
    }
} 