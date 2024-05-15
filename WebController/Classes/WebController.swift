//Copyright (c) 2018 pikachu987 <pikachu77769@gmail.com>
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in
//all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//THE SOFTWARE.

import UIKit
import WebKit

open class WebController: UIViewController {
    
    // MARK: deinit
    
    deinit {
        clear()
    }
    
    // MARK: delegate
    
    public weak var delegate: WebControllerDelegate?
    
    
    // MARK: Public Properties

    /**
     WebOptions
     */
    public var configuration = WebConfiguration()

    /**
     WKWebView
     */
    public lazy var webView: WKWebView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.allowsBackForwardNavigationGestures = true
        return $0
    }(WKWebView(frame: .zero, configuration: WKWebViewConfiguration()))

    /**
     The UIProgressView that appears above the WebView when the site loads
     */
    public lazy var progressView: UIProgressView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.progress = 0
        return $0
    }(UIProgressView())

    /**
     The UIActivityIndicatorView that appears in the center of the webview when the site loads
     */
    public lazy var indicatorView: UIActivityIndicatorView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.color = .darkGray
        $0.isHidden = false
        $0.startAnimating()
        return $0
    }(UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge))

    /**
     A UIView that wraps around the bottom UIToolbar.
     */
    public lazy var toolView: ToolView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(ToolView(frame: .zero))

    /**
     Paints the title color of the UINavigationBar.
     */
    public var titleTintColor: UIColor? {
        didSet {
            titleButton.setTitleColor(titleTintColor, for: .normal)
            navigationController?.navigationBar.tintColor = titleTintColor
        }
    }
    
    /**
     Paints the background color of the UINavigationBar.
     */
    public var barTintColor: UIColor? {
        didSet {
            navigationController?.navigationBar.barTintColor = barTintColor
            navigationController?.navigationBar.backgroundColor = barTintColor
        }
    }
    
    // MARK: Private Properties
    
    public lazy var titleButton: UIButton = {
        $0.setTitle("", for: .normal)
        $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        $0.sizeToFit()
        return $0
    }(UIButton(type: .system))

    private var estimatedProgressObserver: NSKeyValueObservation?
    private var urlObserver: NSKeyValueObservation?
    private var titleObserver: NSKeyValueObservation?
    private var loadingObserver: NSKeyValueObservation?

    private var isEnabledPopGesture: Bool = true

    // MARK: Life Cycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        isEnabledPopGesture = navigationController?.interactivePopGestureRecognizer?.isEnabled ?? true
        print("isEnabledPopGesture: \(isEnabledPopGesture)")
        setupViews()
        setupObserver()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = !webView.canGoBack
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        navigationController?.interactivePopGestureRecognizer?.isEnabled = isEnabledPopGesture
    }
}

extension WebController {
    // MARK: Public Method
    
    public func clear() {
        removeObserver()
        webView.stopLoading()
        webView.uiDelegate = nil
        webView.navigationDelegate = nil
    }

    /**
     Navigates to a requested URL.
     - Parameters:
     - urlPath: Url to Load WebView
     - cachePolicy: cachePolicy The cache policy for the request. Defaults to `.useProtocolCachePolicy`
     - timeoutInterval: timeoutInterval The timeout interval for the request. Defaults to 0.0
     */
    public func load(_ urlPath: String?, cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 0) {
        guard let urlPath = urlPath, let url = URL(string: urlPath) else { return }
        load(url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
    }

    /**
     Navigates to a requested URL.
     - Parameters:
     - url: Url to Load WebView
     - cachePolicy: cachePolicy The cache policy for the request. Defaults to `.useProtocolCachePolicy`
     - timeoutInterval: timeoutInterval The timeout interval for the request. Defaults to 0.0
     */
    public func load(_ url: URL?, cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 0) {
        guard let url = url else { return }
        webView.load(URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval))
    }

    /**
     Evaluates the given JavaScript string.
     - Parameters:
     - javaScriptString: The JavaScript string to evaluate.
     - completionHandler: A block to invoke when script evaluation completes or fails.
     */
    public func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        webView.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
}

