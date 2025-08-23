import Foundation
import CryptoKit
import CommonCrypto

public class DataEncryptionManager {
    public static let shared = DataEncryptionManager()
    
    private init() {}
    
    // MARK: - Encryption Keys
    
    private var encryptionKey: SymmetricKey?
    private let keychainService = "com.flowkey.encryption"
    private let keychainAccount = "master_key"
    
    // MARK: - Public Methods
    
    public func initialize() throws {
        try loadOrCreateEncryptionKey()
    }
    
    public func encryptData(_ data: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw EncryptionError.keyNotAvailable
        }
        
        let sealedBox = try ChaChaPoly.seal(data, using: key)
        return sealedBox.combined
    }
    
    public func decryptData(_ encryptedData: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw EncryptionError.keyNotAvailable
        }
        
        let sealedBox = try ChaChaPoly.SealedBox(combined: encryptedData)
        return try ChaChaPoly.open(sealedBox, using: key)
    }
    
    public func encryptString(_ string: String) throws -> String {
        let data = Data(string.utf8)
        let encryptedData = try encryptData(data)
        return encryptedData.base64EncodedString()
    }
    
    public func decryptString(_ encryptedString: String) throws -> String {
        guard let data = Data(base64Encoded: encryptedString) else {
            throw EncryptionError.invalidData
        }
        
        let decryptedData = try decryptData(data)
        return String(data: decryptedData, encoding: .utf8) ?? ""
    }
    
    // MARK: - File Encryption
    
    public func encryptFile(at sourceURL: URL, to destinationURL: URL) throws {
        let data = try Data(contentsOf: sourceURL)
        let encryptedData = try encryptData(data)
        try encryptedData.write(to: destinationURL)
    }
    
    public func decryptFile(at sourceURL: URL, to destinationURL: URL) throws {
        let encryptedData = try Data(contentsOf: sourceURL)
        let decryptedData = try decryptData(encryptedData)
        try decryptedData.write(to: destinationURL)
    }
    
    // MARK: - Secure Deletion
    
    public func securelyDeleteFile(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return
        }
        
        // Overwrite the file with random data multiple times
        let fileHandle = try FileHandle(forWritingTo: url)
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64 ?? 0
        
        for _ in 0..<3 {
            let randomData = Data(count: Int(fileSize))
            _ = randomData.withUnsafeMutableBytes { ptr in
                guard let baseAddr = ptr.baseAddress else { return }
                let buffer = baseAddr.assumingMemoryBound(to: UInt8.self)
                for i in 0..<randomData.count {
                    buffer[i] = UInt8.random(in: 0...255)
                }
            }
            fileHandle.write(randomData)
            fileHandle.synchronizeFile()
        }
        
        fileHandle.closeFile()
        
        // Finally delete the file
        try FileManager.default.removeItem(at: url)
    }
    
    // MARK: - Privacy Protection
    
    public func anonymizeData(_ data: String) -> String {
        // Remove personal information patterns
        var anonymized = data
        
        // Remove email addresses
        anonymized = anonymized.replacingOccurrences(
            of: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}",
            with: "[EMAIL_REDACTED]",
            options: .regularExpression
        )
        
        // Remove phone numbers
        anonymized = anonymized.replacingOccurrences(
            of: "\\b\\d{3}[-.]?\\d{3}[-.]?\\d{4}\\b",
            with: "[PHONE_REDACTED]",
            options: .regularExpression
        )
        
        // Remove IP addresses
        anonymized = anonymized.replacingOccurrences(
            of: "\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b",
            with: "[IP_REDACTED]",
            options: .regularExpression
        )
        
        // Remove URLs
        anonymized = anonymized.replacingOccurrences(
            of: "https?://[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}[^\\s]*",
            with: "[URL_REDACTED]",
            options: .regularExpression
        )
        
        return anonymized
    }
    
    public func hashData(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Private Methods
    
    private func loadOrCreateEncryptionKey() throws {
        // Try to load existing key from keychain
        if let existingKey = try loadKeyFromKeychain() {
            encryptionKey = existingKey
            return
        }
        
        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        
        // Save to keychain
        try saveKeyToKeychain(newKey)
        
        encryptionKey = newKey
    }
    
    private func loadKeyFromKeychain() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let keyData = item as? Data else {
            if status == errSecItemNotFound {
                return nil
            }
            throw EncryptionError.keychainError(status)
        }
        
        return SymmetricKey(data: keyData)
    }
    
    private func saveKeyToKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrIsInvisible as String: true
        ]
        
        // Delete existing key first
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keychainError(status)
        }
    }
    
    // MARK: - Error Types
    
    public enum EncryptionError: Error, LocalizedError {
        case keyNotAvailable
        case invalidData
        case keychainError(OSStatus)
        case encryptionFailed
        case decryptionFailed
        
        public var errorDescription: String? {
            switch self {
            case .keyNotAvailable:
                return "Encryption key is not available"
            case .invalidData:
                return "Invalid data format"
            case .keychainError(let status):
                return "Keychain error: \(status)"
            case .encryptionFailed:
                return "Encryption failed"
            case .decryptionFailed:
                return "Decryption failed"
            }
        }
    }
}

