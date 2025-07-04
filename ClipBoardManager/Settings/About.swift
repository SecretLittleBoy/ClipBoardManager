import SwiftUI

// About结构体定义了关于页面的UI
struct About: View {
    // 从应用程序包信息中获取版本号
    let version: String? = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String

    // 视图内容
    var body: some View {
        VStack(alignment: .leading) {
            // 应用程序名称
            Text("ClipBoardManager")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 10)
            Spacer()
                .frame(height: 10)
            // 版本信息
            Text("Version: \(version ?? "1.0")")
                .font(.subheadline)
            // 作者信息
            Text("Author: Lennard Kittner")
                .font(.subheadline)
            // GitHub链接按钮
            Button(action: {
                let url = URL(string: "https://github.com/LennardKittner")!
                NSWorkspace.shared.open(url)
            }) {
                Text("My GitHub")
                    .font(.subheadline)
            }
            .buttonStyle(.link)
            .padding(.top, 5)
        }
        .padding(.leading, -150.0)
    }
}

// 预览提供者，用于在Xcode中预览About视图
struct About_Previews: PreviewProvider {
    static var previews: some View {
        About()
            .frame(width: 450, height: 150)
    }
}
