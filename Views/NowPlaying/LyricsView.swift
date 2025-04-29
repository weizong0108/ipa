import SwiftUI

struct LyricLine: Identifiable {
    let id = UUID()
    let timestamp: TimeInterval
    let text: String
    var isHighlighted: Bool = false
}

struct LyricsView: View {
    @ObservedObject var viewModel: NowPlayingViewModel
    @State private var scrollProxy: ScrollViewProxy?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(viewModel.lyrics) { line in
                        Text(line.text)
                            .font(.system(size: 16))
                            .foregroundColor(line.isHighlighted ? .blue : .primary)
                            .fontWeight(line.isHighlighted ? .bold : .regular)
                            .id(line.id)
                            .onTapGesture {
                                viewModel.seekToPosition(timestamp: line.timestamp)
                            }
                    }
                }
                .padding()
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
        .onChange(of: viewModel.currentTime) { newTime in
            if let currentLyric = viewModel.lyrics.first(where: { $0.isHighlighted }),
               let scrollProxy = scrollProxy {
                withAnimation {
                    scrollProxy.scrollTo(currentLyric.id, anchor: .center)
                }
            }
        }
    }
} 