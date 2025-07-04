import SwiftUI

// ClipMenuItem结构体定义了菜单中每个剪贴板项的视图
struct ClipMenuItem: View {
    // 从环境中获取剪贴板处理器
    @EnvironmentObject private var clipBoardHandler: ClipBoardHandler
    // 当前菜单项对应的剪贴板元素
    var clip: CBElement
    // 预览文本的最大长度
    var maxLength: Int
    // 计算好的预览文本
    var preview: String
    // 计算好的图标
    var img: Image

    // 初始化方法
    init(clip: CBElement, maxLength: Int) {
        self.clip = clip
        self.maxLength = maxLength
        // 计算菜单项的预览文本
        self.preview = ClipMenuItem.calcTitel(clip: clip, maxLength: maxLength)
        // 计算菜单项的图标
        self.img = ClipMenuItem.calcImage(clip: clip)
    }

    // 视图内容
    var body: some View {
        // 创建一个按钮，点击时将对应的剪贴板元素写入系统剪贴板
        Button(action: {
            clipBoardHandler.write(entry: clip)
        }) {
            // 水平排列图标和文本
            HStack {
                img
                    .resizable()
                    .frame(width: 15, height: 15)
                Text(preview)

            }
        }
    }

    // 根据剪贴板元素计算菜单项图标
    private static func calcImage(clip: CBElement) -> Image {
        // 如果是文件类型但没有图标数据，使用文档图标
        if clip.isFile && clip.content[NSPasteboard.PasteboardType("com.apple.icns")] == nil
            && clip.content[NSPasteboard.PasteboardType.tiff] == nil
        {
            return Image(systemName: "doc.fill")
        }
        // 创建NSImage对象
        var nsImage = NSImage()
        // 优先使用TIFF格式的图像数据
        if let image = clip.content[NSPasteboard.PasteboardType.tiff] {
            nsImage = NSImage(data: image) ?? NSImage()
        } else {
            // 否则使用Apple图标数据
            nsImage =
                NSImage(data: clip.content[NSPasteboard.PasteboardType("com.apple.icns")] ?? Data())
                ?? NSImage()
        }
        // 设置图像大小
        nsImage.size = NSSize(width: 15, height: 15)
        return Image(nsImage: nsImage)
    }

    // 根据剪贴板元素和最大长度计算菜单项显示的文本
    private static func calcTitel(clip: CBElement, maxLength: Int) -> String {
        var menuTitel = clip.string
        let maxLengthFloat = CGFloat(maxLength)
        // 移除前后空白字符
        menuTitel = menuTitel.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        // 将换行符替换为圆点
        menuTitel = menuTitel.replacingOccurrences(of: "\n", with: "•")
        let pipe = "|"
        // 获取系统字体大小和字体
        let systemFontSize = NSFont.systemFontSize
        let systemFont = NSFont.systemFont(ofSize: systemFontSize)
        let attributes = [NSAttributedString.Key.font: systemFont]
        // 创建一个竖线的富文本，用于估算单个字符的宽度
        let pipeAttrString = NSAttributedString(string: pipe, attributes: attributes)
        let minCharWidth = pipeAttrString.size().width
        // 估算可显示的字符数量
        let estimatedLength = Int(maxLengthFloat / minCharWidth) + 1
        // 截取估算长度的字符串
        menuTitel = String(menuTitel.prefix(estimatedLength))
        // 创建富文本以计算实际宽度
        var attrString = NSAttributedString(string: menuTitel, attributes: attributes)
        var width = attrString.size().width
        // 判断是否需要添加省略号
        let addDots = width > maxLengthFloat

        // 如果宽度超过最大宽度，逐个移除末尾字符直到适合
        while width > maxLengthFloat && !menuTitel.isEmpty {
            menuTitel = String(menuTitel.dropLast())
            attrString = NSAttributedString(string: menuTitel, attributes: attributes)
            width = attrString.size().width
        }

        // 如果原文本被截断，添加省略号
        if addDots {
            menuTitel.append("...")
        }

        return menuTitel
    }
}

// 预览提供者，用于在Xcode中预览ClipMenuItem
struct ClipMenuItem_Previews: PreviewProvider {
    static var previews: some View {
        ClipMenuItem(clip: CBElement(), maxLength: 40)
            .environmentObject(ClipBoardHandler(configHandler: ConfigHandler()))
    }
}
