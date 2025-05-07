import Flutter
import UIKit
import AVFoundation

@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 注册Flutter插件
    GeneratedPluginRegistrant.register(with: self)
    
    // 配置音频会话，支持后台播放
    setupAudioSession()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 配置音频会话，启用后台播放功能
  private func setupAudioSession() {
    do {
      // 设置音频会话类别为播放，允许在后台播放音频
      try AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .default,
        options: [.allowAirPlay, .allowBluetooth]
      )
      
      // 激活音频会话
      try AVAudioSession.sharedInstance().setActive(true)
      
      // 注册远程控制事件接收
      UIApplication.shared.beginReceivingRemoteControlEvents()
      
      print("音频会话配置成功，已启用后台播放")
    } catch {
      print("配置音频会话失败: \(error)")
    }
  }
}
