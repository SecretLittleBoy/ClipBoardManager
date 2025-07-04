import Combine
import SwiftUI

// Settings 结构体定义了应用程序的设置界面
struct Settings: View {
    // 通过环境对象获取配置处理器实例
    @EnvironmentObject private var configHandler: ConfigHandler
    // 用于跟踪三个输入字段的错误状态
    @State private var error = [false, false, false]

    // 验证正整数的函数
    func validatePositiveInt(_ string: String) -> Int? {
        if let num = Int(string) {
            if num > 0 {
                return num
            }
        }
        return nil
    }

    // 验证正浮点数的函数
    func validatePositiveFloat(_ string: String) -> Float? {
        if let num = Float(string) {
            if num > 0 {
                return num
            }
        }
        return nil
    }

    // 定义视图的主体内容
    var body: some View {
        VStack(alignment: .leading) {
            // 如果任何字段有错误，显示错误提示
            if error.reduce(false, { $0 || $1 }) {
                Text("Please enter a positive \(error[1] ? "" : "whole ")number")
                    .foregroundColor(.red)
            }
            // 剪贴板历史记录数量设置
            HStack {
                Text("Number Clippings: ")
                ValidatedTextField(
                    content: $configHandler.conf.clippings, error: $error[0],
                    validate: validatePositiveInt(_:)
                )
                .frame(width: 100)
            }
            // 刷新间隔设置
            HStack {
                Text("Refresh intervall:")
                    .padding(.trailing, 14)
                ValidatedTextField(
                    content: $configHandler.conf.refreshIntervall, error: $error[1],
                    validate: validatePositiveFloat(_:)
                )
                .frame(width: 100)
                Text("seconds")
            }
            // 预览长度设置
            HStack {
                Text("Preview length:")
                    .padding(.trailing, 22.5)
                ValidatedTextField(
                    content: $configHandler.conf.previewLength, error: $error[2],
                    validate: validatePositiveInt(_:)
                )
                .frame(width: 100)
                Text("px")
            }
            // 登录时启动设置
            HStack {
                Text("Start at login:")
                    .padding(.trailing, 35)
                Toggle(isOn: $configHandler.conf.atLogin) {

                }
                .toggleStyle(CheckboxToggleStyle())
                // 当登录设置改变时，应用更改
                .onChange(
                    of: configHandler.conf.atLogin,
                    perform: { b in
                        configHandler.applyAtLognin()
                    })
            }
        }
        .padding(.leading, -95.0)
    }

}

// 预览提供者，用于在设计时预览 Settings 视图
struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
            .environmentObject(ConfigHandler())
            .frame(width: 450, height: 150)
    }
}
