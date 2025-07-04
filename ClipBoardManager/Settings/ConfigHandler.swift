import Combine
import Foundation
import ServiceManagement

// ConfigHandler类负责处理应用程序配置的读取、保存和更新
class ConfigHandler: ObservableObject {

    // 配置文件保存路径
    // ~/Library/Containers/com.Lennard.SettingsSwitfUI/Data/Library/"Application Support"/ClipBoardManager
    static let CONF_FILE = URL(
        fileURLWithPath:
            "\(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].path)/ClipBoardManager/ClipBoardManager.json"
    )
    // 发布的配置数据，UI组件将观察此属性的变化
    @Published var conf: ConfigData
    // 旧配置数据的副本，用于检测变化
    private var oldConf: ConfigData!  // necessary because removeDuplicates(by: ) does not work
    // 配置变更订阅
    private var configSink: Cancellable!

    // 初始化方法
    init() {
        // 尝试从配置文件读取配置，如果失败则使用默认配置
        conf = ConfigHandler.readCfg(from: ConfigHandler.CONF_FILE) ?? ConfigData()
        // 更新登录项状态
        updateAtLogin()
        // 创建配置副本
        oldConf = ConfigData(copy: conf)
        // 订阅配置变化，当配置改变时保存到文件
        configSink = $conf.sink(receiveValue: { conf in
            if conf == self.oldConf {
                return
            }
            ConfigHandler.writeCfg(conf, to: ConfigHandler.CONF_FILE)
            self.oldConf = ConfigData(copy: conf)
        })
    }

    // 更新登录项状态（检查应用是否已设置为登录项）
    private func updateAtLogin() {
        conf.atLogin = SMAppService.mainApp.status.rawValue == 1 ? true : false
    }

    // 应用登录项设置（根据配置启用或禁用登录项）
    func applyAtLognin() {
        if conf.atLogin {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }

    // 从文件读取配置数据
    static func readCfg(from file: URL) -> ConfigData? {
        if let data = try? Data(contentsOf: file) {
            let decoder = JSONDecoder()
            return try? decoder.decode(ConfigData.self, from: data)
        }
        return nil
    }

    // 将配置数据写入文件
    static func writeCfg(_ conf: ConfigData, to file: URL) {
        if let jsonData = try? JSONEncoder().encode(conf) {
            try? FileManager.default.createDirectory(
                atPath: file.deletingLastPathComponent().path, withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: file.path, contents: nil, attributes: nil)
            try? jsonData.write(to: file)
        }
    }
}
