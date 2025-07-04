import SwiftUI

// View扩展，添加创建带工具栏的新窗口的功能
extension View {

    // 根据标识符查找已存在的窗口
    private func findWindowWithTag(identifier: String) -> NSWindow? {
        return NSApplication.shared.windows.filter({ $0.identifier?.rawValue == identifier }).first
    }

    // 打开一个带有自定义工具栏的新窗口
    // 如果指定了标识符且该标识符的窗口已存在，则返回现有窗口
    func openNewWindowWithToolbar(
        title: String, rect: NSRect, style: NSWindow.StyleMask, identifier: String = "",
        toolbar: some View
    ) -> NSWindow {
        // 如果提供了标识符，尝试查找已存在的窗口
        if !identifier.isEmpty {
            if let window = findWindowWithTag(identifier: identifier) {
                window.orderFrontRegardless()
                return window
            }
        }

        // 创建工具栏视图并应用填充
        let titlebarAccessoryView = toolbar.padding(.top, -5).padding(.leading, -8)

        // 将SwiftUI视图转换为NSHostingView
        let accessoryHostingView = NSHostingView(rootView: titlebarAccessoryView)
        accessoryHostingView.frame.size = accessoryHostingView.fittingSize

        // 创建标题栏附件控制器并设置视图
        let titlebarAccessory = NSTitlebarAccessoryViewController()
        titlebarAccessory.view = accessoryHostingView

        // 创建新窗口
        let window = NSWindow(
            contentRect: rect,
            styleMask: style,
            backing: .buffered,
            defer: false)
        window.center()
        window.title = title
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier(identifier)

        // 添加标题栏附件和设置工具栏样式
        window.addTitlebarAccessoryViewController(titlebarAccessory)
        window.toolbarStyle = .preference

        // 设置窗口内容视图为当前SwiftUI视图
        window.contentView = NSHostingView(rootView: self)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()

        return window
    }
}

// View扩展，添加条件性应用修饰符的功能
extension View {
    // 根据条件应用变换
    // 如果条件为真，应用提供的变换函数
    // 如果条件为假，返回原始视图
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

// NSImage扩展，添加图像调整大小的功能
extension NSImage {
    // 调整图像大小，保持宽高比
    func resizeImage(tamanho: NSSize) -> NSImage {

        var ratio: Float = 0.0
        let imageWidth = Float(self.size.width)
        let imageHeight = Float(self.size.height)
        let maxWidth = Float(tamanho.width)
        let maxHeight = Float(tamanho.height)

        // 获取缩放比例（横向或纵向）
        if imageWidth > imageHeight {
            // 横向图像
            ratio = maxWidth / imageWidth
        } else {
            // 纵向图像
            ratio = maxHeight / imageHeight
        }

        // 根据比例计算新尺寸
        let newWidth = imageWidth * ratio
        let newHeight = imageHeight * ratio

        // 使用Core Graphics创建缩略图
        let imageSo = CGImageSourceCreateWithData(self.tiffRepresentation! as CFData, nil)
        let options: [NSString: NSObject] = [
            kCGImageSourceThumbnailMaxPixelSize: max(imageWidth, imageHeight) * ratio as NSObject,
            kCGImageSourceCreateThumbnailFromImageAlways: true as NSObject,
        ]
        let size1 = NSSize(width: Int(newWidth), height: Int(newHeight))
        let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSo!, 0, options as CFDictionary)
            .flatMap {
                NSImage(cgImage: $0, size: size1)
            }

        return scaledImage!
    }
}
