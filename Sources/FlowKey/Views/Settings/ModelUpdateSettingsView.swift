import SwiftUI

struct ModelUpdateSettingsView: View {
    @State private var autoCheckEnabled = true
    @State private var autoDownloadEnabled = false
    @State private var autoInstallEnabled = false
    @State private var updateChannel = 0 // 0: stable, 1: beta, 2: nightly, 3: custom
    @State private var checkInterval = 24 // hours
    @State private var downloadOnlyOnWiFi = true
    @State private var maximumDownloadSize = 2 // GB
    @State private var notifyBeforeInstall = true
    @State private var backupBeforeUpdate = true
    
    @State private var isCheckingForUpdates = false
    @State private var isDownloading = false
    @State private var isInstalling = false
    @State private var updateInfo: ModelUpdateManager.UpdateInfo?
    @State private var updateHistory: [UpdateHistory] = []
    @State private var showUpdateAvailableAlert = false
    @State private var showUpdateCompletedAlert = false
    
    private let updateManager = ModelUpdateManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("自动更新设置")) {
                Toggle("自动检查更新", isOn: $autoCheckEnabled)
                    .onChange(of: autoCheckEnabled) { newValue in
                        updateConfiguration()
                    }
                
                if autoCheckEnabled {
                    Toggle("自动下载更新", isOn: $autoDownloadEnabled)
                        .onChange(of: autoDownloadEnabled) { newValue in
                            updateConfiguration()
                        }
                    
                    Toggle("自动安装更新", isOn: $autoInstallEnabled)
                        .onChange(of: autoInstallEnabled) { newValue in
                            updateConfiguration()
                        }
                }
            }
            
            Section(header: Text("更新渠道")) {
                Picker("更新渠道", selection: $updateChannel) {
                    Text("稳定版").tag(0)
                    Text("测试版").tag(1)
                    Text("每日构建").tag(2)
                    Text("自定义").tag(3)
                }
                .pickerStyle(.menu)
                .onChange(of: updateChannel) { newValue in
                    updateConfiguration()
                }
                
                if autoCheckEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("检查间隔: \(checkInterval) 小时")
                        Slider(value: Binding(
                            get: { Double(checkInterval) },
                            set: { checkInterval = Int($0) }
                        ), in: 1...168, step: 1)
                    }
                    .onChange(of: checkInterval) { newValue in
                        updateConfiguration()
                    }
                }
            }
            
            Section(header: Text("下载设置")) {
                Toggle("仅通过WiFi下载", isOn: $downloadOnlyOnWiFi)
                    .onChange(of: downloadOnlyOnWiFi) { newValue in
                        updateConfiguration()
                    }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("最大下载大小: \(maximumDownloadSize) GB")
                    Slider(value: Binding(
                        get: { Double(maximumDownloadSize) },
                        set: { maximumDownloadSize = Int($0) }
                    ), in: 0.5...10, step: 0.5)
                }
                .onChange(of: maximumDownloadSize) { newValue in
                    updateConfiguration()
                }
            }
            
            Section(header: Text("安装设置")) {
                Toggle("安装前通知", isOn: $notifyBeforeInstall)
                    .onChange(of: notifyBeforeInstall) { newValue in
                        updateConfiguration()
                    }
                
                Toggle("更新前备份", isOn: $backupBeforeUpdate)
                    .onChange(of: backupBeforeUpdate) { newValue in
                        updateConfiguration()
                    }
            }
            
            Section(header: Text("当前状态")) {
                if let info = updateInfo {
                    CurrentStatusView(updateInfo: info)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                HStack {
                    Button("检查更新") {
                        checkForUpdates()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isCheckingForUpdates)
                    
                    Spacer()
                    
                    if let available = updateInfo?.availableVersion {
                        Button("下载更新") {
                            downloadUpdate()
                        }
                        .buttonStyle(.bordered)
                        .disabled(isDownloading || updateInfo?.status != .available)
                    }
                }
                
                if isCheckingForUpdates {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if !updateHistory.isEmpty {
                Section(header: Text("更新历史")) {
                    ForEach(updateHistory, id: \.id) { history in
                        UpdateHistoryRow(history: history)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadSettings()
            loadUpdateInfo()
            loadUpdateHistory()
        }
        .alert("更新可用", isPresented: $showUpdateAvailableAlert) {
            Button("稍后") { }
            Button("立即下载") {
                if let version = updateInfo?.availableVersion {
                    downloadUpdate(version: version)
                }
            }
        } message: {
            if let version = updateInfo?.availableVersion {
                Text("发现新版本 \(version.version) 可用更新。\n\n\(version.description)")
            }
        }
        .alert("更新完成", isPresented: $showUpdateCompletedAlert) {
            Button("确定") { }
        } message: {
            Text("模型更新已完成！")
        }
    }
    
    private func loadSettings() {
        let config = updateManager.getUpdateConfiguration()
        
        autoCheckEnabled = config.autoCheckEnabled
        autoDownloadEnabled = config.autoDownloadEnabled
        autoInstallEnabled = config.autoInstallEnabled
        downloadOnlyOnWiFi = config.downloadOnlyOnWiFi
        maximumDownloadSize = Int(config.maximumDownloadSize / 1_000_000_000)
        notifyBeforeInstall = config.notifyBeforeInstall
        backupBeforeUpdate = config.backupBeforeUpdate
        
        // Set update channel
        switch config.updateChannel {
        case .stable: updateChannel = 0
        case .beta: updateChannel = 1
        case .nightly: updateChannel = 2
        case .custom: updateChannel = 3
        }
        
        // Set check interval
        checkInterval = Int(config.checkInterval / 3600)
    }
    
    private func updateConfiguration() {
        var config = ModelUpdateManager.UpdateConfiguration()
        
        config.autoCheckEnabled = autoCheckEnabled
        config.autoDownloadEnabled = autoDownloadEnabled
        config.autoInstallEnabled = autoInstallEnabled
        config.downloadOnlyOnWiFi = downloadOnlyOnWiFi
        config.maximumDownloadSize = Int64(maximumDownloadSize * 1_000_000_000)
        config.notifyBeforeInstall = notifyBeforeInstall
        config.backupBeforeUpdate = backupBeforeUpdate
        
        // Set update channel
        switch updateChannel {
        case 0: config.updateChannel = .stable
        case 1: config.updateChannel = .beta
        case 2: config.updateChannel = .nightly
        case 3: config.updateChannel = .custom
        default: config.updateChannel = .stable
        }
        
        // Set check interval
        config.checkInterval = TimeInterval(checkInterval * 3600)
        
        updateManager.setUpdateConfiguration(config)
    }
    
    private func loadUpdateInfo() {
        Task {
            let info = updateManager.getCurrentUpdateInfo()
            await MainActor.run {
                self.updateInfo = info
                
                // Show alert if update is available
                if info.status == .available && info.availableVersion != nil {
                    showUpdateAvailableAlert = true
                }
            }
        }
    }
    
    private func loadUpdateHistory() {
        Task {
            let history = await updateManager.getUpdateHistory()
            await MainActor.run {
                self.updateHistory = history
            }
        }
    }
    
    private func checkForUpdates() {
        isCheckingForUpdates = true
        
        Task {
            do {
                let info = try await updateManager.checkForUpdates()
                await MainActor.run {
                    self.updateInfo = info
                    self.isCheckingForUpdates = false
                    
                    // Show alert if update is available
                    if info.status == .available && info.availableVersion != nil {
                        showUpdateAvailableAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isCheckingForUpdates = false
                }
                print("Failed to check for updates: \(error)")
            }
        }
    }
    
    private func downloadUpdate() {
        guard let version = updateInfo?.availableVersion else { return }
        downloadUpdate(version: version)
    }
    
    private func downloadUpdate(version: ModelUpdateManager.ModelVersion) {
        isDownloading = true
        
        Task {
            do {
                try await updateManager.downloadUpdate(version)
                await MainActor.run {
                    self.isDownloading = false
                    self.loadUpdateInfo()
                }
            } catch {
                await MainActor.run {
                    self.isDownloading = false
                }
                print("Failed to download update: \(error)")
            }
        }
    }
    
    private func installUpdate() {
        guard let version = updateInfo?.availableVersion else { return }
        
        isInstalling = true
        
        Task {
            do {
                try await updateManager.installUpdate(version)
                await MainActor.run {
                    self.isInstalling = false
                    self.loadUpdateInfo()
                    self.showUpdateCompletedAlert = true
                }
            } catch {
                await MainActor.run {
                    self.isInstalling = false
                }
                print("Failed to install update: \(error)")
            }
        }
    }
}

struct CurrentStatusView: View {
    let updateInfo: ModelUpdateManager.UpdateInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("当前版本")
                Spacer()
                Text(updateInfo.currentVersion.version)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("更新状态")
                Spacer()
                Text(updateInfo.status.displayName)
                    .foregroundColor(statusColor)
            }
            
            if let available = updateInfo.availableVersion {
                HStack {
                    Text("可用版本")
                    Spacer()
                    Text(available.version)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("更新类型")
                    Spacer()
                    Text(available.updateType.displayName)
                        .foregroundColor(updateTypeColor)
                }
                
                HStack {
                    Text("文件大小")
                    Spacer()
                    Text(formatBytes(available.modelSize))
                        .foregroundColor(.secondary)
                }
            }
            
            if updateInfo.status == .downloading {
                VStack(alignment: .leading, spacing: 4) {
                    Text("下载进度")
                    ProgressView(value: updateInfo.downloadProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    Text("\(Int(updateInfo.downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if updateInfo.status == .installing {
                VStack(alignment: .leading, spacing: 4) {
                    Text("安装进度")
                    ProgressView(value: updateInfo.installProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    Text("\(Int(updateInfo.installProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var statusColor: Color {
        switch updateInfo.status {
        case .completed: return .green
        case .available: return .blue
        case .downloading, .installing: return .orange
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
    
    private var updateTypeColor: Color {
        guard let available = updateInfo.availableVersion else { return .secondary }
        
        switch available.updateType {
        case .critical: return .red
        case .major: return .orange
        case .minor: return .blue
        case .experimental: return .purple
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct UpdateHistoryRow: View {
    let history: UpdateHistory
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(history.version)
                    .font(.headline)
                Text(history.updateType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(history.installDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if history.success {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                
                if let errorMessage = history.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }
        }
    }
}

#Preview {
    ModelUpdateSettingsView()
}