extension WebController {
    private func setupViews() {
        delegate = self
        navigationItem.titleView = titleButton
        navigationController?.navigationBar.barTintColor = barTintColor
        navigationController?.navigationBar.backgroundColor = barTintColor
        navigationController?.navigationBar.tintColor = titleTintColor
        titleButton.setTitleColor(titleTintColor, for: .normal)

        webView.url.map {
            delegate?.webController(self, title: $0.host).map {
                titleButton.setTitle($0, for: .normal)
            }
            titleButton.sizeToFit()
        }

        view.addSubview(webView)
        view.addSubview(toolView)
        view.addSubview(indicatorView)
        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        NSLayoutConstraint.activate([
            toolView.topAnchor.constraint(equalTo: webView.bottomAnchor),
            toolView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            toolView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            toolView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            indicatorView.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: webView.centerYAnchor)
        ])

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: webView.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])

        titleButton.addTarget(self, action: #selector(titleTapped(_:)), for: .touchUpInside)

        toolView.delegate = self
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }
}

extension WebController {
    private func setupObserver() {
        estimatedProgressObserver = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] object, change in
            guard let self = self, let newValue = change.newValue else { return }
            self.progressView.setProgress(Float(newValue), animated: false)
            if newValue == 1 {
                UIView.animate(withDuration: 0.5, animations: { [weak self] in
                    self?.progressView.alpha = 0
                }, completion: { [weak self] _ in
                    self?.progressView.setProgress(0, animated: false)
                })
            } else {
                self.progressView.alpha = 1
            }
        }

        urlObserver = webView.observe(\.url, options: [.new]) { [weak self] object, change in
            guard let self = self, let host = self.webView.url?.host else { return }
            self.delegate?.webController(self, title: host).map {
                self.titleButton.setTitle($0, for: .normal)
            }
            self.titleButton.sizeToFit()
            self.delegate?.webController(self, didChangeURL: self.webView.url)
        }

        titleObserver = webView.observe(\.title, options: [.new]) { [weak self] object, change in
            guard let self = self else { return }
            self.delegate?.webController(self, didChangeTitle: self.webView.title)
        }

        loadingObserver = webView.observe(\.isLoading, options: [.new]) { [weak self] object, change in
            guard let self = self else { return }
            guard let newValue = change.newValue else { return }
            self.delegate?.webController(self, didLoading: !newValue)
            if newValue {
                self.indicatorView.isHidden = false
                self.indicatorView.startAnimating()
                self.toolView.loadDidStart()
            } else {
                self.indicatorView.isHidden = true
                self.indicatorView.stopAnimating()
                self.toolView.loadDidFinish()
            }
        }
    }

    private func removeObserver() {
        if #available(iOS 11.0, *) {
            estimatedProgressObserver.map { $0.invalidate() }
            urlObserver.map { $0.invalidate() }
            titleObserver.map { $0.invalidate() }
            loadingObserver.map { $0.invalidate() }

            estimatedProgressObserver = nil
            urlObserver = nil
            titleObserver = nil
            loadingObserver = nil
        } else {
            estimatedProgressObserver.map {
                $0.invalidate()
                webView.removeObserver($0, forKeyPath: "estimatedProgress")
            }
            urlObserver.map {
                $0.invalidate()
                webView.removeObserver($0, forKeyPath: "URL")
            }
            titleObserver.map {
                $0.invalidate()
                webView.removeObserver($0, forKeyPath: "title")
            }
            loadingObserver.map {
                $0.invalidate()
                webView.removeObserver($0, forKeyPath: "loading")
            }

            estimatedProgressObserver = nil
            urlObserver = nil
            titleObserver = nil
            loadingObserver = nil
        }
    }
}

extension WebController {
    @objc private func titleTapped(_ sender: UIButton) {
        delegate?.webControllerTitleTap(self)
    }
}

// MARK: ToolViewDelegate
extension WebController: ToolViewDelegate {
    var toolViewWebCanGoBack: Bool { webView.canGoBack }
    var toolViewWebCanGoForward: Bool { webView.canGoForward }

    func toolViewWebStopLoading() { webView.stopLoading() }
    func toolViewWebReload() { webView.reload() }
    func toolViewWebGoForward() { webView.goForward() }
    func toolViewWebGoBack() { webView.goBack() }

