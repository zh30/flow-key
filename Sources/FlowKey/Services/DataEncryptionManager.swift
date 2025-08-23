import Foundation
import CryptoKit

public class DataEncryptionManager {
    public static let shared = DataEncryptionManager()
    
    private init() {}
    
    // MARK: - Encryption
    
    public func encryptData(_ data: Data) throws -> Data {
        // Generate a random key for each encryption
        let key = SymmetricKey(size: .bits256)
        let sealedBox = try ChaChaPoly.seal(data, using: key)
        
        // Combine key and encrypted data
        var result = Data()
        result.append(key.withUnsafeBytes { Data($0) })
        result.append(sealedBox.combined)
        
        return result
    }
    
    public func decryptData(_ encryptedData: Data) throws -> Data {
        guard encryptedData.count >= 32 else {
            throw EncryptionError.invalidData
        }
        
        // Extract key and encrypted data
        let keyData = encryptedData.prefix(32)
        let encryptedContent = encryptedData.suffix(from: 32)
        
        let key = SymmetricKey(data: keyData)
        let sealedBox = try ChaChaPoly.SealedBox(combined: encryptedContent)
        
        return try ChaChaPoly.open(sealedBox, using: key)
    }
    
    public func encryptString(_ string: String) throws -> Data {
        let data = Data(string.utf8)
        return try encryptData(data)
    }
    
    public func decryptString(_ encryptedData: Data) throws -> String {
        let decryptedData = try decryptData(encryptedData)
        return String(data: decryptedData, encoding: .utf8) ?? ""
    }
    
    // MARK: - Hashing
    
    public func hashData(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    public func hashString(_ string: String) -> String {
        let data = Data(string.utf8)
        return hashData(data)
    }
}

public enum EncryptionError: Error, LocalizedError {
    case invalidData
    case encryptionFailed
    case decryptionFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid encrypted data"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        }
    }
}