// MARK: - Privacy Settings

public struct PrivacySettings {
    public let enableEncryption: Bool
    public let anonymizeLogs: Bool
    public let secureDeletion: Bool
    public let dataRetentionDays: Int
    public let allowAnalytics: Bool
    public let allowCrashReports: Bool
    
    public init(
        enableEncryption: Bool = true,
        anonymizeLogs: Bool = true,
        secureDeletion: Bool = true,
        dataRetentionDays: Int = 90,
        allowAnalytics: Bool = false,
        allowCrashReports: Bool = true
    ) {
        self.enableEncryption = enableEncryption
        self.anonymizeLogs = anonymizeLogs
        self.secureDeletion = secureDeletion
        self.dataRetentionDays = dataRetentionDays
        self.allowAnalytics = allowAnalytics
        self.allowCrashReports = allowCrashReports
    }
}

// MARK: - Privacy Manager

public class PrivacyManager {
    public static let shared = PrivacyManager()
    
    private let encryptionManager = DataEncryptionManager.shared
    private let coreDataManager = CoreDataManager.shared
    
    private init() {}
    
    // MARK: - Configuration
    
    public var settings: PrivacySettings = PrivacySettings()
    
    public func updateSettings(_ newSettings: PrivacySettings) {
        settings = newSettings
        saveSettingsToStorage()
    }
    
    // MARK: - Data Protection
    
    public func protectSensitiveData(_ data: String) throws -> String {
        guard settings.enableEncryption else { return data }
        return try encryptionManager.encryptString(data)
    }
    
    public func unprotectSensitiveData(_ encryptedData: String) throws -> String {
        guard settings.enableEncryption else { return encryptedData }
        return try encryptionManager.decryptString(encryptedData)
    }
    
    public func anonymizeForLogging(_ data: String) -> String {
        guard settings.anonymizeLogs else { return data }
        return encryptionManager.anonymizeData(data)
    }
    
    // MARK: - Data Management
    
    public func cleanupOldData() throws {
        try coreDataManager.cleanupOldData(olderThan: settings.dataRetentionDays)
    }
    
    public func securelyDeleteFile(at url: URL) throws {
        guard settings.secureDeletion else {
            try FileManager.default.removeItem(at: url)
            return
        }
        
        try encryptionManager.securelyDeleteFile(at: url)
    }
    
    // MARK: - Initialization
    
    public func initialize() throws {
        try encryptionManager.initialize()
        loadSettingsFromStorage()
        
        // Schedule periodic cleanup
        scheduleDataCleanup()
    }
    
    // MARK: - Private Methods
    
    private func saveSettingsToStorage() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(settings) {
            UserDefaults.standard.set(data, forKey: "FlowKeyPrivacySettings")
        }
    }
    
    private func loadSettingsFromStorage() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "FlowKeyPrivacySettings"),
           let loadedSettings = try? decoder.decode(PrivacySettings.self, from: data) {
            settings = loadedSettings
        }
    }
    
    private func scheduleDataCleanup() {
        // Schedule cleanup to run daily
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { _ in
            try? self.cleanupOldData()
        }
    }
}