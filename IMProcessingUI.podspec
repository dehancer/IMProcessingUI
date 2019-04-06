Pod::Spec.new do |s|

  s.name         = 'IMProcessingUI'
  s.version      = '0.12.1'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'denn nevera' => 'denn.nevera@gmail.com' }
  s.homepage     = 'http://dehancer.photo'
  s.summary      = 'IMProcessingUI is an IMProcessing UI extention framework'
  s.description  = 'IMProcessingUI is an IMProcessing UI extention framework uses to create iOS/OSX UI,camera interaction between filters and UI'

  s.source       = { :git => 'https://bitbucket.org/degrader/improcessingui.git', :tag => s.version }

  s.osx.deployment_target = "10.12"
  s.ios.deployment_target = "10.0"
  s.swift_version = "5.0"

  s.source_files        = 'IMProcessingUI/Classes/**/*.{h,swift,m}', 'IMProcessingUI/Classes/*.{swift}', 'IMProcessingUI/Classes/**/*.h', 'IMProcessingUI/Classes/Shaders/*.{h,metal}'
  s.public_header_files = 'IMProcessing/Classes/**/*.h','IMProcessing/Classes/Shaders/*.h'
  s.frameworks = 'Metal'
  s.dependency  'IMProcessing'
  #
  # latest version cocoapods does not work with s.xcconfig ingeritance
  # s.xcconfig     =   { 'MTL_HEADER_SEARCH_PATHS' => '$(inherited)  $(PODS_CONFIGURATION_BUILD_DIR)/IMProcessingUI/IMProcessingUI.framework/Headers $(PODS_CONFIGURATION_BUILD_DIR)/IMProcessingUI-OSX/IMProcessingUI.framework/Headers $(PODS_CONFIGURATION_BUILD_DIR)/IMProcessingUI-iOS/IMProcessingUI.framework/Headers'}

  s.requires_arc = true

end
