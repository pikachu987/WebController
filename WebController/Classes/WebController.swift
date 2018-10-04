import UIKit
import WebKit

@objc public protocol WebControllerDelegate: class {
    @objc optional func webController(_ webController: WebController, didChangeTitle: String?)
    @objc optional func webController(_ webController: WebController, didChangeURL: URL?)
    @objc optional func webController(_ webController: WebController, didLoading: Bool)
    @objc optional func webController(_ webController: WebController, title: String?) -> String?
    @objc optional func webController(_ webController: WebController, alertController: UIAlertController, didUrl url: URL?)
    @objc optional func webController(_ webController: WebController, failAlertController: UIAlertController, didUrl url: URL?)
    @objc optional func webController(_ webController: WebController, openUrl url: URL?) -> Bool
    @objc optional func webController(_ webController: WebController, navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void)
    @objc optional func webController(_ webController: WebController, navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void)
    @objc optional func webController(_ webController: WebController, challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

open class WebController: UIViewController {
    
    // MARK: deinit
    
    deinit {
        self.webView.stopLoading()
        self.webView.uiDelegate = nil
        self.webView.navigationDelegate = nil
    }
    
    // MARK: delegate
    
    public weak var delegate: WebControllerDelegate?
    
    
    // MARK: Public Properties
    
    public lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        return webView
    }()
    
    public lazy var progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progress = 0
        return progressView
    }()
    
