# Pin Pong

A small, landscape iPhone Pong game built with SwiftUI and SpriteKit.

## Build an unsigned IPA with GitHub Actions

1. Extract this project archive on your computer.
2. Open your GitHub repository: `https://github.com/kyuuriq197/Pin-Pong`.
3. Choose **Add file → Upload files**.
4. Upload `project.yml`, `Info.plist`, the `Sources` folder, and the `.github/workflows/ios.yml` workflow. Keep the folder structure exactly as shown.
5. Commit the files to the `main` branch.
6. Open the repository's **Actions** tab and select **Build Pin Pong IPA**.
7. When the run finishes, open it and download the `Pin-Pong-unsigned-IPA` artifact.

The IPA is unsigned. It is a build artifact, not ready for direct installation. To install it on a physical iPhone, it must be signed with a valid Apple development/distribution certificate and provisioning profile.

## Requirements

- Xcode (the workflow uses the macOS GitHub Actions runner)
- XcodeGen (installed automatically by the workflow)
- iOS 15.0 or later
