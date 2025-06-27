# Installation

Learn how to integrate DevLogCapture into your iOS project.

## Requirements

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+

## Swift Package Manager

Add DevLogCapture to your project using Swift Package Manager:

1. In Xcode, select **File** > **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/your-username/DevLogCapture`
3. Select the version range or specific version
4. Add the package to your target

```swift
dependencies: [
    .package(url: "https://github.com/your-username/DevLogCapture", from: "1.0.0")
]
```

## CocoaPods

Add this line to your `Podfile`:

```ruby
pod 'DevLogCapture', '~> 1.0'
```

Then run:

```bash
pod install
```

## Manual Installation

1. Download the framework or clone the repository
2. Drag `DevLogCapture.framework` into your Xcode project
3. Make sure to check "Copy items if needed"
4. Add the framework to your target's "Embedded Binaries"

## Framework Configuration

After installation, you need to configure your project:

### Info.plist Configuration

Add the following permissions to your `Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app uses local networking to serve debug logs for development purposes.</string>
<key>NSBonjourServices</key>
<array>
    <string>_http._tcp</string>
</array>
```

### Network Security

For development builds, you may need to allow arbitrary loads in your `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

⚠️ **Note**: Only use these settings for development builds. Remove them for production releases.

## Next Steps

- <doc:QuickStart>
- <doc:Configuration>
