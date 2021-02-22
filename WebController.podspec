#
# Be sure to run `pod lib lint WebController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WebController'
  s.version          = '0.3.1'
  s.summary          = 'UIViewController with easy WKWebView'
  s.description      = <<-DESC
  A UIViewController with a WKWebView.
  There is a UIProgressView to show the loading status of the site.
  This is done when the scheme is not http or https.
  Dynamically changing data can be handled by a delegate.
                       DESC
  s.homepage         = 'https://github.com/pikachu987/WebController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'pikachu987' => 'pikachu77769@gmail.com' }
  s.source           = { :git => 'https://github.com/pikachu987/WebController.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.swift_version = '5.0'
  s.source_files = 'WebController/Classes/**/*'
end
