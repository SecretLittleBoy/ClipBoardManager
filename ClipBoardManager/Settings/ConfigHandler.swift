import Combine
import Foundation
import ServiceManagement

// ConfigHandler类负责管理应用程序的配置，包括读取、写入和应用配置
class ConfigHandler: ObservableObject {

    // 配置文件的路径，保存在应用程序支持目录下
    // /Users/longyihao/Library/Containers/com.Lennard.ClipBoardManager/Data/Library/Application Support/ClipBoardManager/ClipBoardManager.json
    static let CONF_FILE = URL(
        fileURLWithPath:
            "\(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].path)/ClipBoardManager/ClipBoardManager.json"
    )
    // 当前配置，使用@Published让SwiftUI视图能够响应变化
    @Published var conf: ConfigData
    // 旧配置的引用，用于比较是否有变化（因为removeDuplicates(by: )不能正常工作）
    private var oldConf: ConfigData!
    // 用于监听配置变化的Combine订阅
    private var configSink: Cancellable!

    // 初始化方法
    init() {
        // 尝试从配置文件读取配置，如果失败则创建默认配置
        conf = ConfigHandler.readCfg(from: ConfigHandler.CONF_FILE) ?? ConfigData()
        // 更新登录项状态
        updateAtLogin()
        // 保存当前配置的副本用于比较
        oldConf = ConfigData(copy: conf)
        // 订阅配置变化，当配置改变时保存到文件
        configSink = $conf.sink(receiveValue: { conf in
            // 如果配置没有变化，不做任何操作
            if conf == self.oldConf {
                return
            }
            // 保存配置到文件
            ConfigHandler.writeCfg(conf, to: ConfigHandler.CONF_FILE)
            // 更新旧配置的副本
            self.oldConf = ConfigData(copy: conf)
        })
    }

    // 更新登录时启动的设置，从系统设置中读取当前状态
    private func updateAtLogin() {
        // 检查应用程序是否已注册为登录项
        conf.atLogin = SMAppService.mainApp.status.rawValue == 1 ? true : false
    }

    // 应用登录时启动的设置
    func applyAtLognin() {
        if conf.atLogin {
            // 如果需要登录时启动，注册应用程序为登录项
            try? SMAppService.mainApp.register()
        } else {
            // 如果不需要登录时启动，取消注册
            try? SMAppService.mainApp.unregister()
        }
    }

    // 从文件读取配置
    static func readCfg(from file: URL) -> ConfigData? {
        if let data = try? Data(contentsOf: file) {
            let decoder = JSONDecoder()
            return try? decoder.decode(ConfigData.self, from: data)
        }
        return nil
    }

    // 将配置写入文件
    static func writeCfg(_ conf: ConfigData, to file: URL) {
        if let jsonData = try? JSONEncoder().encode(conf) {
            // 确保目录存在
            try? FileManager.default.createDirectory(
                atPath: file.deletingLastPathComponent().path, withIntermediateDirectories: true)
            // 创建文件
            FileManager.default.createFile(atPath: file.path, contents: nil, attributes: nil)
            // 写入数据
            try? jsonData.write(to: file)
        }
    }
}
