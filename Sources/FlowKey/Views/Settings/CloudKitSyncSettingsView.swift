import SwiftUI

struct CloudKitSyncSettingsView: View {
    @StateObject private var syncManager = CloudKitSyncManager.shared
    @State private var settings = CloudKitSyncSettings()
    @State private var showConflictResolutionSheet = false
    @State private var showSyncDetails = false
    @State private var isCheckingAccount = false
    @State private var accountStatus: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("iCloud 同步")) {
                Toggle("启用 iCloud 同步", isOn: $settings.isEnabled)
                    .onChange(of: settings.isEnabled) { newValue in
                        Task {
                            if newValue {
                                await enableSync()
                            } else {
                                await syncManager.disableSync()
                            }
                        }
                    }
                
                if settings.isEnabled {
                    HStack {
                        Text("账户状态")
                        Spacer()
                        Text(accountStatus)
                            .foregroundColor(syncManager.isSyncEnabled ? .green : .red)
                    }
                    
                    HStack {
                        Text("同步状态")
                        Spacer()
                        Text(syncManager.syncStatus.displayName)
                            .foregroundColor(statusColor)
                    }
                    
                    if let lastSync = syncManager.lastSyncDate {
                        HStack {
                            Text("上次同步")
                            Spacer()
                            Text(lastSync.formatted())
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if syncManager.isSyncing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("同步中...")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let error = syncManager.syncError {
                        Text("错误: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            
            if settings.isEnabled {
                Section(header: Text("同步设置")) {
                    Toggle("自动同步", isOn: $settings.autoSync)
                    
                    if settings.autoSync {
                        Picker("同步间隔", selection: $settings.syncInterval) {
                            Text("5分钟").tag(300.0)
                            Text("15分钟").tag(900.0)
                            Text("30分钟").tag(1800.0)
                            Text("1小时").tag(3600.0)
                            Text("6小时").tag(21600.0)
                            Text("24小时").tag(86400.0)
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Toggle("启动时同步", isOn: $settings.syncOnLaunch)
                    Toggle("后台同步", isOn: $settings.syncOnBackground)
                }
                
                Section(header: Text("冲突解决")) {
                    HStack {
                        Text("解决策略")
                        Spacer()
                        Button(settings.conflictResolution.displayName) {
                            showConflictResolutionSheet = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Section(header: Text("同步操作")) {
                    HStack {
                        Button("立即同步") {
                            Task {
                                await performSync()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(syncManager.isSyncing)
                        
                        Spacer()
                        
                        Button("查看详情") {
                            showSyncDetails = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Section(header: Text("同步统计")) {
                    SyncStatisticsView(statistics: settings.syncStatistics)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadSettings()
        }
        .sheet(isPresented: $showConflictResolutionSheet) {
            ConflictResolutionSettingsView(
                currentStrategy: $settings.conflictResolution
            )
        }
        .sheet(isPresented: $showSyncDetails) {
            SyncDetailsView(settings: settings)
        }
    }
    
    // MARK: - Helper Properties
    
    private var statusColor: Color {
        switch syncManager.syncStatus {
        case .completed:
            return .green
        case .failed:
            return .red
        case .checkingAccount, .fetchingChanges, .uploadingChanges, .resolvingConflicts:
            return .blue
        case .notStarted:
            return .secondary
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadSettings() {
        // Load settings from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "CloudKitSyncSettings") {
            let decoder = JSONDecoder()
            if let loaded = try? decoder.decode(CloudKitSyncSettings.self, from: data) {
                settings = loaded
            }
        }
        
        checkAccountStatus()
    }
    
    private func checkAccountStatus() {
        isCheckingAccount = true
        
        Task {
            let isAvailable = await syncManager.checkCloudKitAvailability()
            
            await MainActor.run {
                accountStatus = isAvailable ? "可用" : "不可用"
                isCheckingAccount = false
            }
        }
    }
    
    private func enableSync() async {
        do {
            try await syncManager.enableSync()
            settings.isEnabled = true
            accountStatus = "已连接"
            saveSettings()
        } catch {
            print("Failed to enable sync: \(error)")
            settings.isEnabled = false
        }
    }
    
    private func performSync() async {
        do {
            try await syncManager.syncNow()
            settings.lastSyncDate = Date()
            saveSettings()
        } catch {
            print("Sync failed: \(error)")
        }
    }
    
    private func saveSettings() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(settings) {
            UserDefaults.standard.set(data, forKey: "CloudKitSyncSettings")
        }
    }
}

// MARK: - Sync Statistics View

struct SyncStatisticsView: View {
    let statistics: SyncStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("总同步次数")
                Spacer()
                Text("\(statistics.totalSyncs)")
            }
            
            HStack {
                Text("成功次数")
                Spacer()
                Text("\(statistics.successfulSyncs)")
                    .foregroundColor(.green)
            }
            
            HStack {
                Text("失败次数")
                Spacer()
                Text("\(statistics.failedSyncs)")
                    .foregroundColor(.red)
            }
            
            HStack {
                Text("成功率")
                Spacer()
                Text("\(String(format: "%.1f", statistics.successRate * 100))%")
                    .foregroundColor(statistics.successRate > 0.8 ? .green : .orange)
            }
            
            HStack {
                Text("上传记录")
                Spacer()
                Text("\(statistics.totalRecordsUploaded)")
            }
            
            HStack {
                Text("下载记录")
                Spacer()
                Text("\(statistics.totalRecordsDownloaded)")
            }
            
            HStack {
                Text("解决冲突")
                Spacer()
                Text("\(statistics.conflictsResolved)")
            }
        }
    }
}

// MARK: - Conflict Resolution Settings View

struct ConflictResolutionSettingsView: View {
    @Binding var currentStrategy: ConflictResolutionStrategy
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("选择冲突解决策略")) {
                    ForEach(ConflictResolutionStrategy.allCases, id: \.self) { strategy in
                        HStack {
                            Text(strategy.displayName)
                            Spacer()
                            if currentStrategy == strategy {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            currentStrategy = strategy
                        }
                    }
                }
                
                Section(header: Text("策略说明")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最新的获胜: 自动选择最新修改的版本")
                        Text("本地获胜: 始终保留本地版本")
                        Text("远程获胜: 始终保留远程版本")
                        Text("手动解决: 需要用户手动选择")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("冲突解决策略")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 300)
    }
}

// MARK: - Sync Details View

struct SyncDetailsView: View {
    let settings: CloudKitSyncSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("同步详情")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Group {
                        DetailRow(title: "启用状态", value: settings.isEnabled ? "是" : "否")
                        DetailRow(title: "自动同步", value: settings.autoSync ? "是" : "否")
                        DetailRow(title: "同步间隔", value: formatInterval(settings.syncInterval))
                        DetailRow(title: "启动时同步", value: settings.syncOnLaunch ? "是" : "否")
                        DetailRow(title: "后台同步", value: settings.syncOnBackground ? "是" : "否")
                        DetailRow(title: "冲突解决", value: settings.conflictResolution.displayName)
                        
                        if let lastSync = settings.lastSyncDate {
                            DetailRow(title: "上次同步", value: lastSync.formatted())
                        }
                    }
                    
                    Text("统计信息")
                        .font(.headline)
                        .padding(.top)
                    
                    SyncStatisticsView(statistics: settings.syncStatistics)
                }
                .padding()
            }
            .navigationTitle("同步详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Conflict Resolution Strategy Extension

extension ConflictResolutionStrategy: CaseIterable {}

#Preview {
    CloudKitSyncSettingsView()
}