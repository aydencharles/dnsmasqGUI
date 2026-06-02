import SwiftUI

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @AppStorage("appLanguage") var selectedLanguage: String = "system" {
        didSet {
            NotificationCenter.default.post(name: Notification.Name("AppLanguageChanged"), object: nil)
        }
    }
    
    // Supported languages
    enum Language: String, CaseIterable, Identifiable {
        case system = "system"
        case english = "en"
        case chinese = "zh-Hans"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .system:
                return LanguageManager.shared.localize("System Language")
            case .english:
                return "English"
            case .chinese:
                return "简体中文"
            }
        }
        
        var nativeName: String {
            switch self {
            case .system:
                return LanguageManager.shared.localize("System Language")
            case .english:
                return "English"
            case .chinese:
                return "简体中文"
            }
        }
    }
    
    // Resolve the active language identifier
    var activeLanguageCode: String {
        if selectedLanguage == "system" {
            let preferred = Locale.preferredLanguages.first ?? "en"
            if preferred.hasPrefix("zh") {
                return "zh-Hans"
            }
            return "en"
        }
        return selectedLanguage
    }
    
    func localize(_ key: String) -> String {
        let lang = activeLanguageCode
        
        // Find the bundle for the language
        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to main bundle or just return key if not found
            return NSLocalizedString(key, comment: "")
        }
        
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    func localize(_ key: String, _ args: CVarArg...) -> String {
        let format = localize(key)
        return String(format: format, arguments: args)
    }
}

extension String {
    var localized: String {
        return LanguageManager.shared.localize(self)
    }
    
    func localized(_ args: CVarArg...) -> String {
        let format = LanguageManager.shared.localize(self)
        return String(format: format, arguments: args)
    }
}
