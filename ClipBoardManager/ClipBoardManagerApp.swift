import SwiftUI

// 指定此App需要macOS 13.0或更高版本
@available(macOS 13.0, *)
// 标记这是应用程序的主入口点
@main
struct ClipBoardManagerApp: App {
    // 状态对象，用于存储和管理配置信息
    @StateObject private var configHandler: ConfigHandler
    // 状态对象，用于处理剪贴板操作和管理剪贴历史
    @StateObject private var clipBoardHandler: ClipBoardHandler
    // 用于跟踪当前选中的设置选项卡
    @State private var curretnTab = 0

    // 初始化方法
    init() {
        // 创建一个配置处理器
        let confH = ConfigHandler()
        // 初始化配置处理器状态对象
        self._configHandler = StateObject(wrappedValue: confH)
        // 初始化剪贴板处理器状态对象，并传入配置处理器
        self._clipBoardHandler = StateObject(wrappedValue: ClipBoardHandler(configHandler: confH))
    }

    // 定义应用程序的用户界面和行为
    var body: some Scene {
        // 创建一个菜单栏扩展（MenuBarExtra）
        MenuBarExtra(content: {
            // 显示主菜单
            MainMenu()
                // 将配置处理器作为环境对象传递给子视图
                .environmentObject(configHandler)
                // 将剪贴板处理器作为环境对象传递给子视图
                .environmentObject(clipBoardHandler)
        }) {
            // 在菜单栏中显示的图标（回形针图标）
            Image(systemName: "paperclip")
        }
    }
}
