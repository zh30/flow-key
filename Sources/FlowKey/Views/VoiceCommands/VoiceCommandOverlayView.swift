import SwiftUI

// MARK: - Voice Command Overlay View

struct VoiceCommandOverlayView: View {
    @StateObject private var voiceCommandRecognizer = VoiceCommandRecognizer.shared
    @State private var isVisible = false
    @State private var pulseScale: Double = 1.0
    @State private var pulseOpacity: Double = 1.0
    @State private var showWaveform = false
    @State private var waveformBars: [Double] = Array(repeating: 0.3, count: 20)
    
    var body: some View {
        VStack(spacing: 20) {
            // Voice Command Header
            HStack {
                Image(systemName: "waveform")
                    .font(.title)
                    .foregroundColor(.blue)
                
                Text("语音命令")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("关闭") {
                    Task {
                        await voiceCommandRecognizer.stopListening()
                        isVisible = false
                    }
                }
                .buttonStyle(.bordered)
            }
            
            // Status Indicator
            VStack(spacing: 12) {
                if voiceCommandRecognizer.isListening {
                    // Animated listening indicator
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .scaleEffect(pulseScale)
                            .opacity(pulseOpacity)
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "mic.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            pulseScale = 1.2
                            pulseOpacity = 0.5
                        }
                    }
                    
                    Text("正在监听...")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("请说出您的命令")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                } else if voiceCommandRecognizer.isProcessing {
                    // Processing indicator
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("处理中...")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("正在识别您的语音")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                } else if let command = voiceCommandRecognizer.currentCommand {
                    // Command result
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: command.type.icon)
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            Text(command.type.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text(command.text)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                        
                        HStack {
                            Text("置信度")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(command.confidence * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(confidenceColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        if voiceCommandRecognizer.settings.showConfirmation {
                            HStack(spacing: 16) {
                                Button("执行") {
                                    Task {
                                        await voiceCommandRecognizer.executeCommand(command)
                                        isVisible = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("取消") {
                                    voiceCommandRecognizer.currentCommand = nil
                                    isVisible = false
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    
                } else {
                    // Ready state
                    VStack(spacing: 8) {
                        Image(systemName: "mic")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("准备就绪")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("点击开始按钮开始录音")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Audio Waveform
            if voiceCommandRecognizer.isListening && showWaveform {
                HStack(spacing: 2) {
                    ForEach(Array(waveformBars.enumerated()), id: \.offset) { index, height in
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 3, height: height * 40)
                            .cornerRadius(2)
                            .animation(
                                Animation.easeInOut(duration: 0.1)
                                    .delay(Double(index) * 0.02),
                                value: height
                            )
                    }
                }
                .frame(height: 60)
                .onAppear {
                    startWaveformAnimation()
                }
            }
            
            // Control Buttons
            HStack(spacing: 16) {
                Button(action: {
                    Task {
                        await voiceCommandRecognizer.toggleListening()
                    }
                }) {
                    HStack {
                        Image(systemName: voiceCommandRecognizer.isListening ? "stop.fill" : "mic.fill")
                        Text(voiceCommandRecognizer.isListening ? "停止" : "开始")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(voiceCommandRecognizer.isProcessing)
                
                if voiceCommandRecognizer.settings.showConfirmation && voiceCommandRecognizer.currentCommand != nil {
                    Button("重试") {
                        voiceCommandRecognizer.currentCommand = nil
                        Task {
                            await voiceCommandRecognizer.startListening()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // Quick Commands Reference
            if !voiceCommandRecognizer.isListening && voiceCommandRecognizer.currentCommand == nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("快速命令")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(quickCommands, id: \.type) { command in
                            HStack {
                                Image(systemName: command.type.icon)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text(command.example)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.top, 16)
            }
        }
        .padding(24)
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(16)
        .shadow(radius: 20)
        .onAppear {
            startWaveformAnimation()
        }
    }
    
    // MARK: - Helper Properties
    
    private var quickCommands: [(type: VoiceCommandType, example: String)] {
        [
            (.translate, "翻译 Hello World"),
            (.insert, "插入 你好"),
            (.search, "搜索 教程"),
            (.copy, "复制"),
            (.paste, "粘贴"),
            (.clear, "清除")
        ]
    }
    
    private var confidenceColor: Color {
        guard let command = voiceCommandRecognizer.currentCommand else { return .gray }
        
        switch command.confidence {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
    
    // MARK: - Helper Methods
    
    private func startWaveformAnimation() {
        showWaveform = true
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if voiceCommandRecognizer.isListening {
                // Simulate audio waveform with random heights
                for i in 0..<waveformBars.count {
                    waveformBars[i] = Double.random(in: 0.2...1.0)
                }
            } else {
                timer.invalidate()
                showWaveform = false
                // Reset waveform
                waveformBars = Array(repeating: 0.3, count: 20)
            }
        }
    }
}

// MARK: - Voice Command Mini View

struct VoiceCommandMiniView: View {
    @StateObject private var voiceCommandRecognizer = VoiceCommandRecognizer.shared
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 8) {
            if voiceCommandRecognizer.isListening {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(isVisible ? 1.0 : 0.3)
                        .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isVisible)
                    
                    Text("正在录音...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(16)
            } else if voiceCommandRecognizer.isProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    
                    Text("处理中...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(16)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Voice Command Manager

@MainActor
class VoiceCommandManager: ObservableObject {
    @Published private(set) var isOverlayVisible = false
    @Published private(set) var isMiniViewVisible = false
    
    private let voiceCommandRecognizer = VoiceCommandRecognizer.shared
    private var overlayWindow: NSWindow?
    private var miniViewWindow: NSWindow?
    
    static let shared = VoiceCommandManager()
    
    private init() {
        setupBindings()
    }
    
    private func setupBindings() {
        voiceCommandRecognizer.$isListening
            .sink { [weak self] isListening in
                if isListening {
                    self?.showOverlay()
                } else if !self?.voiceCommandRecognizer.isProcessing ?? false {
                    self?.hideOverlay()
                }
            }
            .store(in: &cancellables)
        
        voiceCommandRecognizer.$isProcessing
            .sink { [weak self] isProcessing in
                if isProcessing {
                    self?.showMiniView()
                } else {
                    self?.hideMiniView()
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    func showOverlay() {
        guard overlayWindow == nil else { return }
        
        let overlayView = VoiceCommandOverlayView()
        let hostingController = NSHostingController(rootView: overlayView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingController.view
        window.level = .floating
        window.center()
        window.isOpaque = false
        window.backgroundColor = .clear
        
        overlayWindow = window
        window.makeKeyAndOrderFront(nil)
        isOverlayVisible = true
    }
    
    func hideOverlay() {
        overlayWindow?.close()
        overlayWindow = nil
        isOverlayVisible = false
    }
    
    func showMiniView() {
        guard miniViewWindow == nil else { return }
        
        let miniView = VoiceCommandMiniView()
        let hostingController = NSHostingController(rootView: miniView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 120, height: 30),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingController.view
        window.level = .floating
        window.positionAt(.bottomRight, offset: CGPoint(x: -20, y: -20))
        window.isOpaque = false
        window.backgroundColor = .clear
        
        miniViewWindow = window
        window.makeKeyAndOrderFront(nil)
        isMiniViewVisible = true
    }
    
    func hideMiniView() {
        miniViewWindow?.close()
        miniViewWindow = nil
        isMiniViewVisible = false
    }
    
    func toggleVoiceCommand() {
        Task {
            await voiceCommandRecognizer.toggleListening()
        }
    }
}

// MARK: - NSWindow Extension

extension NSWindow {
    func positionAt(_ position: WindowPosition, offset: CGPoint = .zero) {
        guard let screen = NSScreen.main else { return }
        
        let frame = screen.frame
        var targetOrigin: CGPoint
        
        switch position {
        case .topLeft:
            targetOrigin = CGPoint(x: frame.minX + offset.x, y: frame.maxY - frame.height - offset.y)
        case .topRight:
            targetOrigin = CGPoint(x: frame.maxX - frame.width - offset.x, y: frame.maxY - frame.height - offset.y)
        case .bottomLeft:
            targetOrigin = CGPoint(x: frame.minX + offset.x, y: frame.minY + offset.y)
        case .bottomRight:
            targetOrigin = CGPoint(x: frame.maxX - frame.width - offset.x, y: frame.minY + offset.y)
        case .center:
            targetOrigin = CGPoint(x: frame.midX - frame.width / 2 + offset.x, y: frame.midY - frame.height / 2 + offset.y)
        }
        
        setFrameOrigin(targetOrigin)
    }
}

enum WindowPosition {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case center
}

#Preview {
    VoiceCommandOverlayView()
        .frame(width: 400, height: 500)
}