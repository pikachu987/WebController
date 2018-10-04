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

/*
 Pass the changes in the WebController to the delegate.
 */
@objc public protocol WebControllerDelegate: class {
    
    /**
     Called when title changes.
     - Parameters:
        - webController: WebControllerDelegate The UIViewController invoking the delegate method.
        - didChangeTitle: The title to change.
     */
    @objc optional func webController(_ webController: WebController, didChangeTitle: String?)
    
    /**
     Called when url changes.
     - Parameters:
        - webController: WebControllerDelegate The UIViewController invoking the delegate method.
        - didChangeURL: The url to change.
     */
    @objc optional func webController(_ webController: WebController, didChangeURL: URL?)
    
    /**
     It is called when the load starts or ends.
     - Parameters:
        - webController: WebControllerDelegate The UIViewController invoking the delegate method.
        - didLoading: load starts or ends.
     */
    @objc optional func webController(_ webController: WebController, didLoading: Bool)
    
    /**
     Called when title changes.
     - Parameters:
        - webController: WebControllerDelegate The UIViewController invoking the delegate method.
        - title: will change based on the return value.
     - Returns: UINavigationTitle is changed. default is changed to title which is received as argument.
     */
    @objc optional func webController(_ webController: WebController, title: String?) -> String?
    
    /**
     It will be called when the site becomes an Alert.
     - Parameters:
     - webController: WebControllerDelegate The UIViewController invoking the delegate method.
     - alertController: This is an alert window that will appear on the screen.
     - didUrl: The website URL with the alert window.
     */
    @objc optional func webController(_ webController: WebController, alertController: UIAlertController, didUrl: URL?)
    
    /**
     If the website fails to load, the Alert is called.
     - Parameters:
     - webController: WebControllerDelegate The UIViewController invoking the delegate method.
     - alertController: This is an alert window that will appear on the screen.
     - didUrl: The website URL with the alert window.
     */
    @objc optional func webController(_ webController: WebController, failAlertController: UIAlertController, didUrl: URL?)
    
    /**
     If the scheme is not http or https, think of it as a deep link or universal link
     - Parameters:
     - webController: WebControllerDelegate The UIViewController invoking the delegate method.
     - openUrl: Url to use 'UIApplication.shared.openURL'.
     - Returns: Return true to use 'UIApplication.shared.openURL'. default is true.
     */
    @objc optional func webController(_ webController: WebController, openUrl: URL?) -> Bool
    
    /**
     Decides whether to allow or cancel a navigation.
     - Parameters:
     - webController: WebControllerDelegate The UIViewController invoking the delegate method.
     - navigationAction: Descriptive information about the action triggering the navigation request.
     - decisionHandler: The decision handler to call to allow or cancel the navigation. The argument is one of the constants of the enumerated type WKNavigationActionPolicy.
     */
    @objc optional func webController(_ webController: WebController, navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void)
    
    /**
     Decides whether to allow or cancel a navigation after its response is known.
     - Parameters:
     - webController: WebControllerDelegate The UIViewController invoking the delegate method.
     - navigationResponse: Descriptive information about the navigation response.
     - decisionHandler: decisionHandler The decision handler to call to allow or cancel the navigation. The argument is one of the constants of the enumerated type WKNavigationResponsePolicy.
     */
    @objc optional func webController(_ webController: WebController, navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void)
    
    /**
     Invoked when the web view needs to respond to an authentication challenge.
     - Parameters:
     - webController: WebControllerDelegate The UIViewController invoking the delegate method.
     - challenge: The authentication challenge.
     - completionHandler: The completion handler you must invoke to respond to the challenge. The disposition argument is one of the constants of the enumerated type NSURLSessionAuthChallengeDisposition. When disposition is NSURLSessionAuthChallengeUseCredential, the credential argument is the credential to use, or nil to indicate continuing without a credential.
     */
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
    
