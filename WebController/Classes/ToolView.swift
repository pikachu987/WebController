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

/*
 A delegate that passes the state changes of the ToolView to the WebController.
 */
protocol ToolViewDelegate: class {
    
    /**
     Check if WebView can 'GoBack'.
     */
    var toolViewWebCanGoBack: Bool { get }
    
    /**
     Check if WebView can 'GoForward'.
     */
    var toolViewWebCanGoForward: Bool { get }
    
    /**
     Passes an event when 'Back UIBarButtonItem' is touched.
     */
    func toolViewWebGoBack()
    
    /**
     Passes an event when 'Forward UIBarButtonItem' is touched.
     */
    func toolViewWebGoForward()
    
    /**
     Passes an event when 'Reload UIBarButtonItem' is touched.
     */
    func toolViewWebReload()
    
    /**
     Passes an event when 'Stop UIBarButtonItem' is touched.
     */
    func toolViewWebStopLoading()
    
    /**
     Pass in the value of the state of InteractivePopGestureRecognizerd in UINavigation.
     - Parameters:
     - isEnabled: If true, BackSwipe of UINavigation is enabled.
     */
    func toolViewInteractivePopGestureRecognizerEnabled(_ isEnabled: Bool)
}

public class ToolView: UIView {
    
    // MARK: delegate
    
    weak var delegate: ToolViewDelegate?
    
    
    // MARK: Public Properties
    
