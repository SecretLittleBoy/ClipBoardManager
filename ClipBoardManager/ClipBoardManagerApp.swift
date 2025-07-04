import SwiftUI

// @available 表示这个应用程序需要 macOS 13.0 或更高版本
@available(macOS 13.0, *)
// @main 表示这是应用程序的入口点
@main
struct ClipBoardManagerApp: App {
    // 使用 @StateObject 创建并管理配置处理器实例，确保其生命周期与应用程序一致
    @StateObject private var configHandler: ConfigHandler
    // 使用 @StateObject 创建并管理剪贴板处理器实例，确保其生命周期与应用程序一致
    @StateObject private var clipBoardHandler: ClipBoardHandler
    // 用于跟踪当前选中的设置选项卡
    @State private var curretnTab = 0

    // 初始化方法，创建并配置必要的对象
    init() {
        // 首先创建配置处理器
        let confH = ConfigHandler()
        // 将配置处理器包装为 StateObject
        self._configHandler = StateObject(wrappedValue: confH)
        // 创建剪贴板处理器，并将配置处理器传递给它
        self._clipBoardHandler = StateObject(wrappedValue: ClipBoardHandler(configHandler: confH))
    }

    // 定义应用程序的界面结构
    var body: some Scene {
        // 创建一个菜单栏扩展图标，用户点击后会显示剪贴板历史
        MenuBarExtra(content: {
            // 主菜单视图
            MainMenu()
                // 将配置处理器作为环境对象传递给子视图
                .environmentObject(configHandler)
                // 将剪贴板处理器作为环境对象传递给子视图
                .environmentObject(clipBoardHandler)
        }) {
            // 菜单栏中显示的图标（回形针图标）
            Image(systemName: "paperclip")
        }
    }
}
