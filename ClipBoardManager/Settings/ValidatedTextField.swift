import SwiftUI

// ValidatedTextField 结构体提供一个带有验证功能的文本输入框
// 使用泛型T允许它处理不同类型的值（如Int、Float等）
struct ValidatedTextField<T>: View {
    // 绑定到外部的值，当验证通过时会更新此值
    @Binding var content: T
    // 绑定到外部的错误状态标志
    @Binding var error: Bool
    // 内部状态用于存储文本框中的文本值
    @State var valueProxy = ""
    // 文本框的标题
    var title = ""
    // 验证函数，接收字符串并返回验证后的T类型值，如果验证失败则返回nil
    var validate: (String) -> T?

    // 更新值的方法，当验证通过时更新绑定的content
    func update(value: String) {
        if let newValue = validate(value) {
            self.content = newValue
        }
    }

    // 定义视图的主体内容
    var body: some View {
        return HStack {
            // 创建文本输入框
            TextField(
                title, text: $valueProxy,
                onEditingChanged: { focus in
                    // 当失去焦点时尝试更新值
                    if !focus {
                        update(value: valueProxy)
                    }
                }
            )
            // 当文本值变化时进行验证
            .onChange(of: valueProxy) { value in
                error = validate(value) == nil
            }
            // 当视图出现时，将content的值转换为字符串显示在文本框中
            .onAppear {
                valueProxy = "\(content)"
            }
            // 当视图消失时尝试更新值
            .onDisappear {
                update(value: valueProxy)
            }
            // 如果验证失败，显示红色边框
            .border(error ? Color.red : Color(red: 0, green: 0, blue: 0, opacity: 0))
        }
    }
}
