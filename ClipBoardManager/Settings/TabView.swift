import SwiftUI

// TabView结构体定义了设置窗口中的选项卡视图
struct TabView: View {
    // 从环境中获取配置处理器
    @EnvironmentObject private var configHandler: ConfigHandler
    // 当前选中的选项卡索引（由父视图控制）
    @Binding var currentTab: Int

    // 视图内容
    var body: some View {
        Section {
            // 根据当前选中的选项卡索引显示不同的视图
            if currentTab == 0 {
                // 显示关于页面
                About()
            } else if currentTab == 1 {
                // 显示设置页面
                Settings()
                    .environmentObject(configHandler)
            }
        }
        .frame(width: 450, height: 150)
    }
}

// 预览提供者，用于在Xcode中预览TabView
struct TabView_Previews: PreviewProvider {
    static var previews: some View {
        TabView(currentTab: .constant(0))
    }
}
