Pod::Spec.new do |s|
  s.name         = "KSWebView"
  s.version      = "1.0.0"
  s.summary      = "KSWebView Powerful WKWebView successors"

  s.description  = "KSWebView Powerful WKWebView successors"

  s.homepage     = "https://github.com/kinsunlu/KSWebView"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author       = { "kinsunlu" => "kinsunlu@sina.com" }

  s.platform     = :ios, "8.0" 

  s.source       = { :git => "https://github.com/kinsunlu/KSWebView.git", :tag => "#{s.version}" }

  s.source_files  = "KSWebView/*.{h,m}"
  s.public_header_files = "KSWebView/*.h"
  

  s.dependency "MJExtension", "~> 3.0.15.1"

end
