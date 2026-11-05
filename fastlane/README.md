fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

CI/CD 自动化：自动递增 Build Number、编译打包并上传到 TestFlight

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

本地专用：仅上传元数据与截图到 App Store Connect（不提交审核，便于预览和反复修改）

### ios submit_review

```sh
[bundle exec] fastlane ios submit_review
```

本地专用：指定已上传的构建版本、同步最新截图与元数据，并直接自动提交 App Store 审核

### ios upload_and_submit

```sh
[bundle exec] fastlane ios upload_and_submit
```

本地专用：上传已构建好的 ipa、等待处理、关联版本并自动提交审核

### ios release

```sh
[bundle exec] fastlane ios release
```

本地专用全流程：本地构建、上传二进制包、同步资料截图并提交审核

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
