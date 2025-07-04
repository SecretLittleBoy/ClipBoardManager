import Cocoa
import Combine
import SwiftUI

// ClipBoardHandler 类负责管理剪贴板操作，包括监控、读取、写入剪贴板内容
class ClipBoardHandler: ObservableObject {
    // 剪贴板历史记录的保存路径
    // /Users/longyihao/Library/Containers/com.Lennard.ClipBoardManager/Data/Library/Application Support/ClipBoardManager/Clippings.json
    private let clippingsPath = URL(
        fileURLWithPath:
            "\(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].path)/ClipBoardManager/Clippings.json"
    )
    // 系统通用剪贴板
    private let clipBoard = NSPasteboard.general
    // 配置处理器引用
    private let configHandler: ConfigHandler
    // 需要排除的剪贴板类型列表
    private var excludedTypes = ["com.apple.finder.noderef"]
    // 额外监控的剪贴板类型列表
    private var extraTypes = [
        NSPasteboard.PasteboardType("com.apple.icns"),
        NSPasteboard.PasteboardType("org.nspasteboard.source"),
    ]
    // 上一次检测到的剪贴板变化计数
    private var oldChangeCount: Int!
    // 用于线程安全访问的锁
    private var accessLock: NSLock
    // 剪贴板历史记录，使用 @Published 让 SwiftUI 视图能够响应变化
    @Published var history: [CBElement]!
    // 定时器，用于定期检查剪贴板变化
    private var timer: Timer!
    // 用于监听配置变化的 Combine 订阅
    private var configSink: Cancellable!
    // 历史记录容量
    var historyCapacity: Int

