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
public protocol WebControllerDelegate: NSObject {

    /**
     Called when title changes.
     - Parameters:
        - webController: WebControllerDelegate The UIViewController invoking the delegate method.
        - didChangeTitle: The title to change.
     */
    func webController(_ webController: WebController, didChangeTitle: String?)
    
    /**
     Called when url changes.
     - Parameters:
        - webController: WebControllerDelegate The UIViewController invoking the delegate method.
        - didChangeURL: The url to change.
     */
    func webController(_ webController: WebController, didChangeURL: URL?)
    
    /**
     It is called when the load starts or ends.
     - Parameters:
        - webController: WebControllerDelegate The UIViewController invoking the delegate method.
        - didLoading: load starts or ends.
     */
    func webController(_ webController: WebController, didLoading: Bool)
    
    /**
     Called when title changes.
     - Parameters:
        - webController: WebControllerDelegate The UIViewController invoking the delegate method.
        - title: will change based on the return value.
     - Returns: UINavigationTitle is changed. default is changed to title which is received as argument.
     */
    func webController(_ webController: WebController, title: String?) -> String?
    
    /**
     Called Error.
     - Parameters:
        - webController: WebControllerDelegate The UIViewController invoking the delegate method.
        - error: Error
     */
    func webController(_ webController: WebController, error: Error)

    /**
     It will be called when the site becomes an Alert.
     - Parameters:
     - webController: WebControllerDelegate The UIViewController invoking the delegate method.
     - alertController: This is an alert window that will appear on the screen.
     - didUrl: The website URL with the alert window.
     */
    func webController(_ webController: WebController, alertController: UIAlertController, didUrl: URL?)
    
    /**
     If the website fails to load, the Alert is called.
     - Parameters:
     - webController: WebControllerDelegate The UIViewController invoking the delegate method.
     - alertController: This is an alert window that will appear on the screen.
     - didUrl: The website URL with the alert window.
     */
    func webController(_ webController: WebController, failAlertController: UIAlertController, didUrl: URL?)
    
    /**
     If the scheme is not http or https, think of it as a deep link or universal link
     - Parameters:
     - webController: WebControllerDelegate The UIViewController invoking the delegate method.
     - openUrl: Url to use 'UIApplication.shared.openURL'.
     - Returns: Return true to use 'UIApplication.shared.openURL'. default is true.
     */
    func webController(_ webController: WebController, openUrl: URL?) -> Bool
    
    /**
     Decides whether to allow or cancel a navigation.
     - Parameters:
     - webController: WebControllerDelegate The UIViewController invoking the delegate method.
     - navigationAction: Descriptive information about the action triggering the navigation request.
     - decisionHandler: The decision handler to call to allow or cancel the navigation. The argument is one of the constants of the enumerated type WKNavigationActionPolicy.
     */
    func webController(_ webController: WebController, navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void)
    
    /**
     Decides whether to allow or cancel a navigation after its response is known.
     - Parameters:
     - webController: WebControllerDelegate The UIViewController invoking the delegate method.
     - navigationResponse: Descriptive information about the navigation response.
     - decisionHandler: decisionHandler The decision handler to call to allow or cancel the navigation. The argument is one of the constants of the enumerated type WKNavigationResponsePolicy.
     */
    func webController(_ webController: WebController, navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void)
    
    /**
     Invoked when the web view needs to respond to an authentication challenge.
     - Parameters:
     - webController: WebControllerDelegate The UIViewController invoking the delegate method.
     - challenge: The authentication challenge.
     - completionHandler: The completion handler you must invoke to respond to the challenge. The disposition argument is one of the constants of the enumerated type NSURLSessionAuthChallengeDisposition. When disposition is NSURLSessionAuthChallengeUseCredential, the credential argument is the credential to use, or nil to indicate continuing without a credential.
     */
    func webController(_ webController: WebController, challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)

    /**
     Title tapped
     - Parameters:
        - webController: WebControllerDelegate The UIViewController invoking the delegate method.
     */
    func webControllerTitleTap(_ webController: WebController)
}

public extension WebControllerDelegate {
    public func webController(_ webController: WebController, didChangeTitle: String?) {
        internalWebController(webController, didChangeTitle: didChangeTitle)
    }

    public func webController(_ webController: WebController, didChangeURL: URL?) {
        internalWebController(webController, didChangeURL: didChangeURL)
    }

    public func webController(_ webController: WebController, didLoading: Bool) {
        internalWebController(webController, didLoading: didLoading)
    }

    public func webController(_ webController: WebController, title: String?) -> String? {
        internalWebController(webController, title: title)
    }

    public func webController(_ webController: WebController, error: Error) {
        internalWebController(webController, error: error)
    }

    public func webController(_ webController: WebController, alertController: UIAlertController, didUrl: URL?) {
        internalWebController(webController, alertController: alertController, didUrl: didUrl)
    }

    public func webController(_ webController: WebController, failAlertController: UIAlertController, didUrl: URL?) {
        internalWebController(webController, failAlertController: failAlertController, didUrl: didUrl)
    }

    public func webController(_ webController: WebController, openUrl: URL?) -> Bool {
        internalWebController(webController, openUrl: openUrl)
    }

    public func webController(_ webController: WebController, navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        internalWebController(webController, navigationAction: navigationAction, decisionHandler: decisionHandler)
    }

    public func webController(_ webController: WebController, navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        internalWebController(webController, navigationResponse: navigationResponse, decisionHandler: decisionHandler)
    }

    public func webController(_ webController: WebController, challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        internalWebController(webController, challenge: challenge, completionHandler: completionHandler)
    }

    public func webControllerTitleTap(_ webController: WebController) {
        internalWebControllerTitleTap(webController)
    }
}

extension WebControllerDelegate {
    private var openLoadURL: URL? {
        get { objc_getAssociatedObject(self, &openLoadURLKey) as? URL }
        set { objc_setAssociatedObject(self, &openLoadURLKey, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }

    func internalWebController(_ webController: WebController, didChangeTitle: String?) {}
    func internalWebController(_ webController: WebController, didChangeURL: URL?) {}
    func internalWebController(_ webController: WebController, didLoading: Bool) {}

    func internalWebController(_ webController: WebController, title: String?) -> String? {
        title.map { "\($0) ▾" }
    }

    func internalWebController(_ webController: WebController, error: Error) {}

    func internalWebController(_ webController: WebController, alertController: UIAlertController, didUrl: URL?) {
        webController.present(alertController, animated: true, completion: nil)
    }

    func internalWebController(_ webController: WebController, failAlertController: UIAlertController, didUrl: URL?) {}
    func internalWebController(_ webController: WebController, openUrl: URL?) -> Bool { true }

    func internalWebController(_ webController: WebController, navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
        if let scheme = url.scheme, !( scheme == "http" || scheme == "https") {
            openLoadURL = nil
            if self.webController(webController, openUrl: url) {
                UIApplication.shared.openURL(url)
                return
            }
        } else if url.absoluteString.contains("app.link") && openLoadURL == nil{
            openLoadURL = url
            webController.load(url)
        } else {
            openLoadURL = nil
            if let currentURL = webController.webView.url, url == currentURL {
                return
            }
        }
        return
    }

    func internalWebController(_ webController: WebController, navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }

    func internalWebController(_ webController: WebController, challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }

    func internalWebControllerTitleTap(_ webController: WebController) {
        guard let urlPath = webController.webView.url?.absoluteString else { return }
        let activityViewController = UIActivityViewController(activityItems: [urlPath], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = webController.view
        webController.present(activityViewController, animated: true, completion: nil)
    }
}

private var openLoadURLKey: UInt8 = 0
