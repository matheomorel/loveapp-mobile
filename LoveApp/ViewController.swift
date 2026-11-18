import UIKit
import WebKit

final class ViewController: UIViewController {
    private let configName = "site-url.txt"
    private let urlPlaceholder = "REMPLACER_PAR_IP_DU_PC"
    private var webView: WKWebView!
    private var websiteURL: URL?
    private var errorAlertVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 1, green: 0.973, blue: 0.984, alpha: 1)
        configureWebView()

        do {
            let url = try readWebsiteURL()
            websiteURL = url
            webView.load(URLRequest(url: url))
        } catch {
            showSetupMessage(error.localizedDescription)
        }
    }

    private func configureWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func readWebsiteURL() throws -> URL {
        guard let configURL = Bundle.main.url(forResource: "site-url", withExtension: "txt") else {
            throw setupError(
                "Impossible de lire \(configName). Vérifiez que le fichier est inclus dans l’application."
            )
        }

        let content = try String(contentsOf: configURL, encoding: .utf8)
        let value = content
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty && !$0.hasPrefix("#") }

        guard let value,
              !value.contains(urlPlaceholder),
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host != nil
        else {
            throw setupError(
                "L’adresse du site est absente ou invalide. Remplacez la ligne dans \(configName) par l’adresse complète du site, par exemple https://192.168.1.25:5173."
            )
        }
        return url
    }

    private func setupError(_ message: String) -> NSError {
        NSError(domain: "LoveApp", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func showSetupMessage(_ message: String) {
        webView.removeFromSuperview()

        let label = UILabel()
        label.text = message
        label.textColor = UIColor(red: 87.0 / 255, green: 47.0 / 255, blue: 66.0 / 255, alpha: 1)
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func showWebsiteLoadError(_ message: String) {
        guard !errorAlertVisible, presentedViewController == nil else { return }
        errorAlertVisible = true

        let alert = UIAlertController(
            title: "Impossible d’afficher le site",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Réessayer", style: .default) { [weak self] _ in
            guard let self, let websiteURL = self.websiteURL else { return }
            self.errorAlertVisible = false
            self.webView.load(URLRequest(url: websiteURL))
        })
        alert.addAction(UIAlertAction(title: "Fermer", style: .cancel) { [weak self] _ in
            self?.errorAlertVisible = false
        })
        present(alert, animated: true)
    }

    private func isSecureRequest(from origin: WKSecurityOrigin) -> Bool {
        guard let currentURL = webView.url,
              currentURL.scheme?.lowercased() == "https",
              origin.protocol.lowercased() == "https",
              currentURL.host?.lowercased() == origin.host.lowercased()
        else {
            return false
        }

        let expectedPort = currentURL.port ?? 443
        return expectedPort == origin.port
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        let nsError = error as NSError
        guard nsError.code != NSURLErrorCancelled else { return }
        showWebsiteLoadError(
            "Connexion impossible (\(error.localizedDescription)). Vérifiez l’adresse, que le serveur LoveApp est démarré et que l’iPhone et le PC sont sur le même Wi-Fi. N’utilisez pas localhost sur l’iPhone."
        )
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        let nsError = error as NSError
        guard nsError.code != NSURLErrorCancelled else { return }
        showWebsiteLoadError("Connexion impossible (\(error.localizedDescription)).")
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if navigationResponse.isForMainFrame,
           let response = navigationResponse.response as? HTTPURLResponse,
           response.statusCode >= 400 {
            showWebsiteLoadError("Le site a répondu avec l’erreur HTTP \(response.statusCode). Vérifiez l’adresse du site.")
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

extension ViewController: WKUIDelegate {
    @available(iOS 15.0, *)
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(isSecureRequest(from: origin) ? .grant : .deny)
    }
}
