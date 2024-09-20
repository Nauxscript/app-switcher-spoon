--- === AppSwitcher ===
---
--- Quickly switch between applications using hotkeys
---
--- Download: [https://github.com/Nauxscript/app-switcher-spoon/tree/main/AppSwitcher.spoon.zip](https://github.com/Nauxscript/app-switcher-spoon/tree/main/AppSwitcher.spoon.zip)
---
--- Quickly launch and switch between different apps using hotkeys, 
--- reducing the need for mouse movements or complex keyboard operations, 
--- and saving you valuable time.
---
--- Example `~/.hammerspoon/init.lua` configuration:
---
--- ```
--- hs.loadSpoon("AppSwitcher")
---     :bindHotkeys({
---         {name = "Claude", key = "c", },
---         {name = "WeChat", key = "e", bundleId = "com.tencent.xinWeChat"},
---         {name = "Google Chrome", key = "g"},
---         {name = "Obsidian", key = "o"},
---         {name = "Warp", key = "w"},
---     })
--- ```
---
--- In this example, 
--- * `option + c` to open Claude
--- * `option + e` to open WeChat
--- * `option + g` to open Google Chrome
--- * `option + o` to open Obsidian
--- * `option + w` to open Warp
---
--- The hotkey matching logic of this spoon works as follows:
--- * If the bundleId is specified, prefer to match the bundleId, otherwise match the name.
---
--- The hotkey trigger logic of this spoon works as follows:
--- * When the option key is pressed and held for a short duration, 
--- a modal window will be displayed, show all the configured apps info and the running apps info,
--- * when the specific hotkey is pressed, the matching app will be opened if it is not running. 
--- * when the specific hotkey is pressed, the matching app will be activated if it is running and not in the foreground.
--- * when the specific hotkey is pressed, the matching app will be hide if it is running and in the foreground.
---
--- When should you give the bundleId to the app?
--- * some apps will running another process in the background when it window is closed by `command + w` (e.g. WeChat)
--- * some apps get different name in different language (e.g. WeChat in Chinese is "微信"), if using name to match, it will not working properly.

local switcher = {}

-- Metadata
switcher.name = "AppSwitcher"
switcher.version = "0.1"
switcher.author = "Nauxscript"
switcher.homepage = "https://github.com/Nauxscript/app-switcher-spoon"
switcher.license = "MIT - https://opensource.org/licenses/MIT"

-- setup shortcut for apps
switcher.apps = {}

local optKeyTimer = nil
local optKeyPressTime = 0
local longPressThreshold = 1 -- long press threshold (seconds)
local modalFrame = nil

local function toggleApp(app)
    local application = hs.application.get(app.bundleId or app.name)
    if application then
        if application:isFrontmost() and #application:visibleWindows() > 0 then
            application:hide()
        else
            application:activate()
            hs.timer.doAfter(0.1, function()
                -- hs.alert.show(application:bundleID())
                if #application:visibleWindows() == 0 then
                    hs.application.open(app.bundleId or app.name)
                end
            end)
        end
    else
        hs.application.launchOrFocus(app.name)
    end
end

function switcher:bindHotkeys(mapping)
    -- store mapping
    self.apps = mapping
    -- bind shortcut
    for _, app in ipairs(self.apps) do
        hs.hotkey.bind({"option"}, app.key, function()
            toggleApp(app)
            if (optKeyTimer) then
                -- hs.alert.show("Option 长按清除")
                optKeyTimer:stop()
                optKeyTimer = nil
                if modalFrame then
                    modalFrame:delete()
                    modalFrame = nil
                end
            end
        end)
    end
end

local function getRunningApps()
    local apps = {}
    for _, app in ipairs(hs.application.runningApplications()) do
        if app:kind() == 1 then -- 1 表示普通应用程序
            table.insert(apps, {
                name = app:name(),
                bundleID = app:bundleID()
            })
        end
    end
    return apps
end

-- check if app is configured
local function isAppConfigured(appName)
    for _, app in ipairs(switcher.apps) do
        if app.name == appName then
            return true
        end
    end
    return false
end

local function showModal()
    if modalFrame then
        modalFrame:delete()
    end

    local runningApps = getRunningApps()
    local configuredAppsText = "Configured Apps:\n\n"
    local unconfiguredAppsText = "Unconfigured Apps:\n\n"

    -- classify apps
    for _, app in ipairs(runningApps) do
        local appInfo = app.name .. " [bundleID: " .. (app.bundleID or "N/A") .. "]\n"
        if isAppConfigured(app.name) then
            local configuredApp = nil
            for _, cfgApp in ipairs(switcher.apps) do
                if cfgApp.name == app.name then
                    configuredApp = cfgApp
                    break
                end
            end
            if configuredApp then
                configuredAppsText = configuredAppsText .. "【" .. configuredApp.key .. "】 " .. appInfo
            end
        else
            unconfiguredAppsText = unconfiguredAppsText .. appInfo
        end
    end

    local modalText = configuredAppsText .. "\n" .. unconfiguredAppsText

    -- get main screen size
    local screen = hs.screen.mainScreen()
    local screenFrame = screen:frame()

    -- set modal frame size
    local modalWidth = 800
    local modalHeight = 600

    -- calculate center position
    local modalX = (screenFrame.w - modalWidth) / 2
    local modalY = (screenFrame.h - modalHeight) / 2

    modalFrame = hs.canvas.new({x=modalX, y=modalY, w=modalWidth, h=modalHeight})
    modalFrame:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    modalFrame:level(hs.canvas.windowLevels.modalPanel)

    modalFrame[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = {alpha = 0.7, white = 0.1},
        roundedRectRadii = {xRadius = 10, yRadius = 10},
    }
    modalFrame[2] = {
        type = "text",
        text = modalText,
        textColor = {white = 1},
        textSize = 16,
        textAlignment = "left",
        frame = {x = "5%", y = "5%", w = "100%", h = "100%"}
    }

    modalFrame:show()
end

opt_tap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
    local whichFlags = event:getFlags()
    if whichFlags['alt'] then
        -- hs.alert.show("Option 键按下")
        optKeyPressTime = hs.timer.secondsSinceEpoch()
        optKeyTimer = hs.timer.doAfter(longPressThreshold, function()
            -- hs.alert.show("Option 键长按")
            showModal()
        end)
    else
        if optKeyTimer then
            optKeyTimer:stop()
            optKeyTimer = nil
            -- hs.alert.show("Option 键释放")
            -- delay 1 second to delete modal frame
            hs.timer.doAfter(1, function()
                if modalFrame then
                    modalFrame:delete()
                    modalFrame = nil
                end
            end)
        end
    end
end)

opt_tap:start()

hs.alert.show("App Switcher Loaded")

return switcher
