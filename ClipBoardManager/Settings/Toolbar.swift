import SwiftUI

// Toolbar 结构体用于创建设置窗口顶部的选项卡切换工具栏
struct Toolbar: View {
    // 选项卡标题数组
    let tabs: [String]
    // 绑定到外部的当前选中选项卡索引
    @Binding var currentTab: Int

    // 定义视图的主体内容
    var body: some View {
        // 创建一个选择器，用于在不同选项卡之间切换
        Picker("", selection: $currentTab) {
            // 遍历所有选项卡标题，创建对应的选项
            ForEach(tabs.indices) { i in
                Text(tabs[i]).tag(i)
            }
        }
        // 使用分段样式，适合作为选项卡切换器
        .pickerStyle(SegmentedPickerStyle())
        // 设置固定宽度
        .frame(width: 100)
    }
}

// 预览提供者，用于在设计时预览 Toolbar 视图
struct Toolbar_Previews: PreviewProvider {
    static var previews: some View {
        // 创建 Toolbar 预览，使用两个选项卡，默认选中第一个
        Toolbar(tabs: ["About", "Settings"], currentTab: .constant(0))
    }
}
