# AppSwitcher

Quickly switch between applications using hotkeys

## Description

AppSwitcher is a Hammerspoon Spoon that enables quick launching and switching between different apps using hotkeys. This tool reduces the need for mouse movements or complex keyboard operations, thereby saving you valuable time.

## Download

[Download AppSwitcher.spoon](https://github.com/Nauxscript/app-switcher-spoon/tree/main/AppSwitcher.spoon)

## Installation

1. Download the AppSwitcher.spoon
2. Double-click the downloaded file to install it in your `~/.hammerspoon/Spoons` directory
3. Add the necessary configuration to your `~/.hammerspoon/init.lua` file

## Configuration

Here's an example configuration for your `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("AppSwitcher")
    :bindHotkeys({
        {name = "Claude", key = "c"},
        {name = "WeChat", key = "e", bundleId = "com.tencent.xinWeChat"},
        {name = "Google Chrome", key = "g"},
        {name = "Obsidian", key = "o"},
        {name = "Warp", key = "w"},
    })
```

In this example:
* `option + c` opens Claude
* `option + e` opens WeChat
* `option + g` opens Google Chrome
* `option + o` opens Obsidian
* `option + w` opens Warp

## How It Works

### Hotkey Matching Logic
* If the bundleId is specified, it will be used for matching. Otherwise, the app name will be used.

### Hotkey Trigger Logic
* When the option key is pressed and held for a short duration, a modal window will appear, displaying information about all configured apps and currently running apps.
* When a specific hotkey is pressed:
  - If the matching app is not running, it will be launched.
  - If the matching app is running but not in the foreground, it will be brought to the front.
  - If the matching app is running and in the foreground, it will be hidden.

## When to Use BundleId

You should provide the bundleId for an app when:
* The app continues running another process in the background when its window is closed by `command + w` (e.g., WeChat)
* The app has different names in different languages (e.g., WeChat in Chinese is "微信"). Using the name to match in these cases may not work properly.

## Contributing

Contributions to AppSwitcher are welcome! Please feel free to submit a Pull Request.

## License

[MIT License](LICENSE)