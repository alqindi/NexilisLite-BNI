#
#  Be sure to run `pod spec lint PalioLite.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|
  spec.name         = "NexilisLite"
  spec.version      = "1.0.2"
  spec.summary      = "NexilisLite Framework"
  spec.description  = <<-DESC
  NexilisLite Framework, embed Contact Center, Live Streaming, Push Notifications, Instant Messaging, Video and VoIP Calling features into your mobile apps within minutes...
                   DESC

  spec.homepage     = "https://github.com/yayandw/qmeralite/"
  spec.license      = "MIT"
  spec.author       = { "Yayan D Wicaksono" => "ya2n.wicaksono@gmail.com" }
  spec.ios.deployment_target = "14.0"
  # spec.source       = { :http => 'https://github.com/yayandw/QmeraLite/releases/download/v1.0.2/QmeraLite.zip' }
  spec.source       = { :path => '.' }
  spec.source_files = 'NexilisLite/Source/**/*'
  spec.resource_bundles = { 'NexilisLite' => ['NexilisLite/Resource/**/*']}
  spec.swift_version = '5.5.1'
  spec.dependency 'FMDB', '~> 2.7.5'
  # spec.dependency 'nuSDKService', '~> 0.0.7'
  spec.dependency 'NotificationBannerSwift', '~> 3.0.0'
  spec.dependency 'ReadabilityKit'
  spec.dependency 'GoogleMLKit/FaceDetection', '2.6.0'
  spec.dependency 'GoogleUtilitiesComponents', '~> 1.1'
  spec.static_framework = true
  # spec.preserve_path = 'NexilisLite.framework'
  # spec.xcconfig = { 'OTHER_LDFLAGS' => '-framework NexilisLite' }
  spec.ios.vendored_frameworks = "NexilisLite.framework", "Frameworks/nuSDKService.framework", "Frameworks/libwebp.framework", "Frameworks/SDWebImage.framework", "Frameworks/SDWebImageWebPCoder.framework"
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'ENABLE_BITCODE' => 'NO' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'ENABLE_BITCODE' => 'NO' }
end
