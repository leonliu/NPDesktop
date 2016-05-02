Pod::Spec.new do |spec|
  spec.name         = 'RFBConnection'
  spec.version      = '0.1.0'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/ReDetection/RFBConnection'
  spec.authors      = { 'Liu Leon' => 'liu.l.leon@gmail.com' }
  spec.summary      = 'RFB (VNC) client library for iOS'

  spec.source       = { :git => 'https://github.com/ReDetection/RFBConnection', :tag => "#{spec.version}" }
  spec.source_files = 'NPDesktop/{3rdparty,datamodel,jpeg,protocol,utilities}/*.{h,m,c}'
  spec.prefix_header_file = 'NPDesktop/NPDesktop-Prefix.pch'

  spec.libraries = 'z'
  spec.vendored_libraries = 'libjpeg.a'
end