    // 初始化方法
    init(configHandler: ConfigHandler) {
        self.configHandler = configHandler
        historyCapacity = configHandler.conf.clippings
        oldChangeCount = clipBoard.changeCount
        history = []
        accessLock = NSLock()
        // 尝试从保存的文件加载历史记录
        if let clippings = try? String(contentsOfFile: clippingsPath.path) {
            loadHistoryFromJSON(JSON: clippings)
        }
        // 添加应用程序退出时的通知监听，用于保存历史记录
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { _ in
            let JSON = self.getHistoryAsJSON()
            try? JSON.write(
                toFile: self.clippingsPath.path, atomically: true, encoding: String.Encoding.utf8)
        }
        // 订阅配置变化
        configSink = configHandler.$conf.sink(receiveValue: { newConf in
            // 更新历史记录容量
            self.historyCapacity = newConf.clippings
            // 如果历史记录超出新容量，删除多余项
            if self.history.count > self.historyCapacity {
                self.history.removeLast(self.history.count - self.historyCapacity)
            }

            // 如果刷新间隔有变化，更新定时器
            if self.timer?.timeInterval ?? -1 != TimeInterval(newConf.refreshIntervall)
                && newConf.refreshIntervall > 0
            {
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer(
                    timeInterval: TimeInterval(newConf.refreshIntervall), target: self,
                    selector: #selector(self.refreshClipBoard(_:)), userInfo: nil, repeats: true)
            }
        })
    }

    // 定时器调用的方法，用于刷新剪贴板
    @objc func refreshClipBoard(_ sender: Any?) {
        read()
    }

    // 读取当前剪贴板内容
    func read() {
        // 加锁确保线程安全
        accessLock.lock()
        // 检查剪贴板是否有变化，如果没有则返回历史记录中的第一项
        if !updateChangeCount() {
            accessLock.unlock()
            return
        }
        // 存储不同类型的剪贴板内容
        var content: [NSPasteboard.PasteboardType: Data] = [:]
        // 获取剪贴板中所有可用的类型
        var types = clipBoard.types
        types?.append(contentsOf: extraTypes)
        // 遍历所有类型，读取数据
        for t in types ?? [] {
            if !excludedTypes.contains(t.rawValue) {
                if let data = clipBoard.data(forType: t) {
                    content[t] = data
                }
            }
        }
        // 如果没有源应用信息，尝试添加前台应用的标识符
        if content[NSPasteboard.PasteboardType("org.nspasteboard.source")] == nil {
            content[NSPasteboard.PasteboardType("org.nspasteboard.source")] = Data(
                NSWorkspace.shared.frontmostApplication?.bundleIdentifier?.utf8 ?? "".utf8)
        }

        // 获取字符串表示
        let string = clipBoard.string(forType: NSPasteboard.PasteboardType.string)
        
        // 如果是文件但没有图标，等待图标数据（最多1秒）
        if content[NSPasteboard.PasteboardType.fileURL] != nil
            && content[NSPasteboard.PasteboardType("com.apple.icns")] == nil
        {
            var i = 0
            // 等待图标可用，但最多等待1秒
            while clipBoard.data(forType: NSPasteboard.PasteboardType("com.apple.icns")) == nil
                && i < 200 && !haasChanged()
            {
                usleep(5000)  // 等待0.005秒
                i += 1
            }
        }
        content[NSPasteboard.PasteboardType("com.apple.icns")] = clipBoard.data(forType: NSPasteboard.PasteboardType("com.apple.icns"))
        if content[NSPasteboard.PasteboardType("com.apple.icns")] == nil && content[NSPasteboard.PasteboardType.tiff] != nil {
            content[NSPasteboard.PasteboardType("com.apple.icns")] = content[NSPasteboard.PasteboardType.tiff]
        }
        
        // 压缩图标数据
        if content[NSPasteboard.PasteboardType("com.apple.icns")] != nil {
            let image = NSBitmapImageRep(
                data: NSImage(
                    data: content[NSPasteboard.PasteboardType("com.apple.icns")] ?? Data())?
                    .resizeImage(tamanho: NSSize(width: 15, height: 15)).tiffRepresentation
                    ?? Data())?.representation(using: .png, properties: [:])
            content[NSPasteboard.PasteboardType("com.apple.icns")] = image
        }
        // 创建新的剪贴板元素并添加到历史记录的开头
        history.insert(
            CBElement(string: string ?? "", content: content), at: 0
        )
        // 如果历史记录超出容量限制，删除多余项
        if history.count > historyCapacity {
            history.removeLast(history.count - historyCapacity)
        }
        accessLock.unlock()
    }

    // 将指定的剪贴板元素写入系统剪贴板
    func write(entry: CBElement) {
        accessLock.lock()
        // 清空当前剪贴板内容
        clipBoard.clearContents()
        // 写入所有保存的数据类型
        for (t, d) in entry.content {
            clipBoard.setData(d, forType: t)
        }
        // 更新变化计数
        oldChangeCount = clipBoard.changeCount
        accessLock.unlock()
    }

    // 将历史记录中指定索引的元素写入系统剪贴板
    func write(historyIndex: Int) {
        write(entry: history[historyIndex])
    }

    // 清空历史记录
    func clear() {
        history.removeAll()
    }

    // 检查剪贴板是否有变化
    func haasChanged() -> Bool {
        return oldChangeCount != clipBoard.changeCount
    }

    // 更新变化计数并返回是否有变化
    func updateChangeCount() -> Bool {
        if haasChanged() {
            oldChangeCount = clipBoard.changeCount
            return true
        }
        return false
    }

    // 将历史记录转换为JSON字符串
    func getHistoryAsJSON() -> String {
        let hs = history.map({ (e) in e.toMap() })
        if let jsonData = try? JSONSerialization.data(withJSONObject: hs, options: .prettyPrinted) {
            return String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        }
        return ""
    }

    // 从JSON字符串加载历史记录
    func loadHistoryFromJSON(JSON: String) {
        let decoded = try? JSONSerialization.jsonObject(
            with: JSON.data(using: String.Encoding.utf8) ?? Data(), options: [])
        if let arr = decoded as? [[String: String]] {
            for dict in arr {
                self.history.append(CBElement(from: dict))
            }
        }
    }

    // 调试方法：记录剪贴板的所有内容到控制台
    func logPasetBoard() {
        let logPB = { (name: String, t: NSPasteboard.PasteboardType) in
            print(name)
            print("Type: " + t.rawValue)
            print(self.clipBoard.pasteboardItems?[0].propertyList(forType: t) ?? "")
            print(self.clipBoard.pasteboardItems?[0].string(forType: t) ?? "")
            print(self.clipBoard.pasteboardItems?[0].data(forType: t) ?? "")
        }

        print(clipBoard.changeCount)
        print(logPB("pdf", NSPasteboard.PasteboardType.pdf))
        print(logPB("url", NSPasteboard.PasteboardType.URL))
        print(logPB("string", NSPasteboard.PasteboardType.string))
        print(logPB("fileContents", NSPasteboard.PasteboardType.fileContents))
        print(logPB("fileURL", NSPasteboard.PasteboardType.fileURL))
        print(logPB("findPanelSearchOptions", NSPasteboard.PasteboardType.findPanelSearchOptions))
        print(logPB("html", NSPasteboard.PasteboardType.html))
        print(logPB("multipleTextSelection", NSPasteboard.PasteboardType.multipleTextSelection))
        print(logPB("png", NSPasteboard.PasteboardType.png))
        print(logPB("rtf", NSPasteboard.PasteboardType.rtf))
        print(logPB("rtfd", NSPasteboard.PasteboardType.rtfd))
        print(logPB("ruler", NSPasteboard.PasteboardType.ruler))
        print(logPB("sound", NSPasteboard.PasteboardType.sound))
        print(logPB("tabularText", NSPasteboard.PasteboardType.tabularText))
        print(logPB("textFinderOptions", NSPasteboard.PasteboardType.textFinderOptions))
        print(logPB("tiff", NSPasteboard.PasteboardType.tiff))
        print(logPB("color", NSPasteboard.PasteboardType.color))
        print(logPB("font", NSPasteboard.PasteboardType.font))
        print(logPB("com.apple.icns", NSPasteboard.PasteboardType("com.apple.icns")))
        print(logPB("source", NSPasteboard.PasteboardType("org.nspasteboard.source")))
    }
}
