import Foundation
import AVFoundation

enum AudioEffect: String {
    case none
    case bass
    case treble
    case vocal
    case rock
    case pop
    case classical
    case custom
}

class AudioEffectsProcessor {
    static let shared = AudioEffectsProcessor()
    
    private var audioEngine: AVAudioEngine
    private var equalizer: AVAudioUnitEQ
    private var reverb: AVAudioUnitReverb
    private var distortion: AVAudioUnitDistortion
    
    private var currentEffect: AudioEffect = .none
    private var isEnabled = true
    
    // 均衡器预设
    private let presets: [AudioEffect: [Float]] = [
        .bass: [-5, 4, 4, 3, 1, 0, 0, 0, 0, 0],
        .treble: [0, 0, 0, 0, 0, 2, 3, 4, 4, 5],
        .vocal: [-2, -1, 0, 2, 4, 4, 2, 0, -1, -2],
        .rock: [4, 3, 2, 0, -1, -1, 2, 3, 4, 4],
        .pop: [-1, 0, 2, 4, 3, 1, 0, -1, -1, -2],
        .classical: [3, 2, 1, 0, -1, -1, 0, 1, 2, 3]
    ]
    
    private init() {
        audioEngine = AVAudioEngine()
        equalizer = AVAudioUnitEQ(numberOfBands: 10)
        reverb = AVAudioUnitReverb()
        distortion = AVAudioUnitDistortion()
        
        setupAudioEngine()
        setupEqualizer()
    }
    
    private func setupAudioEngine() {
        let mainMixer = audioEngine.mainMixerNode
        
        // 连接音频处理单元
        audioEngine.attach(equalizer)
        audioEngine.attach(reverb)
        audioEngine.attach(distortion)
        
        // 设置音频处理链
        audioEngine.connect(equalizer, to: reverb, format: nil)
        audioEngine.connect(reverb, to: distortion, format: nil)
        audioEngine.connect(distortion, to: mainMixer, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }
    
    private func setupEqualizer() {
        // 设置均衡器频段
        let frequencies: [Float] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
        let bandwidths: [Float] = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
        
        for i in 0..<equalizer.bands.count {
            let band = equalizer.bands[i]
            band.frequency = frequencies[i]
            band.bandwidth = bandwidths[i]
            band.bypass = false
            band.gain = 0
        }
    }
    
    // 应用音效预设
    func applyEffect(_ effect: AudioEffect) {
        currentEffect = effect
        
        guard isEnabled else { return }
        
        if effect == .none {
            resetEffects()
            return
        }
        
        if let gains = presets[effect] {
            for (index, gain) in gains.enumerated() {
                equalizer.bands[index].gain = gain
            }
        }
        
        // 根据音效类型设置混响和失真
        switch effect {
        case .rock:
            reverb.wetDryMix = 20
            distortion.preGain = 3
            distortion.wetDryMix = 30
        case .pop:
            reverb.wetDryMix = 15
            distortion.preGain = 0
            distortion.wetDryMix = 0
        case .classical:
            reverb.wetDryMix = 40
            distortion.preGain = 0
            distortion.wetDryMix = 0
        default:
            reverb.wetDryMix = 0
            distortion.preGain = 0
            distortion.wetDryMix = 0
        }
    }
    
    // 重置所有音效
    func resetEffects() {
        for band in equalizer.bands {
            band.gain = 0
        }
        
        reverb.wetDryMix = 0
        distortion.preGain = 0
        distortion.wetDryMix = 0
        
        currentEffect = .none
    }
    
    // 启用/禁用音效处理
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled {
            applyEffect(currentEffect)
        } else {
            resetEffects()
        }
    }
    
    // 自定义均衡器设置
    func setCustomEqualizer(gains: [Float]) {
        guard gains.count == equalizer.bands.count else { return }
        
        currentEffect = .custom
        
        for (index, gain) in gains.enumerated() {
            equalizer.bands[index].gain = gain
        }
    }
    
    // 获取当前均衡器设置
    func getCurrentEqualizerGains() -> [Float] {
        return equalizer.bands.map { $0.gain }
    }
    
    // 设置混响效果
    func setReverb(wetDryMix: Float) {
        reverb.wetDryMix = wetDryMix
    }
    
    // 设置失真效果
    func setDistortion(preGain: Float, wetDryMix: Float) {
        distortion.preGain = preGain
        distortion.wetDryMix = wetDryMix
    }
    
    // 获取当前音效
    func getCurrentEffect() -> AudioEffect {
        return currentEffect
    }
    
    // 获取可用的音效预设
    func getAvailableEffects() -> [AudioEffect] {
        return Array(presets.keys) + [.none, .custom]
    }
    
    // 获取特定预设的均衡器设置
    func getPresetGains(for effect: AudioEffect) -> [Float]? {
        return presets[effect]
    }
    
    // 保存自定义预设
    func saveCustomPreset(gains: [Float], name: String) {
        var savedPresets = UserDefaults.standard.dictionary(forKey: "customPresets") as? [String: [Float]] ?? [:]
        savedPresets[name] = gains
        UserDefaults.standard.set(savedPresets, forKey: "customPresets")
    }
    
    // 加载自定义预设
    func loadCustomPreset(name: String) -> [Float]? {
        let savedPresets = UserDefaults.standard.dictionary(forKey: "customPresets") as? [String: [Float]]
        return savedPresets?[name]
    }
    
    // 删除自定义预设
    func deleteCustomPreset(name: String) {
        var savedPresets = UserDefaults.standard.dictionary(forKey: "customPresets") as? [String: [Float]] ?? [:]
        savedPresets.removeValue(forKey: name)
        UserDefaults.standard.set(savedPresets, forKey: "customPresets")
    }
} 