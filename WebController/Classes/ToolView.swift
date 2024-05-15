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
protocol ToolViewDelegate: AnyObject {

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
    public lazy var toolbar: UIToolbar = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIToolbar(frame: .init(origin: .zero, size: .init(width: 200, height: 60))))

    /**
     Paints the colors of the UIToolbar's items.
     */
    public var itemTintColor: UIColor? {
        didSet {
            changeItemTintColor()
        }
    }
    
    /**
     Paints the background color of the UIToolbar.
     */
    public var barTintColor: UIColor? {
        didSet {
            changeBarTintColor()
        }
    }
    
    /**
     Hide the ToolBar's Refresh UIBarButtonItem, Stop UIBarButtonItem.
     Default is false.
     */
    public var isHiddenRefresh: Bool = false {
        didSet {
            setHiddenRefresh()
        }
    }
    
    /**
     Hides the ToolBar at the bottom of the WebController.
     Default is false.
     */
    public var isHiddenToolBar: Bool = false {
        didSet {

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
    public override init(frame: CGRect) {
        super.init(frame: frame)

        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ToolView {
    /**
     Back to UIToolbar Change UIBarButtonitem to title.
     - Parameters:
     - title: Title of UIBarButtonitem
     */
    public func setBackBarButtonItem(_ title: String?) {
        backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(goBack(_:)))
        backBarButtonItem?.tintColor = itemTintColor
    }

    /**
     Back to UIToolbar Change UIBarButtonitem to image.
     - Parameters:
     - image: Image of UIBarButtonitem
     */
    public func setBackBarButtonItem(_ image: UIImage?) {
        backBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(goBack(_:)))
        backBarButtonItem?.tintColor = itemTintColor
    }

    /**
     Forward to UIToolbar Change UIBarButtonitem to title.
     - Parameters:
     - title: Title of UIBarButtonitem
     */
    public func setForwardBarButtonItem(_ title: String?) {
        forwardBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(goForward(_:)))
        forwardBarButtonItem?.tintColor = itemTintColor
    }

    /**
     Forward to UIToolbar Change UIBarButtonitem to image.
     - Parameters:
     - image: Image of UIBarButtonitem
     */
    public func setForwardBarButtonItem(_ image: UIImage?) {
        forwardBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(goForward(_:)))
        forwardBarButtonItem?.tintColor = itemTintColor
    }
}

extension ToolView {
    /**
     Runs when the site is loaded.
     stopBarButtonItem appears.
     */
    func loadDidStart() {
        var items = historyBarButtonItem()
        if let stopBarButtonItem = stopBarButtonItem {
            items.append(contentsOf: [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                                      stopBarButtonItem])
        }
        toolbar.setItems(items, animated: false)
    }

    /**
     Run when the site is finished.
     refreshBarButtonItem appears.
     */
    func loadDidFinish() {
        var items = historyBarButtonItem()
        if let reloadBarButtonItem = reloadBarButtonItem {
            items.append(contentsOf: [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                                      reloadBarButtonItem])
        }
        toolbar.setItems(items, animated: false)
    }
}

extension ToolView {
    private func setupViews() {
        clipsToBounds = true

        addSubview(toolbar)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        toolbar.setItems(historyBarButtonItem(), animated: false)
        changeItemTintColor()
        changeBarTintColor()
        setHiddenRefresh()
    }
}

extension ToolView {
    private func historyBarButtonItem() -> [UIBarButtonItem] {
        guard let canGoBack = delegate?.toolViewWebCanGoBack,
            let canGoForward = delegate?.toolViewWebCanGoForward else { return [UIBarButtonItem]() }

        backBarButtonItem?.isEnabled = canGoBack
        forwardBarButtonItem?.isEnabled = canGoForward
        delegate?.toolViewInteractivePopGestureRecognizerEnabled(!canGoBack)

        var items = [UIBarButtonItem]()

        if let barButtonItem = backBarButtonItem {
            items.append(barButtonItem)
        } else {
            let barButtonItem = UIBarButtonItem(title: "◀︎", style: .plain, target: self, action: #selector(goBack(_:)))
            barButtonItem.isEnabled = canGoBack
            items.append(barButtonItem)
            backBarButtonItem = barButtonItem
        }

        if let barButtonItem = forwardBarButtonItem {
            items.append(barButtonItem)
        } else {
            let barButtonItem = UIBarButtonItem(title: "▶︎", style: .plain, target: self, action: #selector(goForward(_:)))
            barButtonItem.isEnabled = canGoForward
            items.append(barButtonItem)
            forwardBarButtonItem = barButtonItem
        }

        return items
    }
}

extension ToolView {
    private func changeItemTintColor() {
        backBarButtonItem?.tintColor = itemTintColor
        forwardBarButtonItem?.tintColor = itemTintColor
        reloadBarButtonItem?.tintColor = itemTintColor
        stopBarButtonItem?.tintColor = itemTintColor
    }

    private func changeBarTintColor() {
        backgroundColor = barTintColor
        toolbar.barTintColor = barTintColor
    }
}

extension ToolView {
    private func setHiddenRefresh() {
        if isHiddenRefresh {
            reloadBarButtonItem = nil
            stopBarButtonItem = nil
        } else {
            reloadBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reload(_:)))
            stopBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(stop(_:)))
            reloadBarButtonItem?.tintColor = itemTintColor
            stopBarButtonItem?.tintColor = itemTintColor
        }
    }
}

extension ToolView {
    @objc private func goBack(_ sender: UIBarButtonItem) {
        delegate?.toolViewWebGoBack()
    }

    @objc private func goForward(_ sender: UIBarButtonItem) {
        delegate?.toolViewWebGoForward()
    }

    @objc private func reload(_ sender: UIBarButtonItem) {
        delegate?.toolViewWebReload()
    }

    @objc private func stop(_ sender: UIBarButtonItem) {
        delegate?.toolViewWebStopLoading()
    }
}