    /**
     UIToolbar
     */
    public let toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        return toolbar
    }()
    
    /**
     Paints the colors of the UIToolbar's items.
     */
    public var itemTintColor: UIColor? {
        didSet {
            self.changeItemTintColor()
        }
    }
    
    /**
     Paints the background color of the UIToolbar.
     */
    public var barTintColor: UIColor? {
        didSet {
            self.changeBarTintColor()
        }
    }
    
    /**
     Hide the ToolBar's Refresh UIBarButtonItem, Stop UIBarButtonItem.
     Default is false.
     */
    public var isHiddenRefresh: Bool = false {
        didSet {
            self.setHiddenRefresh()
        }
    }
    
    /**
     Hides the ToolBar at the bottom of the WebController.
     Default is false.
     */
    public var isHiddenToolBar: Bool = false {
        didSet {
            self.makeToolBar()
        }
    }
    
    
    // MARK: Private Properties
    
    private var toolViewHeightConstraint: NSLayoutConstraint?
    
    /**
     backBarButtonItem Private Properties
     Included in items in UIToolBar.
     */
    private var backBarButtonItem: UIBarButtonItem?
    
    /**
     forwardBarButtonItem Private Properties
     Included in items in UIToolBar.
     */
    private var forwardBarButtonItem: UIBarButtonItem?
    
    /**
     reloadBarButtonItem Private Properties
     Included in items in UIToolBar.
     */
    private lazy var reloadBarButtonItem: UIBarButtonItem? = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.reload(_:)))
    
    /**
     stopBarButtonItem Private Properties
     Included in items in UIToolBar.
     */
    private lazy var stopBarButtonItem: UIBarButtonItem? = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.stop(_:)))
    
    
    // MARK: Life Cycle
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    // MARK: Public Method
    
    /**
     Back to UIToolbar Change UIBarButtonitem to title.
     - Parameters:
     - title: Title of UIBarButtonitem
     */
    public func setBackBarButtonItem(_ title: String?) {
        self.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(self.goBack(_:)))
        self.backBarButtonItem?.tintColor = self.itemTintColor
    }
    
    /**
     Back to UIToolbar Change UIBarButtonitem to image.
     - Parameters:
     - image: Image of UIBarButtonitem
     */
    public func setBackBarButtonItem(_ image: UIImage?) {
        self.backBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(self.goBack(_:)))
        self.backBarButtonItem?.tintColor = self.itemTintColor
    }
    
    /**
     Forward to UIToolbar Change UIBarButtonitem to title.
     - Parameters:
     - title: Title of UIBarButtonitem
     */
    public func setForwardBarButtonItem(_ title: String?) {
        self.forwardBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(self.goForward(_:)))
        self.forwardBarButtonItem?.tintColor = self.itemTintColor
    }
    
    /**
     Forward to UIToolbar Change UIBarButtonitem to image.
     - Parameters:
     - image: Image of UIBarButtonitem
     */
    public func setForwardBarButtonItem(_ image: UIImage?) {
        self.forwardBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(self.goForward(_:)))
        self.forwardBarButtonItem?.tintColor = self.itemTintColor
    }
    
    
    // MARK: Internal Method
    
    /**
     Runs when the site is loaded.
     stopBarButtonItem appears.
     */
    func loadDidStart() {
        var items = self.historyBarButtonItem()
        if let stopBarButtonItem = self.stopBarButtonItem {
            items.append(contentsOf: [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                stopBarButtonItem
                ])
        }
        self.toolbar.setItems(items, animated: false)
    }
    
    /**
     Run when the site is finished.
     refreshBarButtonItem appears.
     */
    func loadDidFinish() {
        var items = self.historyBarButtonItem()
        if let reloadBarButtonItem = self.reloadBarButtonItem {
            items.append(contentsOf: [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                reloadBarButtonItem
                ])
        }
        self.toolbar.setItems(items, animated: false)
    }
    
    func initVars() {
        let toolViewHeightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 0)
        toolViewHeightConstraint.priority = UILayoutPriority(500)
        self.addConstraint(toolViewHeightConstraint)
        self.makeToolBar()
        
        self.clipsToBounds = true
        self.toolbar.setItems(self.historyBarButtonItem(), animated: false)
        self.changeItemTintColor()
        self.changeBarTintColor()
        self.setHiddenRefresh()
    }
    
    
    // MARK: Private Method
    
    private func makeToolBar() {
        if self.isHiddenToolBar {
            self.removeConstraints(self.constraints.filter({ $0.firstAttribute != .height }))
            self.toolbar.removeFromSuperview()
        } else {
            if self.subviews.filter({ $0 == self.toolbar }).isEmpty {
                self.addSubview(self.toolbar)
                self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[toolbar]-0-|", options: [], metrics: nil, views: ["toolbar": toolbar]))
                var bottomConstant: CGFloat = 0
                if #available(iOS 11.0, *) {
                    bottomConstant = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
                }
                let topConstraint = NSLayoutConstraint(
                    item: self,
                    attribute: .top,
                    relatedBy: .equal,
                    toItem: toolbar,
                    attribute: .top,
                    multiplier: 1,
                    constant: 0)
                let bottomConstraint = NSLayoutConstraint(
                    item: self,
                    attribute: .bottom,
                    relatedBy: .equal,
                    toItem: toolbar,
                    attribute: .bottom,
                    multiplier: 1,
                    constant: bottomConstant)
                self.addConstraints([topConstraint, bottomConstraint])
            }
        }
    }
    
    private func historyBarButtonItem() -> [UIBarButtonItem] {
        guard let canGoBack = self.delegate?.toolViewWebCanGoBack,
            let canGoForward = self.delegate?.toolViewWebCanGoForward
            else { return [UIBarButtonItem]() }
        
        self.backBarButtonItem?.isEnabled = canGoBack
        self.forwardBarButtonItem?.isEnabled = canGoForward
        self.delegate?.toolViewInteractivePopGestureRecognizerEnabled(!canGoBack)
        var items = [UIBarButtonItem]()
        if let barButtonItem = self.backBarButtonItem {
            items.append(barButtonItem)
        } else {
            let barButtonItem = UIBarButtonItem(title: "◀︎", style: .plain, target: self, action: #selector(self.goBack(_:)))
            barButtonItem.isEnabled = canGoBack
            items.append(barButtonItem)
            self.backBarButtonItem = barButtonItem
        }
        if let barButtonItem = self.forwardBarButtonItem {
            items.append(barButtonItem)
        } else {
            let barButtonItem = UIBarButtonItem(title: "▶︎", style: .plain, target: self, action: #selector(self.goForward(_:)))
            barButtonItem.isEnabled = canGoForward
            items.append(barButtonItem)
            self.forwardBarButtonItem = barButtonItem
        }
        return items
    }
    
    private func changeItemTintColor() {
        self.backBarButtonItem?.tintColor = self.itemTintColor
        self.forwardBarButtonItem?.tintColor = self.itemTintColor
        self.reloadBarButtonItem?.tintColor = self.itemTintColor
        self.stopBarButtonItem?.tintColor = self.itemTintColor
    }
    
    private func changeBarTintColor() {
        self.backgroundColor = self.barTintColor
        self.toolbar.barTintColor = self.barTintColor
    }
    
    private func setHiddenRefresh() {
        if self.isHiddenRefresh {
            self.reloadBarButtonItem = nil
            self.stopBarButtonItem = nil
        } else {
            self.reloadBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.reload(_:)))
            self.stopBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.stop(_:)))
            self.reloadBarButtonItem?.tintColor = self.itemTintColor
            self.stopBarButtonItem?.tintColor = self.itemTintColor
        }
    }
    
    @objc private func goBack(_ sender: UIBarButtonItem) {
        self.delegate?.toolViewWebGoBack()
    }
    
    @objc private func goForward(_ sender: UIBarButtonItem) {
        self.delegate?.toolViewWebGoForward()
    }
    
    @objc private func reload(_ sender: UIBarButtonItem) {
        self.delegate?.toolViewWebReload()
    }
    
    @objc private func stop(_ sender: UIBarButtonItem) {
        self.delegate?.toolViewWebStopLoading()
    }
}
