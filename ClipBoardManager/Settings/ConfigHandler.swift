import Combine
import Foundation
import ServiceManagement

class ConfigHandler: ObservableObject {

    // ~/Library/Containers/com.Lennard.SettingsSwitfUI/Data/Library/"Application Support"/ClipBoardManager
    static let CONF_FILE = URL(
        fileURLWithPath:
            "\(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].path)/ClipBoardManager/ClipBoardManager.json"
    )
    @Published var conf: ConfigData
    private var oldConf: ConfigData!  // necessary because removeDuplicates(by: ) does not work
    private var configSink: Cancellable!

    init() {
        conf = ConfigHandler.readCfg(from: ConfigHandler.CONF_FILE) ?? ConfigData()
        updateAtLogin()
        oldConf = ConfigData(copy: conf)
        configSink = $conf.sink(receiveValue: { conf in
            if conf == self.oldConf {
                return
            }
            ConfigHandler.writeCfg(conf, to: ConfigHandler.CONF_FILE)
            self.oldConf = ConfigData(copy: conf)
        })
    }

    private func updateAtLogin() {
        conf.atLogin = SMAppService.mainApp.status.rawValue == 1 ? true : false
    }

    func applyAtLognin() {
        if conf.atLogin {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }

    static func readCfg(from file: URL) -> ConfigData? {
        if let data = try? Data(contentsOf: file) {
            let decoder = JSONDecoder()
            return try? decoder.decode(ConfigData.self, from: data)
        }
        return nil
    }

    static func writeCfg(_ conf: ConfigData, to file: URL) {
        if let jsonData = try? JSONEncoder().encode(conf) {
            try? FileManager.default.createDirectory(
                atPath: file.deletingLastPathComponent().path, withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: file.path, contents: nil, attributes: nil)
            try? jsonData.write(to: file)
        }
    }
}
