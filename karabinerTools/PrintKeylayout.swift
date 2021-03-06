import Cocoa
import InputMethodKit
// Usage: Run the following command in the terminal
//  swift ./PrintKeylayout.swift

print("Your Mac Keylayout Settings ")
InputSource.print()


class InputSource {
    fileprivate static var inputSources: [TISInputSource] {
        let inputSourceNSArray = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
        return inputSourceNSArray as! [TISInputSource]
    }

    fileprivate static var selectCapableInputSources: [TISInputSource] {
        return inputSources.filter({ $0.isSelectCapable })
    }

    static func change(id: String) {
        guard let inputSource = selectCapableInputSources.filter({ $0.id == id }).first else { return }
        TISSelectInputSource(inputSource)
    }

    // 確認用
    static func print() {
        for source in inputSources {
            Swift.print("id:[\(source.id)]")
            Swift.print("localizedName:[\(source.localizedName)]")
            Swift.print("isSelectCapable:[\(source.isSelectCapable)]")
            Swift.print("isSelected:[\(source.isSelected)]")
            Swift.print("sourceLanguages:[\(source.sourceLanguages)]")
            Swift.print("--------------------")
        }
    }
}

extension TISInputSource {
    func getProperty(_ key: CFString) -> AnyObject? {
        guard let cfType = TISGetInputSourceProperty(self, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(cfType).takeUnretainedValue()
    }

    var id: String {
        return getProperty(kTISPropertyInputSourceID) as! String
    }

    var localizedName: String {
        return getProperty(kTISPropertyLocalizedName) as! String
    }

    var isSelectCapable: Bool {
        return getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
    }

    var isSelected: Bool {
        return getProperty(kTISPropertyInputSourceIsSelected) as! Bool
    }

    var sourceLanguages: [String] {
        return getProperty(kTISPropertyInputSourceLanguages) as! [String]
    }
}