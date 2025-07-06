import SwiftUI

// MainMenu 结构体定义了应用程序的主菜单界面
struct MainMenu: View {
    // 通过环境对象获取剪贴板处理器实例
    @EnvironmentObject var clipBoardHandler: ClipBoardHandler
    // 通过环境对象获取配置处理器实例
    @EnvironmentObject var configHandler: ConfigHandler
    // 用于跟踪当前选中的设置选项卡
    @State private var curretnTab = 0

    // 定义视图的主体内容
    var body: some View {
        // 遍历剪贴板历史记录，为每个记录创建一个菜单项
        ForEach(clipBoardHandler.history.indices, id: \.self) { id in
            // 创建剪贴板菜单项，显示历史记录中的内容
            ClipMenuItem(clip: clipBoardHandler.history[id], maxLength: configHandler.conf.previewLength)
        }
        // 添加分隔线
        Divider()
        // 添加清除按钮，点击后清空剪贴板历史
        Button("Clear") {
            clipBoardHandler.clear()
        }
        // 添加分隔线
        Divider()
        // 添加首选项按钮，点击后打开设置窗口
        Button("Preferences") {
            // 创建选项卡视图
            TabView(currentTab: $curretnTab)
                // 将配置处理器作为环境对象传递给子视图
                .environmentObject(configHandler)
                // 打开一个带有工具栏的新窗口
                .openNewWindowWithToolbar(
                    title: "ClipBoardManager", rect: NSRect(x: 0, y: 0, width: 450, height: 150),
                    style: [.closable, .titled], identifier: "Settings",
                    toolbar: Toolbar(tabs: ["About", "Settings"], currentTab: $curretnTab))
        }
        // 添加分隔线
        Divider()
        // 添加退出按钮，点击后退出应用程序
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}

// 预览提供者，用于在设计时预览 MainMenu 视图
struct MainMenu_Previews: PreviewProvider {
    static var previews: some View {
        // 创建 MainMenu 预览视图
        MainMenu()
            // 为预览提供必要的环境对象
            .environmentObject(ConfigHandler())
            .environmentObject(ClipBoardHandler(configHandler: ConfigHandler()))
    }
}
