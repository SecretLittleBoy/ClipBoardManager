import Cocoa

// CBElement类定义了剪贴板中的一个元素
// 存储剪贴板内容及其相关信息
class CBElement: Equatable {
    // 唯一标识符，用于区分不同的剪贴板元素
    var id: UUID
    // 剪贴板内容的字符串表示
    var string: String
    // 标记是否为文件类型的剪贴板内容
    var isFile: Bool
    // 存储剪贴板内容的不同表示形式
    // 键为剪贴板内容类型，值为实际内容的二进制数据
    var content: [NSPasteboard.PasteboardType: Data]

    // 默认初始化方法
    init() {
        isFile = false
        string = ""
        content = [:]
        id = UUID()
    }

    // 从字典创建CBElement的便捷初始化方法
    // 用于从保存的JSON数据恢复剪贴板元素
    convenience init(from map: [String: String]) {
        self.init()
        string = map["string"] ?? ""
        isFile = map["isFile"] == "true"
        for (k, v) in map {
            if k != "string" && k != "isFile" {
                content[NSPasteboard.PasteboardType(k)] = Data(base64Encoded: v)
            }
        }
    }

    // 使用指定值初始化剪贴板元素
    init(string: String, isFile: Bool, content: [NSPasteboard.PasteboardType: Data]) {
        self.string = string
        self.isFile = isFile
        self.content = content
        id = UUID()
    }

    // 将剪贴板元素转换为字典表示
    // 用于将剪贴板元素保存到JSON
    func toMap() -> [String: String] {
        var stringDict: [String: String] = [:]
        stringDict["string"] = string
        stringDict["isFile"] = isFile ? "true" : "false"
        for (k, d) in content {
            stringDict[k.rawValue] = d.base64EncodedString()
        }
        return stringDict
    }

    // 实现Equatable协议的等价比较方法
    // 通过比较id判断两个剪贴板元素是否相同
    static func == (lhs: CBElement, rhs: CBElement) -> Bool {
        lhs.id == rhs.id
    }
}
