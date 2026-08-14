#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint local_translation.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'local_translation'
  s.version          = '0.0.3'
  s.summary          = 'On device translation and language detection for Flutter.'
  s.description      = <<-DESC
On device translation and language detection for Flutter.
                       DESC
  s.homepage         = 'https://github.com/ae1studio/local_translation'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Æ1' => 'https://github.com/ae1studio' }
  s.source           = { :path => '.' }
  s.source_files = 'local_translation/Sources/local_translation/**/*'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '10.15'
  s.frameworks = 'NaturalLanguage', 'SwiftUI'
  s.weak_frameworks = 'Translation'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '$(inherited) -weak_framework Translation'
  }
  s.swift_version = '5.0'
end
