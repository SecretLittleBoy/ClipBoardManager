import SwiftUI

// TabView 结构体用于在设置窗口中显示不同的选项卡内容
struct TabView: View {
    // 通过环境对象获取配置处理器实例
    @EnvironmentObject private var configHandler: ConfigHandler
    // 绑定到外部的当前选中选项卡索引
    @Binding var currentTab: Int

    // 定义视图的主体内容
    var body: some View {
        // 创建一个区域来显示选项卡内容
        Section {
            // 根据当前选项卡索引显示不同的内容
            if currentTab == 0 {
                // 显示关于页面
                About()
            } else if currentTab == 1 {
                // 显示设置页面，并传递配置处理器
                Settings()
                    .environmentObject(configHandler)
            }
        }
        // 设置固定的框架大小
        .frame(width: 450, height: 150)
    }
}

// 预览提供者，用于在设计时预览 TabView 视图
struct TabView_Previews: PreviewProvider {
    static var previews: some View {
        // 创建 TabView 预览，默认选中第一个选项卡
        TabView(currentTab: .constant(0))
    }
}
