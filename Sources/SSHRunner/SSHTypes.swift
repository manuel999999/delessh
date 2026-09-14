import Foundation

enum SSHClientError: Error, LocalizedError {
    case invalidChannelType
    case notConnected
    case passwordAuthUnsupported

    var errorDescription: String? {
        switch self {
        case .invalidChannelType:
            "The SSH server offered an unexpected channel type."
        case .notConnected:
            "Not connected to a server."
        case .passwordAuthUnsupported:
            "The server does not support password authentication."
        }
    }
}
