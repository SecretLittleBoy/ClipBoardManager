import SwiftUI

// Toolbar结构体定义了设置窗口顶部的工具栏（选项卡切换器）
struct Toolbar: View {
    // 选项卡标题数组
    let tabs: [String]
    // 当前选中的选项卡索引（由父视图控制）
    @Binding var currentTab: Int

    // 视图内容
    var body: some View {
        // 创建一个选择器，用于在不同选项卡之间切换
        Picker("", selection: $currentTab) {
            // 为每个选项卡标题创建一个文本视图
            ForEach(tabs.indices) { i in
                Text(tabs[i]).tag(i)
            }
        }
        // 使用分段控件样式
        .pickerStyle(SegmentedPickerStyle())
        // 设置选择器宽度
        .frame(width: 100)
    }
}

// 预览提供者，用于在Xcode中预览Toolbar
struct Toolbar_Previews: PreviewProvider {
    static var previews: some View {
        Toolbar(tabs: ["About", "Settings"], currentTab: .constant(0))
    }
}
