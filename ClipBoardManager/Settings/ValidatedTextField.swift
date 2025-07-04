import SwiftUI

// ValidatedTextField结构体定义了一个带验证功能的文本输入框
// 泛型T允许输入框处理不同类型的值（如Int、Float等）
struct ValidatedTextField<T>: View {
    // 绑定到父视图中的实际值
    @Binding var content: T
    // 绑定到父视图中的错误状态
    @Binding var error: Bool
    // 本地状态，存储文本框中显示的字符串值
    @State var valueProxy = ""
    // 文本框的标题/占位符
    var title = ""
    // 验证函数，接收字符串输入并返回T类型的值或nil（验证失败时）
    var validate: (String) -> T?

    // 尝试用给定的字符串更新绑定的值
    func update(value: String) {
        if let newValue = validate(value) {
            self.content = newValue
        }
    }

    // 视图内容
    var body: some View {
        return HStack {
            TextField(
                title, text: $valueProxy,
                onEditingChanged: { focus in
                    // 当用户完成编辑（失去焦点）时更新值
                    if !focus {
                        update(value: valueProxy)
                    }
                }
            )
            // 当输入值变化时验证并更新错误状态
            .onChange(of: valueProxy) { value in
                error = validate(value) == nil
            }
            // 当视图首次出现时，用当前值初始化文本框
            .onAppear {
                valueProxy = "\(content)"
            }
            // 当视图消失时尝试更新值
            .onDisappear {
                update(value: valueProxy)
            }
            // 根据错误状态设置边框颜色
            .border(error ? Color.red : Color(red: 0, green: 0, blue: 0, opacity: 0))
        }
    }
}
