import UIKit

protocol ToolViewDelegate: class {
    var toolViewWebCanGoBack: Bool { get }
    var toolViewWebCanGoForward: Bool { get }
    func toolViewWebGoBack()
    func toolViewWebGoForward()
    func toolViewWebReload()
    func toolViewWebStopLoading()
    func toolViewInteractivePopGestureRecognizerEnabled(_ isEnabled: Bool)
}

public class ToolView: UIView {
    weak var delegate: ToolViewDelegate?
    
    public lazy var toolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(toolbar)
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
        bottomConstraint.priority = UILayoutPriority(500)
        self.addConstraints([topConstraint, bottomConstraint])
        return toolbar
    }()
    
    private var toolViewHeightConstraint: NSLayoutConstraint?
    
    private var backBarButtonItem: UIBarButtonItem?
    
    private var forwardBarButtonItem: UIBarButtonItem?
    
    private lazy var reloadBarButtonItem: UIBarButtonItem? = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.reload(_:)))
    
    private lazy var stopBarButtonItem: UIBarButtonItem? = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(self.stop(_:)))
    
    public var itemTintColor: UIColor? {
        didSet {
            self.changeItemTintColor()
        }
    }
    
    public var barTintColor: UIColor? {
        didSet {
            self.changeBarTintColor()
        }
    }
    
    public var isHiddenRefresh: Bool = false {
        didSet {
            self.setHiddenRefresh()
        }
    }
    
    public var isHiddenToolBar: Bool = false {
        didSet {
            self.toolViewHeightConstraint?.priority = UILayoutPriority(self.isHiddenToolBar ? 750 : 250)
        }
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        let toolViewHeightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 0)
        toolViewHeightConstraint.priority = UILayoutPriority(self.isHiddenToolBar ? 750 : 250)
        self.addConstraint(toolViewHeightConstraint)
        self.toolViewHeightConstraint = toolViewHeightConstraint
        
        self.clipsToBounds = true
        self.toolbar.setItems(self.historyBarButtonItem(), animated: false)
        self.changeItemTintColor()
        self.changeBarTintColor()
        self.setHiddenRefresh()
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
    
    public func setBackBarButtonItem(_ title: String?) {
        self.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(self.goBack(_:)))
        self.backBarButtonItem?.tintColor = self.itemTintColor
    }
    
    public func setBackBarButtonItem(_ image: UIImage?) {
        self.backBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(self.goBack(_:)))
        self.backBarButtonItem?.tintColor = self.itemTintColor
    }
    
    public func setForwardBarButtonItem(_ title: String?) {
        self.forwardBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(self.goForward(_:)))
        self.forwardBarButtonItem?.tintColor = self.itemTintColor
    }
    
    public func setForwardBarButtonItem(_ image: UIImage?) {
        self.forwardBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(self.goForward(_:)))
        self.forwardBarButtonItem?.tintColor = self.itemTintColor
    }
    
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
