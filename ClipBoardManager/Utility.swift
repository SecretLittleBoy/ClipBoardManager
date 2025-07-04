import SwiftUI

// 扩展View，添加打开新窗口的功能
extension View {

    // 查找具有特定标识符的窗口
    private func findWindowWithTag(identifier: String) -> NSWindow? {
        return NSApplication.shared.windows.filter({ $0.identifier?.rawValue == identifier }).first
    }

    // 打开一个带有工具栏的新窗口，如果窗口已存在则将其置于前台
    func openNewWindowWithToolbar(
        title: String, rect: NSRect, style: NSWindow.StyleMask, identifier: String = "",
        toolbar: some View
    ) -> NSWindow {
        // 如果提供了标识符，尝试查找已存在的窗口
        if !identifier.isEmpty {
            if let window = findWindowWithTag(identifier: identifier) {
                // 如果找到匹配的窗口，将其置于前台并返回
                window.orderFrontRegardless()
                return window
            }
        }

        // 创建工具栏视图，并调整边距
        let titlebarAccessoryView = toolbar.padding(.top, -5).padding(.leading, -8)

        // 创建托管视图来包含工具栏视图
        let accessoryHostingView = NSHostingView(rootView: titlebarAccessoryView)
        accessoryHostingView.frame.size = accessoryHostingView.fittingSize

        // 创建标题栏附件视图控制器
        let titlebarAccessory = NSTitlebarAccessoryViewController()
        titlebarAccessory.view = accessoryHostingView

        // 创建新窗口
        let window = NSWindow(
            contentRect: rect,
            styleMask: style,
            backing: .buffered,
            defer: false)
        // 窗口居中显示
        window.center()
        // 设置窗口标题
        window.title = title
        // 设置窗口关闭时不释放内存
        window.isReleasedWhenClosed = false
        // 设置窗口标识符
        window.identifier = NSUserInterfaceItemIdentifier(identifier)

        // 添加工具栏到窗口
        window.addTitlebarAccessoryViewController(titlebarAccessory)
        // 设置工具栏样式
        window.toolbarStyle = .preference

        // 设置窗口内容视图为当前视图
        window.contentView = NSHostingView(rootView: self)
        // 使窗口成为前台窗口并显示
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()

        return window
    }
}

// 扩展View，添加条件修改器
extension View {
    // 自定义修改器，根据条件应用变换
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content)
        -> some View
    {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// 扩展NSImage，添加调整图像大小的功能
extension NSImage {
    // 调整图像大小，保持宽高比
    func resizeImage(tamanho: NSSize) -> NSImage {

        var ratio: Float = 0.0
        let imageWidth = Float(self.size.width)
        let imageHeight = Float(self.size.height)
        let maxWidth = Float(tamanho.width)
        let maxHeight = Float(tamanho.height)

        // 获取比例（横向或纵向）
        if imageWidth > imageHeight {
            // 横向图像
            ratio = maxWidth / imageWidth
        } else {
            // 纵向图像
            ratio = maxHeight / imageHeight
        }

        // 根据比例计算新大小
        let newWidth = imageWidth * ratio
        let newHeight = imageHeight * ratio

        // 使用Core Graphics创建缩略图
        let imageSo = CGImageSourceCreateWithData(self.tiffRepresentation! as CFData, nil)
        let options: [NSString: NSObject] = [
            kCGImageSourceThumbnailMaxPixelSize: max(imageWidth, imageHeight) * ratio as NSObject,
            kCGImageSourceCreateThumbnailFromImageAlways: true as NSObject,
        ]
        let size1 = NSSize(width: Int(newWidth), height: Int(newHeight))
        // 创建缩略图并转换为NSImage
        let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSo!, 0, options as CFDictionary)
            .flatMap {
                NSImage(cgImage: $0, size: size1)
            }

        return scaledImage!
    }

}
