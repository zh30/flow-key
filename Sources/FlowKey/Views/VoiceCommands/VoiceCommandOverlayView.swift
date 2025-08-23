import SwiftUI
import Combine

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
                    }
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            pulseScale = 1.2
                            pulseOpacity = 0.5
                        }
                    }
                    
                    Text("正在录音...")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    // Audio waveform visualization
                    if showWaveform {
                        HStack(spacing: 2) {
                            ForEach(waveformBars.indices, id: \.self) { index in
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: 3, height: CGFloat(waveformBars[index] * 40))
                                    .animation(.easeInOut(duration: 0.1), value: waveformBars[index])
                            }
                        }
                        .frame(height: 40)
                        .onAppear {
                            startWaveformAnimation()
                        }
                    }
                } else if voiceCommandRecognizer.isProcessing {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("处理中...")
                        .font(.headline)
                        .foregroundColor(.orange)
                } else {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 60, height: 60)
                    Text("就绪")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            
            // Current Command Display
            if let command = voiceCommandRecognizer.currentCommand {
                VStack(spacing: 8) {
                    Text("识别到命令")
                        .font(.headline)
                    Text(command.type.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    if let confidence = command.confidence {
                        Text("置信度: \(Int(confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            
            // Control Buttons
            HStack(spacing: 16) {
                if voiceCommandRecognizer.isListening {
                    Button("停止录音") {
                        Task {
                            await voiceCommandRecognizer.stopListening()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button("开始录音") {
                        Task {
                            await voiceCommandRecognizer.startListening()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                
                Button("取消") {
                    Task {
                        await voiceCommandRecognizer.stopListening()
                        isVisible = false
                    }
                }
                .buttonStyle(.bordered)
            }
            
            // Command Reference
            VStack(alignment: .leading, spacing: 8) {
                Text("常用命令")
                    .font(.headline)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(VoiceCommandRecognizer.VoiceCommandType.allCases.prefix(5), id: \.self) { commandType in
                            HStack {
                                Text("•")
                                Text(commandType.displayName)
                                Spacer()
                                Text(commandType.example)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .font(.caption)
                        }
                    }
                }
                .frame(height: 120)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
        .frame(width: 400, height: 500)
        .onAppear {
            setupWaveform()
        }
    }
    
    private func setupWaveform() {
        // Initialize waveform with random values
        waveformBars = waveformBars.map { _ in
            Double.random(in: 0.2...0.8)
        }
    }
    
    private func startWaveformAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard voiceCommandRecognizer.isListening else {
                timer.invalidate()
                return
            }
            
            // Simulate audio waveform with random heights
            for i in 0..<waveformBars.count {
                waveformBars[i] = Double.random(in: 0.2...0.8)
            }
        }
    }
}

// MARK: - Voice Command Mini View

struct VoiceCommandMiniView: View {
    @StateObject private var voiceCommandRecognizer = VoiceCommandRecognizer.shared
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 8) {
            if voiceCommandRecognizer.isProcessing {
                // Pulsing indicator
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isPulsing ? 1.5 : 1.0)
                    .opacity(isPulsing ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
                    .onAppear {
                        isPulsing = true
                    }
                    .onDisappear {
                        isPulsing = false
                    }
                
                Text("处理中...")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Text("语音命令")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Window Position Extension

extension NSWindow {
    func positionWindow(at position: WindowPosition) {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.frame
        let windowFrame = frame
        
        switch position {
        case .topLeft:
            setFrameOrigin(NSPoint(x: screenFrame.minX + 20, y: screenFrame.maxY - windowFrame.height - 20))
        case .topRight:
            setFrameOrigin(NSPoint(x: screenFrame.maxX - windowFrame.width - 20, y: screenFrame.maxY - windowFrame.height - 20))
        case .bottomLeft:
            setFrameOrigin(NSPoint(x: screenFrame.minX + 20, y: screenFrame.minY + 20))
        case .bottomRight:
            setFrameOrigin(NSPoint(x: screenFrame.maxX - windowFrame.width - 20, y: screenFrame.minY + 20))
        case .center:
            center()
        }
    }
}

enum WindowPosition {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case center
}