import SwiftUI

// ClipMenuItem 结构体用于显示剪贴板历史中的单个项目，作为菜单中的一个条目
struct ClipMenuItem: View {
    // 通过环境对象获取剪贴板处理器实例
    @EnvironmentObject private var clipBoardHandler: ClipBoardHandler
    // 剪贴板元素，包含需要显示的内容
    var clip: CBElement
    // 预览文本的最大长度
    var maxLength: Int
    // 处理后的预览文本
    var preview: String
    // 剪贴板内容相关的图标
    var img: Image?

    // 初始化方法，创建一个剪贴板菜单项
    init(clip: CBElement, maxLength: Int) {
        self.clip = clip
        self.maxLength = maxLength
        // 计算并设置图标
        self.img = ClipMenuItem.calcImage(clip: clip)
        // 计算并设置预览文本，传递hasIcon参数
        self.preview = ClipMenuItem.calcTitel(clip: clip, maxLength: maxLength, hasIcon: self.img != nil)
    }

    // 定义视图的主体内容
    var body: some View {
        // 创建一个按钮，点击后将该剪贴板元素写入到系统剪贴板
        Button(action: {
            clipBoardHandler.write(entry: clip)
        }) {
            // 水平排列图标和文本
            HStack {
                // 只有img不为nil时才显示图标
                if let img = img {
                    img
                        .resizable()
                        .frame(width: 15, height: 15)
                }
                // 显示预览文本
                Text(preview)
            }
        }
    }
    
    // 静态方法，根据剪贴板元素计算显示的图标
    private static func calcImage(clip: CBElement) -> Image? {
        // 如果是文件但没有图标数据，则显示文档图标
        if clip.isFile && clip.content[NSPasteboard.PasteboardType("com.apple.icns")] == nil
            && clip.content[NSPasteboard.PasteboardType.tiff] == nil
        {
            return Image(systemName: "doc.fill")
        }
        // 创建一个空的NSImage对象
        var nsImage = NSImage()
        // 尝试从TIFF数据创建图像
        if let image = clip.content[NSPasteboard.PasteboardType.tiff] {
            nsImage = NSImage(data: image) ?? NSImage()
        } else if let icnsData = clip.content[NSPasteboard.PasteboardType("com.apple.icns")] {
            // 尝试从ICNS数据创建图像
            nsImage = NSImage(data: icnsData) ?? NSImage()
        }
        // 如果nsImage没有有效内容，返回nil
        if nsImage.representations.isEmpty {
            return nil
        }
        // 设置图像大小为15x15
        nsImage.size = NSSize(width: 15, height: 15)
        // 返回SwiftUI的Image
        return Image(nsImage: nsImage)
    }

    // 静态方法，根据剪贴板元素和最大长度计算预览文本
    private static func calcTitel(clip: CBElement, maxLength: Int, hasIcon: Bool) -> String {
        // 获取剪贴板文本
        var menuTitel = clip.string
        var maxLengthFloat = CGFloat(maxLength)
        // 如果有图标，则最大长度减去图标宽度
        if hasIcon {
            maxLengthFloat -= 15
        }
        // 移除首尾的空白字符
        menuTitel = menuTitel.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        // 将换行符替换为点号
        menuTitel = menuTitel.replacingOccurrences(of: "\n", with: "•")
        // 用于计算字符宽度的参考字符
        let pipe = "|"
        // 获取系统字体大小
        let systemFontSize = NSFont.systemFontSize
        // 获取系统字体
        let systemFont = NSFont.systemFont(ofSize: systemFontSize)
        // 设置字体属性
        let attributes = [NSAttributedString.Key.font: systemFont]
        // 创建参考字符的属性字符串
        let pipeAttrString = NSAttributedString(string: pipe, attributes: attributes)
        // 计算最小字符宽度
        let minCharWidth = pipeAttrString.size().width
        // 估计可显示的字符数量
        let estimatedLength = Int(maxLengthFloat / minCharWidth) + 1
        // 截取估计长度的文本
        menuTitel = String(menuTitel.prefix(estimatedLength))
        // 创建当前文本的属性字符串
        var attrString = NSAttributedString(string: menuTitel, attributes: attributes)
        // 计算当前文本宽度
        var width = attrString.size().width
        // 判断是否需要添加省略号
        let addDots = width > maxLengthFloat

        // 如果文本宽度超过最大宽度，逐个删除字符直到合适
        while width > maxLengthFloat && !menuTitel.isEmpty {
            menuTitel = String(menuTitel.dropLast())
            attrString = NSAttributedString(string: menuTitel, attributes: attributes)
            width = attrString.size().width
        }

        // 如果需要，添加省略号表示文本被截断
        if addDots {
            menuTitel.append("...")
        }

        return menuTitel
    }
}

// 预览提供者，用于在设计时预览 ClipMenuItem 视图
struct ClipMenuItem_Previews: PreviewProvider {
    static var previews: some View {
        // 创建 ClipMenuItem 预览视图
        ClipMenuItem(clip: CBElement(), maxLength: 40)
            // 为预览提供必要的环境对象
            .environmentObject(ClipBoardHandler(configHandler: ConfigHandler()))
    }
}