    func toolViewInteractivePopGestureRecognizerEnabled(_ isEnabled: Bool) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = isEnabled
    }
}

extension WebController: WebControllerDelegate {
    @objc open func webController(_ webController: WebController, didChangeTitle: String?) {
        internalWebController(webController, didChangeTitle: didChangeTitle)
    }

    @objc open func webController(_ webController: WebController, didChangeURL: URL?) {
        internalWebController(webController, didChangeURL: didChangeURL)
    }

    @objc open func webController(_ webController: WebController, didLoading: Bool) {
        internalWebController(webController, didLoading: didLoading)
    }

    @objc open func webController(_ webController: WebController, title: String?) -> String? {
        internalWebController(webController, title: title)
    }

    @objc open func webController(_ webController: WebController, error: Error) {
        internalWebController(webController, error: error)
    }

    @objc open func webController(_ webController: WebController, alertController: UIAlertController, didUrl: URL?) {
        internalWebController(webController, alertController: alertController, didUrl: didUrl)
    }

    @objc open func webController(_ webController: WebController, failAlertController: UIAlertController, didUrl: URL?) {
        internalWebController(webController, failAlertController: failAlertController, didUrl: didUrl)
    }

    @objc open func webController(_ webController: WebController, openUrl: URL?) -> Bool {
        internalWebController(webController, openUrl: openUrl)
    }

    @objc open func webController(_ webController: WebController, navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        internalWebController(webController, navigationAction: navigationAction, decisionHandler: decisionHandler)
    }

    @objc open func webController(_ webController: WebController, navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        internalWebController(webController, navigationResponse: navigationResponse, decisionHandler: decisionHandler)
    }

    @objc open func webController(_ webController: WebController, challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        internalWebController(webController, challenge: challenge, completionHandler: completionHandler)
    }

    @objc open func webControllerTitleTap(_ webController: WebController) {
        internalWebControllerTitleTap(webController)
    }
}

// MARK: WKNavigationDelegate
extension WebController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        toolView.loadDidStart()
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        toolView.loadDidFinish()
        delegate?.webController(self, error: error)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        toolView.loadDidFinish()
        if error._code == NSURLErrorCancelled { return }
        let alertController = UIAlertController(title: configuration.strings.error, message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: configuration.strings.confirm, style: .default, handler: nil))
        delegate?.webController(self, alertController: alertController, didUrl: webView.url)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        delegate?.webController(self, navigationAction: navigationAction, decisionHandler: decisionHandler)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        delegate?.webController(self, navigationResponse: navigationResponse, decisionHandler: decisionHandler)
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        delegate?.webController(self, challenge: challenge, completionHandler: completionHandler)
    }
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {}
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {}
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {}
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {}

    public func webView(_ webView: WKWebView, authenticationChallenge challenge: URLAuthenticationChallenge, shouldAllowDeprecatedTLS decisionHandler: @escaping (Bool) -> Void) {
        decisionHandler(true)
    }
    public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {}
    public func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {}
}

// MARK: WKUIDelegate
extension WebController: WKUIDelegate {
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController: UIAlertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: configuration.strings.confirm, style: .default, handler: { _ in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: configuration.strings.cancel, style: .cancel, handler: { _ in
            completionHandler(false)
        }))
        delegate?.webController(self, alertController: alertController, didUrl: webView.url)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController: UIAlertController = UIAlertController(title: prompt, message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = defaultText
        }
        alertController.addAction(UIAlertAction(title: configuration.strings.confirm, style: .cancel, handler: { _ in
            completionHandler(alertController.textFields?.first?.text)
        }))
        delegate?.webController(self, alertController: alertController, didUrl: webView.url)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController: UIAlertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: configuration.strings.confirm, style: .cancel, handler: { _ in
            completionHandler()
        }))
        delegate?.webController(self, alertController: alertController, didUrl: webView.url)
    }

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame?.isMainFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    public func webViewDidClose(_ webView: WKWebView) {}
    public func webView(_ webView: WKWebView, commitPreviewingViewController previewingViewController: UIViewController) {}
}
