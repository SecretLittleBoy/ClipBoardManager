import Foundation

// 重载等号操作符，用于比较两个ConfigData对象是否相等
func == (op1: ConfigData, op2: ConfigData) -> Bool {
    return op1.atLogin == op2.atLogin
        && op1.previewLength == op2.previewLength
        && op1.clippings == op2.clippings
        && (abs(op1.refreshIntervall - op2.refreshIntervall) < Float.ulpOfOne
            * abs(op1.refreshIntervall + op2.refreshIntervall))
}

// ConfigData类定义了应用程序的配置数据结构
// 实现了Decodable和Encodable协议，可以与JSON数据进行转换
final class ConfigData: Decodable, Encodable {
    // 剪贴历史容量（保存的剪贴板项目数量）
    var clippings: Int
    // 剪贴板刷新间隔（秒）
    var refreshIntervall: Float
    // 预览文本的最大长度（像素）
    var previewLength: Int
    // 是否在系统登录时启动应用
    var atLogin: Bool

    // 定义用于编码/解码的键
    enum CodingKeys: CodingKey {
        case clippings
        case refreshIntervall
        case previewLength
        case atLogin
    }

    // 从解码器创建ConfigData实例
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clippings = try container.decode(Int.self, forKey: .clippings)
        self.refreshIntervall = try container.decode(Float.self, forKey: .refreshIntervall)
        self.previewLength = try container.decode(Int.self, forKey: .previewLength)
        self.atLogin = try container.decode(Bool.self, forKey: .atLogin)
    }

    // 使用默认值初始化
    init() {
        clippings = 10        // 默认保存10个剪贴板项
        refreshIntervall = 0.5 // 默认0.5秒刷新一次
        previewLength = 300    // 默认预览长度300像素
        atLogin = false        // 默认不在登录时启动
    }

    // 从现有ConfigData对象复制创建新实例
    init(copy: ConfigData) {
        clippings = copy.clippings
        refreshIntervall = copy.refreshIntervall
        previewLength = copy.previewLength
        atLogin = copy.atLogin
    }
}
