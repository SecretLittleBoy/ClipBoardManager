import Cocoa
import Combine

// ClipBoardHandler类用于处理剪贴板操作，监控剪贴板变化并保存剪贴历史
class ClipBoardHandler: ObservableObject {
    // 剪贴历史保存路径
    private let clippingsPath = URL(
        fileURLWithPath:
            "\(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].path)/ClipBoardManager/Clippings.json"
    )
    // 系统通用剪贴板
    private let clipBoard = NSPasteboard.general
    // 配置处理器
    private let configHandler: ConfigHandler
    // 排除的剪贴板类型列表
    private var excludedTypes = ["com.apple.finder.noderef"]
    // 额外要监控的剪贴板类型
    private var extraTypes = [
        NSPasteboard.PasteboardType("com.apple.icns"),
        NSPasteboard.PasteboardType("org.nspasteboard.source"),
    ]
    // 记录上一次剪贴板变化计数
    private var oldChangeCount: Int!
    // 访问锁，防止多线程同时访问导致的问题
    private var accessLock: NSLock
    // 发布的剪贴历史，UI将观察此属性
    @Published var history: [CBElement]!
    // 定时器，用于定期检查剪贴板变化
    private var timer: Timer!
    // 配置变更订阅
    private var configSink: Cancellable!
    // 历史容量
    var historyCapacity: Int

    // 初始化方法
    init(configHandler: ConfigHandler) {
        self.configHandler = configHandler
        historyCapacity = configHandler.conf.clippings
        oldChangeCount = clipBoard.changeCount
        history = []
        accessLock = NSLock()
        // 尝试从文件加载历史剪贴记录
        if let clippings = try? String(contentsOfFile: clippingsPath.path) {
            loadHistoryFromJSON(JSON: clippings)
        }
        // 在应用程序终止时保存剪贴历史
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { _ in
            let JSON = self.getHistoryAsJSON()
            try? JSON.write(
                toFile: self.clippingsPath.path, atomically: true, encoding: String.Encoding.utf8)
        }
        // 订阅配置变更
        configSink = configHandler.$conf.sink(receiveValue: { newConf in
            // 更新历史容量
            self.historyCapacity = newConf.clippings
            if self.history.count > self.historyCapacity {
                self.history.removeLast(self.history.count - self.historyCapacity)
            }

            // 如果刷新间隔发生变化，更新定时器
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

    // 定时刷新剪贴板的方法
    @objc func refreshClipBoard(_ sender: Any?) {
        read()
    }

    // 读取剪贴板内容
    func read() -> CBElement {
        accessLock.lock()
        // 检查剪贴板是否有变化
        if !updateChangeCount() {
            accessLock.unlock()
            return history.first ?? CBElement(string: "", isFile: false, content: [:])
        }
        var content: [NSPasteboard.PasteboardType: Data] = [:]
        var types = clipBoard.types
        types?.append(contentsOf: extraTypes)
        // 遍历剪贴板中所有可用类型
        for t in types ?? [] {
            if !excludedTypes.contains(t.rawValue) {
                if let data = clipBoard.data(forType: t) {
                    content[t] = data
                }
            }
        }
        // 如果没有源应用信息，添加当前前台应用作为源
        if content[NSPasteboard.PasteboardType("org.nspasteboard.source")] == nil {
            content[NSPasteboard.PasteboardType("org.nspasteboard.source")] = Data(
                NSWorkspace.shared.frontmostApplication?.bundleIdentifier?.utf8 ?? "".utf8)
        }
        // 判断剪贴内容是否为文件
        let isFile =
            content[NSPasteboard.PasteboardType.fileURL] != nil
            || content[NSPasteboard.PasteboardType.tiff] != nil
        // 获取字符串表示
        let string = clipBoard.string(forType: NSPasteboard.PasteboardType.string)
        // 如果是文件但没有图标，等待图标可用
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
        // 获取图标数据
        content[NSPasteboard.PasteboardType("com.apple.icns")] = clipBoard.data(
            forType: NSPasteboard.PasteboardType("com.apple.icns"))
        // 压缩图标数据
        if content[NSPasteboard.PasteboardType("com.apple.icns")] != nil {
            let image = NSBitmapImageRep(
                data: NSImage(
                    data: content[NSPasteboard.PasteboardType("com.apple.icns")] ?? Data())?
                    .resizeImage(tamanho: NSSize(width: 15, height: 15)).tiffRepresentation
                    ?? Data())?.representation(using: .png, properties: [:])
            content[NSPasteboard.PasteboardType("com.apple.icns")] = image
        }
        // 将新内容添加到历史开头
        history.insert(
            CBElement(string: string ?? "No Preview Found", isFile: isFile, content: content), at: 0
        )
        // 如果历史超出容量限制，移除多余项
        if history.count > historyCapacity {
            history.removeLast(history.count - historyCapacity)
        }
        accessLock.unlock()
        return history.first!
    }

    // 将指定的剪贴板元素写入系统剪贴板
    func write(entry: CBElement) {
        accessLock.lock()
        clipBoard.clearContents()
        for (t, d) in entry.content {
            clipBoard.setData(d, forType: t)
        }
        oldChangeCount = clipBoard.changeCount
        accessLock.unlock()
    }

    // 将历史中指定索引的元素写入系统剪贴板
    func write(historyIndex: Int) {
        write(entry: history[historyIndex])
    }

    // 清空剪贴历史
    func clear() {
        history.removeAll()
    }

    // 检查剪贴板是否有变化
    func haasChanged() -> Bool {
        return oldChangeCount != clipBoard.changeCount
    }

    // 更新剪贴板变化计数
    func updateChangeCount() -> Bool {
        if haasChanged() {
            oldChangeCount = clipBoard.changeCount
            return true
        }
        return false
    }

    // 将剪贴历史转换为JSON字符串
    func getHistoryAsJSON() -> String {
        let hs = history.map({ (e) in e.toMap() })
        if let jsonData = try? JSONSerialization.data(withJSONObject: hs, options: .prettyPrinted) {
            return String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        }
        return ""
    }

    // 从JSON字符串加载剪贴历史
    func loadHistoryFromJSON(JSON: String) {
        let decoded = try? JSONSerialization.jsonObject(
            with: JSON.data(using: String.Encoding.utf8) ?? Data(), options: [])
        if let arr = decoded as? [[String: String]] {
            for dict in arr {
                self.history.append(CBElement(from: dict))
            }
        }
    }

    // 调试方法：输出剪贴板所有类型的内容
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
