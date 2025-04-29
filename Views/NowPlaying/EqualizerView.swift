import SwiftUI

struct EqualizerView: View {
    @ObservedObject var viewModel: NowPlayingViewModel
    
    private let frequencies = ["32Hz", "125Hz", "500Hz", "2kHz", "8kHz"]
    private let presets = ["Default", "Bass Boost", "Treble Boost", "Vocal Boost"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("均衡器")
                .font(.title)
                .padding(.top)
            
            // 预设选择
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(presets, id: \.self) { preset in
                        Button(action: {
                            selectPreset(preset)
                        }) {
                            Text(preset)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(isSelectedPreset(preset) ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(isSelectedPreset(preset) ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // 均衡器滑块
            HStack(spacing: 20) {
                ForEach(0..<5) { index in
                    VStack {
                        Slider(value: binding(for: index), in: -12...12, step: 1) {
                            Text(frequencies[index])
                        }
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 200)
                        
                        Text(frequencies[index])
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.0fdB", viewModel.equalizerSettings.bands[index]))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            Spacer()
        }
    }
    
    private func binding(for index: Int) -> Binding<Float> {
        Binding(
            get: { viewModel.equalizerSettings.bands[index] },
            set: { newValue in
                var newSettings = viewModel.equalizerSettings
                newSettings.bands[index] = newValue
                viewModel.updateEqualizerSettings(newSettings)
            }
        )
    }
    
    private func selectPreset(_ preset: String) {
        switch preset {
        case "Default":
            viewModel.updateEqualizerSettings(.default)
        case "Bass Boost":
            viewModel.updateEqualizerSettings(.bass)
        case "Treble Boost":
            viewModel.updateEqualizerSettings(.treble)
        case "Vocal Boost":
            viewModel.updateEqualizerSettings(.vocal)
        default:
            break
        }
    }
    
    private func isSelectedPreset(_ preset: String) -> Bool {
        switch preset {
        case "Default":
            return viewModel.equalizerSettings.bands == EqualizerSettings.default.bands
        case "Bass Boost":
            return viewModel.equalizerSettings.bands == EqualizerSettings.bass.bands
        case "Treble Boost":
            return viewModel.equalizerSettings.bands == EqualizerSettings.treble.bands
        case "Vocal Boost":
            return viewModel.equalizerSettings.bands == EqualizerSettings.vocal.bands
        default:
            return false
        }
    }
} 