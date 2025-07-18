import Cocoa

// CBElement 类表示剪贴板中的一个元素，存储剪贴板内容及其元数据
class CBElement: Equatable {
    // 复制次数计数
    var count: Int64
    // 剪贴板内容的字符串表示，用于显示预览
    var string: String
    // 存储剪贴板的所有格式数据，键为格式类型，值为对应的二进制数据
    var content: [NSPasteboard.PasteboardType: Data]

    // 默认构造函数，创建一个空的剪贴板元素
    init() {
        count = 0
        string = ""
        content = [:]
    }

    // 便利构造函数，从字典映射中创建剪贴板元素（用于从JSON数据恢复）
    convenience init(from map: [String: String]) {
        self.init()
        count = Int64(map["count"] ?? "0") ?? 0
        string = map["string"] ?? ""
        for (k, v) in map {
            if k != "string" && k != "count" {
                // 将Base64编码的字符串转换回原始数据
                content[NSPasteboard.PasteboardType(k)] = Data(base64Encoded: v)
            }
        }
    }

    // 完整构造函数，使用给定的值创建剪贴板元素
    init(count: Int64, string: String, content: [NSPasteboard.PasteboardType: Data]) {
        self.count = count
        self.string = string
        self.content = content
    }

    // 将剪贴板元素转换为字典映射（用于JSON序列化和存储）
    func toMap() -> [String: String] {
        var stringDict: [String: String] = [:]
        stringDict["count"] = String(count)
        stringDict["string"] = string
        for (k, d) in content {
            // 将二进制数据转换为Base64编码的字符串以便存储
            stringDict[k.rawValue] = d.base64EncodedString()
        }
        return stringDict
    }

    // 实现Equatable协议，用于比较两个剪贴板元素是否相同
    static func == (lhs: CBElement, rhs: CBElement) -> Bool {
        // if file or snapshot compare all content
        if lhs.content[NSPasteboard.PasteboardType.fileURL] != nil
            || lhs.content[NSPasteboard.PasteboardType.tiff] != nil
            || rhs.content[NSPasteboard.PasteboardType.fileURL] != nil
            || rhs.content[NSPasteboard.PasteboardType.tiff] != nil
        {
            return lhs.content == rhs.content
        } else {
            return lhs.string == rhs.string
        }
    }
}
