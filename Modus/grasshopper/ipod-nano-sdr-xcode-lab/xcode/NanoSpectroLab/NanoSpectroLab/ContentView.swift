import SwiftUI
import WebKit

struct ContentView: View {
    @State private var serverURL = "http://localhost:8088"
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Nano Spectro Lab")
                    .font(.headline)
                Spacer()
                TextField("Server URL", text: $serverURL)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(10)
            WebView(urlString: serverURL)
        }
    }
}

struct WebView: UIViewRepresentable {
    let urlString: String
    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        let web = WKWebView(frame: .zero, configuration: cfg)
        web.isOpaque = false
        web.backgroundColor = .black
        return web
    }
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
    }
}
