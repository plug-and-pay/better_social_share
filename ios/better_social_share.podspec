Pod::Spec.new do |s|
  s.name             = 'better_social_share'
  s.version          = '0.1.0'
  s.summary          = 'Share directly to social apps with typed results instead of silent failures.'
  s.description      = <<-DESC
Share text, images, and videos directly to WhatsApp, Instagram, Facebook,
Messenger, Telegram, X, and SMS. No Facebook SDK required.
                       DESC
  s.homepage         = 'https://github.com/keesplugandpay/better_social_share'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Plug & Pay' => 'kees@plugandpay.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
