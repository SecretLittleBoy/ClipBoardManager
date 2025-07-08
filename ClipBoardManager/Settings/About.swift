import SwiftUI

// About 结构体定义了应用程序的关于界面，显示版本信息和作者信息
struct About: View {
    // 从应用程序包中获取版本号
    let version: String? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String

    // 定义视图的主体内容
    var body: some View {
        VStack(alignment: .leading) {
            // 显示应用程序标题
            Text("ClipBoardManager")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 10)
            // 添加一个小间隔
            Spacer()
                .frame(height: 10)
            // 显示版本信息，如果获取失败则显示默认版本"1.0"
            Text("Version: \(version ?? "1.0")")
                .font(.subheadline)
            // 显示作者信息
            Text("Author: Lennard Kittner, lyh")
                .font(.subheadline)
            // 添加一个链接按钮，点击后打开作者的GitHub页面
            Button(action: {
                let url = URL(string: "https://github.com/SecretLittleBoy/ClipBoardManager")!
                NSWorkspace.shared.open(url)
            }) {
                Text("My GitHub")
                    .font(.subheadline)
            }
            // 使用链接样式并添加上边距
            .buttonStyle(.link)
            .padding(.top, 5)
        }
        // 调整左边距，使内容居中
        .padding(.leading, -150.0)
    }
}

// 预览提供者，用于在设计时预览 About 视图
struct About_Previews: PreviewProvider {
    static var previews: some View {
        About()
            .frame(width: 450, height: 150)
    }
}