    public lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView()
        indicatorView.style = UIActivityIndicatorView.Style.whiteLarge
        indicatorView.color = UIColor.darkGray
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.isHidden = false
        indicatorView.startAnimating()
        return indicatorView
    }()
    
    public lazy var toolView: ToolView = {
        let view = ToolView()
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public var titleTintColor: UIColor? {
        didSet {
            self.titleButton.setTitleColor(self.titleTintColor, for: .normal)
        }
    }
    
    public var barTintColor: UIColor? {
        didSet {
            self.navigationController?.navigationBar.barTintColor = self.barTintColor
        }
    }
    
    
    // MARK: Private Properties
    
    private var openLoadURL: URL?
    
    private lazy var titleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        button.sizeToFit()
        button.addTarget(self, action: #selector(self.shareAction(_:)), for: .touchUpInside)
        return button
    }()
    
    
    // MARK: Life Cycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = self.barTintColor
        
        if let host = self.webView.url?.host {
            self.titleButton.setTitle("\(host) ▾", for: .normal)
            self.titleButton.sizeToFit()
        }
        
        self.view.addSubview(self.webView)
        self.view.addSubview(self.toolView)
        self.view.addSubview(self.indicatorView)
        self.view.addSubview(self.progressView)
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[webView]-0-|", options: [], metrics: nil, views: ["webView": self.webView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[topGuide]-0-[webView]-0-[toolView]|", options: [], metrics: nil, views: ["webView": self.webView, "toolView": self.toolView, "topGuide": self.topLayoutGuide]))
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[toolView]-0-|", options: [], metrics: nil, views: ["toolView": self.toolView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[toolView]-0-|", options: [], metrics: nil, views: ["toolView": self.toolView]))
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[progressView]-0-|", options: [], metrics: nil, views: ["progressView": self.progressView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[topGuide]-0-[progressView(2)]", options: [], metrics: nil, views: ["progressView": self.progressView, "topGuide": self.topLayoutGuide]))
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[webView]-(<=1)-[indicatorView]", options:.alignAllCenterY, metrics: nil, views: ["webView": self.webView, "indicatorView": indicatorView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[webView]-(<=1)-[indicatorView]", options:.alignAllCenterX, metrics: nil, views: ["webView": self.webView, "indicatorView": indicatorView]))
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.webView.stopLoading()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        self.webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.webView.removeObserver(self, forKeyPath: "estimatedProgress")
        self.webView.removeObserver(self, forKeyPath: "URL")
        self.webView.removeObserver(self, forKeyPath: "title")
        self.webView.removeObserver(self, forKeyPath: "loading")
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else {return}
        switch keyPath {
        case "estimatedProgress":
            guard let newValue = change?[NSKeyValueChangeKey.newKey] as? NSNumber else { return }
            self.progressView.setProgress(Float(truncating: newValue), animated: false)
            if newValue == 1 {
                UIView.animate(withDuration: 0.5, animations: {
                    self.progressView.alpha = 0
                }) { (_) in
                    self.progressView.setProgress(0, animated: false)
                }
            } else {
                self.progressView.alpha = 1
            }
        case "URL":
            guard let host = self.webView.url?.host else { return }
            if let title = self.delegate?.webController?(self, title: "\(host) ▾") {
                self.titleButton.setTitle(title, for: .normal)
            } else {
                self.titleButton.setTitle("\(host) ▾", for: .normal)
            }
            self.titleButton.sizeToFit()
            self.delegate?.webController?(self, didChangeURL: self.webView.url)
        case "title":
            self.delegate?.webController?(self, didChangeTitle: self.webView.title)
        case "loading":
            guard let value = change?[NSKeyValueChangeKey.newKey] as? Bool else { return }
            self.delegate?.webController?(self, didLoading: !value)
            if value {
                self.indicatorView.isHidden = false
                self.indicatorView.startAnimating()
                self.toolView.loadDidStart()
            } else {
                self.indicatorView.isHidden = true
                self.indicatorView.stopAnimating()
                self.toolView.loadDidFinish()
            }
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: Public Method
    
    public func load(_ urlPath: String?, cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 0) {
        guard let urlPath = urlPath, let url = URL(string: urlPath) else { return }
        self.load(url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
    }
    
    public func load(_ url: URL?, cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 0) {
        guard let url = url else { return }
        self.webView.load(URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval))
    }
    
    public func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        self.webView.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
    
    
    
    // MARK: Private Method
    
    @objc private func shareAction(_ sender: UIButton) {
        guard let urlPath = self.webView.url?.absoluteString else { return }
        let activityViewController = UIActivityViewController(activityItems: [urlPath], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
}

// MARK: ToolViewDelegate
extension WebController: ToolViewDelegate{
    var toolViewWebCanGoBack: Bool {
        return self.webView.canGoBack
    }
    var toolViewWebCanGoForward: Bool {
        return self.webView.canGoForward
    }
    func toolViewWebStopLoading() {
        self.webView.stopLoading()
    }
    func toolViewWebReload() {
        self.webView.reload()
    }
    func toolViewWebGoForward() {
        self.webView.goForward()
    }
    func toolViewWebGoBack() {
        self.webView.goBack()
    }
    func toolViewInteractivePopGestureRecognizerEnabled(_ isEnabled: Bool) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = isEnabled
    }
}

// MARK: WKNavigationDelegate
extension WebController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.toolView.loadDidStart()
    }
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.toolView.loadDidFinish()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.toolView.loadDidFinish()
        if error._code == NSURLErrorCancelled { return }
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        guard self.delegate?.webController?(self, alertController: alertController, didUrl: webView.url) != nil else {
            self.present(alertController, animated: true, completion: nil)
            return
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard self.delegate?.webController?(self, navigationAction: navigationAction, decisionHandler: decisionHandler) != nil else {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
            if let scheme = url.scheme, !( scheme == "http" || scheme == "https") {
                self.openLoadURL = nil
                guard self.delegate?.webController?(self, openUrl: url) != nil else {
                    UIApplication.shared.openURL(url)
                    return
                }
            } else if url.absoluteString.contains("app.link") && self.openLoadURL == nil{
                self.openLoadURL = url
                self.load(url)
            } else {
                self.openLoadURL = nil
                if let currentURL = self.webView.url, url == currentURL {
                    return
                }
            }
            return
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard self.delegate?.webController?(self, navigationResponse: navigationResponse, decisionHandler: decisionHandler) != nil else {
            decisionHandler(.allow)
            return
        }
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard self.delegate?.webController?(self, challenge: challenge, completionHandler: completionHandler) != nil else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
    }
}

// MARK: WKUIDelegate
extension WebController: WKUIDelegate {
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Confirm", style: .cancel, handler: {(action: UIAlertAction) -> Void in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {(action: UIAlertAction) -> Void in
            completionHandler(false)
        }))
        guard self.delegate?.webController?(self, alertController: alertController, didUrl: webView.url) != nil else {
            self.present(alertController, animated: true, completion: nil)
            return
        }
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.text = defaultText
        }
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {(action: UIAlertAction) -> Void in
            completionHandler(alertController.textFields?.first?.text)
        }))
        guard self.delegate?.webController?(self, alertController: alertController, didUrl: webView.url) != nil else {
            self.present(alertController, animated: true, completion: nil)
            return
        }
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController: UIAlertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {(action: UIAlertAction) -> Void in
            completionHandler()
        }))
        guard self.delegate?.webController?(self, alertController: alertController, didUrl: webView.url) != nil else {
            self.present(alertController, animated: true, completion: nil)
            return
        }
    }
}