    /**
     WKWebView
     */
    public lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        return webView
    }()
    
    /**
     The UIProgressView that appears above the WebView when the site loads
     */
    public lazy var progressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progress = 0
        return progressView
    }()
    
    /**
     The UIActivityIndicatorView that appears in the center of the webview when the site loads
     */
    public lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorView.Style.whiteLarge)
        indicatorView.color = UIColor.darkGray
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.isHidden = false
        indicatorView.startAnimating()
        return indicatorView
    }()
    
    /**
     A UIView that wraps around the bottom UIToolbar.
     */
    public lazy var toolView: ToolView = {
        let view = ToolView()
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /**
     Paints the title color of the UINavigationBar.
     */
    public var titleTintColor: UIColor? {
        didSet {
            self.titleButton.setTitleColor(self.titleTintColor, for: .normal)
            self.navigationController?.navigationBar.tintColor = self.titleTintColor
        }
    }
    
    /**
     Paints the background color of the UINavigationBar.
     */
    public var barTintColor: UIColor? {
        didSet {
            self.navigationController?.navigationBar.barTintColor = self.barTintColor
            self.navigationController?.navigationBar.backgroundColor = self.barTintColor
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
        
        self.navigationItem.titleView = self.titleButton
        self.navigationController?.navigationBar.barTintColor = self.barTintColor
        self.navigationController?.navigationBar.backgroundColor = self.barTintColor
        self.navigationController?.navigationBar.tintColor = self.titleTintColor
        self.titleButton.setTitleColor(self.titleTintColor, for: .normal)
        
        if let host = self.webView.url?.host {
            self.titleButton.setTitle("\(host) ▾", for: .normal)
            self.titleButton.sizeToFit()
        }
        
        // Set up webView
        self.view.addSubview(self.webView)
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[webView]-0-|", options: [], metrics: nil, views: ["webView": self.webView]))
        
        // Set up toolView
        self.view.addSubview(self.toolView)
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[toolView]-0-|", options: [], metrics: nil, views: ["toolView": self.toolView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[toolView]-0-|", options: [], metrics: nil, views: ["toolView": self.toolView]))
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[topGuide]-0-[webView]-0-[toolView]|", options: [], metrics: nil, views: ["webView": self.webView, "toolView": self.toolView, "topGuide": self.topLayoutGuide]))
        
        // Set up indicatorView
        self.view.addSubview(self.indicatorView)
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[webView]-(<=1)-[indicatorView]", options:.alignAllCenterY, metrics: nil, views: ["webView": self.webView, "indicatorView": self.indicatorView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[webView]-(<=1)-[indicatorView]", options:.alignAllCenterX, metrics: nil, views: ["webView": self.webView, "indicatorView": self.indicatorView]))
        
        // Set up progressView
        self.view.addSubview(self.progressView)
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[progressView]-0-|", options: [], metrics: nil, views: ["progressView": self.progressView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[topGuide]-0-[progressView(2)]", options: [], metrics: nil, views: ["progressView": self.progressView, "topGuide": self.topLayoutGuide]))
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
    
    
    // MARK: KVO
    
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
    
    /**
     Navigates to a requested URL.
     - Parameters:
        - urlPath: Url to Load WebView
        - cachePolicy: cachePolicy The cache policy for the request. Defaults to `.useProtocolCachePolicy`
        - timeoutInterval: timeoutInterval The timeout interval for the request. Defaults to 0.0
     */
    public func load(_ urlPath: String?, cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 0) {
        guard let urlPath = urlPath, let url = URL(string: urlPath) else { return }
        self.load(url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
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
        self.webView.load(URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval))
    }
    
    /**
     Evaluates the given JavaScript string.
     - Parameters:
        - javaScriptString: The JavaScript string to evaluate.
        - completionHandler: A block to invoke when script evaluation completes or fails.
     */
    public func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        self.webView.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
    
    
    // MARK: Private Method
    
    /**
     When you touch TitleView, a shared event that runs
     - Parameters:
        - sender: UIButton
     */
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
    private func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.toolView.loadDidStart()
    }
    private func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.toolView.loadDidFinish()
    }
    
    private func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.toolView.loadDidFinish()
        if error._code == NSURLErrorCancelled { return }
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        guard self.delegate?.webController?(self, alertController: alertController, didUrl: webView.url) != nil else {
            self.present(alertController, animated: true, completion: nil)
            return
        }
    }
    
    private func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
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
    
    private func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard self.delegate?.webController?(self, navigationResponse: navigationResponse, decisionHandler: decisionHandler) != nil else {
            decisionHandler(.allow)
            return
        }
    }
    
    private func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard self.delegate?.webController?(self, challenge: challenge, completionHandler: completionHandler) != nil else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
    }
}

// MARK: WKUIDelegate
extension WebController: WKUIDelegate {
    
    private func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
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
    
    private func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
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
    
    private func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
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
