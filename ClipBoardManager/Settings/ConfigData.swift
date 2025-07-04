import Foundation

// 比较两个ConfigData对象是否相等的操作符重载
func == (op1: ConfigData, op2: ConfigData) -> Bool {
    return op1.atLogin == op2.atLogin
        && op1.previewLength == op2.previewLength
        && op1.clippings == op2.clippings
        && (abs(op1.refreshIntervall - op2.refreshIntervall) < Float.ulpOfOne
            * abs(op1.refreshIntervall + op2.refreshIntervall))
}

// ConfigData类用于存储应用程序的配置数据
final class ConfigData: Decodable, Encodable {
    // 剪贴板历史记录的最大数量
    var clippings: Int
    // 刷新剪贴板的时间间隔（秒）
    var refreshIntervall: Float
    // 菜单中预览文本的最大长度（像素）
    var previewLength: Int
    // 是否在登录时启动应用程序
    var atLogin: Bool

    // 定义编码和解码的键
    enum CodingKeys: CodingKey {
        case clippings
        case refreshIntervall
        case previewLength
        case atLogin
    }

    // 从解码器中创建实例的初始化方法
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clippings = try container.decode(Int.self, forKey: .clippings)
        self.refreshIntervall = try container.decode(Float.self, forKey: .refreshIntervall)
        self.previewLength = try container.decode(Int.self, forKey: .previewLength)
        self.atLogin = try container.decode(Bool.self, forKey: .atLogin)
    }

    // 默认初始化方法，设置默认值
    init() {
        clippings = 10  // 默认保存10个剪贴板历史
        refreshIntervall = 0.5  // 默认每0.5秒刷新一次
        previewLength = 300  // 默认预览长度为300像素
        atLogin = false  // 默认不在登录时启动
    }

    // 复制另一个ConfigData对象的初始化方法
    init(copy: ConfigData) {
        clippings = copy.clippings
        refreshIntervall = copy.refreshIntervall
        previewLength = copy.previewLength
        atLogin = copy.atLogin
    }
}
