#!/usr/bin/env just --justfile

# Intellij에서 Just 플러그인 설치
# brew uninstall
# brew install --cask flutter

# 출시때
# just clean-and-install
# just build-ios-production

default:
    @just --list

gen-code:
  /opt/homebrew/bin/dart run build_runner build

clean-and-install:
  time flutter clean
  time cd ios && pod cache clean —all
  time cd ios && rm -rf Podfile.lock
  time flutter pub get
  time cd ios && pod install --repo-update

build-ios-staging:
  flutter build ipa --dart-define-from-file=.env.staging.json

build-ios-production:
  #flutter build ipa --dart-define-from-file=.env.production.json
  time flutter build ipa --dart-define-from-file=.env
  /usr/bin/open build/ios/ipa

clean-build-ios-production:
  time cd ios && xcodebuild clean
  cd ..
  time flutter clean
  just build-ios-production

build-android-production:
  time flutter build appbundle --no-tree-shake-icons --dart-define-from-file=.env
  /usr/bin/open build/app/outputs/bundle/release
  /usr/bin/open build/app/intermediates/merged_native_libs/release/out/lib

apk-release:
  flutter build apk --release --target-platform=android-arm64
  /usr/bin/open build/app/outputs/apk/release/

## Firebase: 프로젝트 설정 -> 내 앱 -> SHA 인증서 지문 추가
android-keystore-release-key-hash-for-firebase:
   keytool -list -v -keystore  ~/.config/android-keystores/sanbo/upload-keystore.jks -alias upload

test:
  time flutter test ./test/api/*