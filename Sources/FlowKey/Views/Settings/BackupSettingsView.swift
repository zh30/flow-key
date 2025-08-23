import SwiftUI

struct BackupSettingsView: View {
    @State private var availableBackups: [BackupInfo] = []
    @State private var isLoading = false
    @State private var isCreatingBackup = false
    @State private var backupProgress: Double = 0.0
    @State private var showRestoreAlert = false
    @State private var selectedBackup: BackupInfo?
    @State private var restoreResult: RestoreResult?
    @State private var showRestoreResult = false
    
    private let backupManager = BackupManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("数据备份与恢复")
                    .font(.headline)
                Spacer()
                
                Button(action: {
                    createBackup()
                }) {
                    Label("创建备份", systemImage: "plus.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCreatingBackup)
            }
            .padding()
            
            Divider()
            
            if isCreatingBackup {
                VStack(spacing: 16) {
                    ProgressView(value: backupProgress, total: 100.0)
                        .progressViewStyle(.linear)
                    
                    Text("正在创建备份...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if availableBackups.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "externaldrive.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("没有可用的备份")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("点击\"创建备份\"按钮来创建您的第一个数据备份")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Backup List
                List(availableBackups) { backup in
                    BackupRowView(backup: backup) {
                        selectedBackup = backup
                        showRestoreAlert = true
                    } onDelete: {
                        deleteBackup(backup)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            loadBackups()
        }
        .alert("恢复备份", isPresented: $showRestoreAlert) {
            Button("取消", role: .cancel) { }
            Button("恢复") {
                if let backup = selectedBackup {
                    restoreBackup(backup)
                }
            }
        } message: {
            Text("确定要从备份恢复数据吗？这将覆盖当前的所有数据。")
        }
        .sheet(isPresented: $showRestoreResult) {
            if let result = restoreResult {
                RestoreResultView(result: result) {
                    showRestoreResult = false
                }
            }
        }
    }
    
    private func loadBackups() {
        isLoading = true
        
        Task {
            do {
                let backups = try await backupManager.getAvailableBackups()
                await MainActor.run {
                    self.availableBackups = backups
                    self.isLoading = false
                }
            } catch {
                print("Failed to load backups: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func createBackup() {
        isCreatingBackup = true
        backupProgress = 0.0
        
        Task {
            do {
                // Simulate progress
                for i in 0..<100 {
                    try await Task.sleep(nanoseconds: 50_000_000)
                    await MainActor.run {
                        backupProgress = Double(i)
                    }
                }
                
                let backup = try await backupManager.createBackup()
                await MainActor.run {
                    backupProgress = 100.0
                    isCreatingBackup = false
                    loadBackups()
                }
                
                // Show success notification
                await MainActor.run {
                    let alert = NSAlert()
                    alert.messageText = "备份创建成功"
                    alert.informativeText = "备份文件: \(backup.fileName)"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "确定")
                    alert.runModal()
                }
            } catch {
                await MainActor.run {
                    isCreatingBackup = false
                    backupProgress = 0.0
                    
                    let alert = NSAlert()
                    alert.messageText = "备份创建失败"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "确定")
                    alert.runModal()
                }
            }
        }
    }
    
    private func restoreBackup(_ backup: BackupInfo) {
        isLoading = true
        
        Task {
            do {
                let result = try await backupManager.restoreBackup(from: backup.fileURL)
                await MainActor.run {
                    self.restoreResult = result
                    self.isLoading = false
                    self.showRestoreResult = true
                    self.loadBackups()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    
                    let alert = NSAlert()
                    alert.messageText = "备份恢复失败"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "确定")
                    alert.runModal()
                }
            }
        }
    }
    
    private func deleteBackup(_ backup: BackupInfo) {
        let alert = NSAlert()
        alert.messageText = "删除备份"
        alert.informativeText = "确定要删除备份\"\(backup.fileName)\"吗？此操作无法撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "取消")
        alert.addButton(withTitle: "删除")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            Task {
                do {
                    try backupManager.deleteBackup(backup)
                    await MainActor.run {
                        loadBackups()
                    }
                } catch {
                    print("Failed to delete backup: \(error)")
                }
            }
        }
    }
}

// MARK: - Backup Row View

struct BackupRowView: View {
    let backup: BackupInfo
    let onRestore: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(backup.fileName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(formatDate(backup.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatFileSize(backup.size))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        if backup.isEncrypted {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        Text(backup.version)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack {
                Button(action: onRestore) {
                    Label("恢复", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button(action: onDelete) {
                    Label("删除", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Restore Result View

struct RestoreResultView: View {
    let result: RestoreResult
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("恢复完成")
                .font(.headline)
            
            if result.success {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                VStack(spacing: 8) {
                    Text("成功恢复了 \(result.itemsRestored) 项数据")
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    Text("恢复时间: \(formatDate(result.timestamp))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("恢复失败")
                    .font(.body)
                    .foregroundColor(.red)
            }
            
            Button("确定") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 300, height: 250)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}