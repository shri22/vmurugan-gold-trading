Pod::Spec.new do |s|
  s.name             = 'PaymentGatewaySwiftSDK'
  s.version          = '1.0.2'
  s.summary          = 'Omniware Payment Gateway Swift SDK'
  s.description      = 'Local framework for Omniware Payment Gateway integration'
  s.homepage         = 'https://omniware.in'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Omniware' => 'support@omniware.in' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  
  s.vendored_frameworks = 'PaymentGatewaySwiftSDK.framework'
  s.preserve_paths = 'PaymentGatewaySwiftSDK.framework'
  
  s.pod_target_xcconfig = { 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'DEFINES_MODULE' => 'YES'
  }
end

