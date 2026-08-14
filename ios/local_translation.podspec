#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint local_translation.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'local_translation'
  s.version          = '0.0.1'
  s.summary          = 'On device translation and language detection for Flutter.'
  s.description      = <<-DESC
On device translation and language detection for Flutter.
                       DESC
  s.homepage         = 'https://github.com/ae1studio/local_translation'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Æ1' => 'https://github.com/ae1studio' }
  s.source           = { :path => '.' }
  s.source_files = 'local_translation/Sources/local_translation/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.frameworks = 'NaturalLanguage', 'SwiftUI'
  s.weak_frameworks = 'Translation'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '$(inherited) -weak_framework Translation'
  }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'local_translation_privacy' => ['local_translation/Sources/local_translation/PrivacyInfo.xcprivacy']}
end
