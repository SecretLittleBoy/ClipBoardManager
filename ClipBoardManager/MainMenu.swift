import SwiftUI

// MainMenu结构体定义了应用程序的主菜单界面
struct MainMenu: View {
    // 从环境中获取剪贴板处理器，用于访问剪贴历史和操作剪贴板
    @EnvironmentObject var clipBoardHandler: ClipBoardHandler
    // 从环境中获取配置处理器，用于访问用户配置
    @EnvironmentObject var configHandler: ConfigHandler
    // 用于跟踪当前选中的设置选项卡
    @State private var curretnTab = 0

    // 定义视图的内容和布局
    var body: some View {
        //TODO: this always recreates all ClipMenuItem when the history changes, which is not ideal.
        // 遍历剪贴板历史记录，为每个条目创建一个菜单项
        ForEach(clipBoardHandler.history.indices, id: \.self) { id in
            ClipMenuItem(
                clip: CBElement(
                    string: clipBoardHandler.history[id].string,
                    isFile: clipBoardHandler.history[id].isFile,
                    content: clipBoardHandler.history[id].content),
                maxLength: configHandler.conf.previewLength)
        }
        // 添加分隔线
        Divider()
        // 清除按钮，点击时清空剪贴板历史
        Button("Clear") {
            clipBoardHandler.clear()
        }.keyboardShortcut("l") // 键盘快捷键：Command+L
        // 添加分隔线
        Divider()
        // 首选项按钮，点击时打开设置窗口
        Button("Preferences") {
            TabView(currentTab: $curretnTab)
                .environmentObject(configHandler)
                .openNewWindowWithToolbar(
                    title: "ClipBoardManager", rect: NSRect(x: 0, y: 0, width: 450, height: 150),
                    style: [.closable, .titled], identifier: "Settings",
                    toolbar: Toolbar(tabs: ["About", "Settings"], currentTab: $curretnTab))
        }.keyboardShortcut(",") // 键盘快捷键：Command+,
        // 添加分隔线
        Divider()
        // 退出按钮，点击时关闭应用程序
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q") // 键盘快捷键：Command+Q
    }
}

// 预览提供者，用于在Xcode中预览MainMenu
struct MainMenu_Previews: PreviewProvider {
    static var previews: some View {
        MainMenu()
            .environmentObject(ConfigHandler())
            .environmentObject(ClipBoardHandler(configHandler: ConfigHandler()))
    }
}
