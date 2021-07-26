# Talkies
A simple messagebox system for LÖVE, a rewrite of [Moan.lua](https://github.com/tanema/moan.lua)

```lua
Talkies.say("Title", "Hello world!")
```

## Features
- Multiple choices prompt
- Typing effect + sounds
- Pauses
- UTF-8 support
- Message box icons
- Autowrapped text
- General theming and per-message theming

### To do:
Break overflow to new message. Currently if your message is too large for the display
of the message box, it will overflow the box and will not be displayed. Be careful
and make sure all your messages work on all of the resolutions you use.

## How to
Download the `talkies.lua` and place it in your project directory.

```lua
local Talkies = require('talkies')

function love.load()
  Talkies.say("Title", "Hello World!")
end

function love.update(dt)
  Talkies.update(dt)
end

function love.draw()
  Talkies.draw()
end

function love.keypressed(key)
  if key == "space" then Talkies.onAction()
  elseif key == "up" then Talkies.prevOption()
  elseif key == "down" then Talkies.nextOption()
  end
end
```

## API

### Talkies.say(title, messages, config)
Create a new dialog of messages and returns that dialog.

- **title** : string; if set to `""`, title box will not appear
- **messages**, a string or a table that contains strings
- **config**, table that contains message configs, takes;
  * `image`, message icon image e.g. `love.graphics.newImage("img.png")`
  * `onstart(dialog)`, function to be executed on message start
  * `onmessage(dialog, messages_left)`, function called after every message that is acknowledged
  * `oncomplete(dialog)`, function executed on message end
  * `options`, table, contains multiple-choice options
    - [1], string, a label for the option
    - [2], function to be called if option is selected

On the final message in the array of messages, the options will be displayed.
Upon pressing return, the function relative to the option will be called. There
can be "infinite" options, however the options will probably overflow depending
on your UI configuration.

To change the appearance of each message please pass in the theming values described
below

#### Pauses
A double dash `--` causes them message to stop typing, and will only continue when
`Talkies.selectButton` is pressed. (Be sure to follow each `--` with a space if you
want text to wrap correctly!)

### Talkies.update(dt)
Update will update the UI with the dt and animate the typing

### Talkies.draw()
Draw the UI of the dialog

### Talkies.clearMessages()
Removes all messages from the queue and closes the messagebox. This will quit all dialogs.

### Talkies.prevOption()
Will move the option selector to the previous option. This can be safely called at any
time so you can bind your actions all at once.

### Talkies.nextOption()
Will move the option selector to the next option. This can be safely called at any
time so you can bind your actions all at once.

### Talkies.onAction()
This is the main interaction with the dialog. If the message is fully displayed,
it will show the next message. If the message is paused, it will resume. If the
message has options shown, it will select the option. This can safely be called
at any time.

### Talkies.isOpen()
isOpen will return true if Talkies is currently drawing dialogs. It will return
false otherwise.

## Theming your message box
All of the following options can be set on the `Talkies.[attribute]` settings and
passed in as config to each new dialog created. For instance to set a default text
speed for all message boxes you would call `Talkies.textSpeed = "fast"` but then if
you wanted a single message to go slower you would create it like this.
`Talkies.say("Old man", "I talk very slow", {textSpeed = "slow"})`

The following are all of the message theme options:
* `textSpeed` - speed that the text is displayed. `slow`, `medium`, `fast` or number, default to fast.
* `talkSound` - Sound to be played when the character speaks, should be a very short clip (e.g. `Talkies.typeSound = love.audio.newSource("typeSound.wav", "static")`)
* `optionSwitchSound` - Sound to be played when a option is selected
* `indicatorCharacter` - Character on the bottom right indicating more content (string), default: ">"
* `optionCharacter` - Character before option to indicate selection (string), default: "-"
* `inlineOptions` - Sets whether options should be displayed within the message box or if they should be displayed in a separate box, default: `true`
* `font` - Message box font (e.g. `Talkies.font = love.graphics.newFont("Talkies/main.ttf", 32)`)
* `padding` - padding on the inside of the box, default is `10`
* `thickness` - thickness of box borders. Default is `0` (no border).
* `rounding` - radius in pixels of box corners. Default is `0` (no rounding).
* `titleColor` - title text color. Default is `{1, 1, 1}` (when `nil`, uses message text color).
* `titleBackgroundColor` - background color for title box. Default is `nil` (when `nil`, uses message background color).
* `titleBorderColor` - border color for title box. Default is `nil` (when `nil`, uses message border color).
* `messageColor` - message text color. Default is `{1, 1, 1}`
* `messageBackgroundColor` - background color of the message box. Default is `{0, 0, 0, 0.8}`
* `messageBorderColor` - border color of the message box. Default is `nil` (when `nil`, uses message background color).
* `typedNotTalked` - when making a sound while talking, if this is set to true the
  noise will be made for every character. If set to false the noise will be looped,
  and the pitch will be oscillated randomly between the pitchValues setting. default to true
* `pitchValues` - If `typedNotTalked` is set to false then this table value will be
  used to choose values of pitch while talking. If you want no pitch change set it to
  {1}, Default is {0.7, 0.8, 1.0, 1.2, 1.3}

### dialog:isShown()
isShown will return true if the dialog is currently the dialog on the screen and
false otherwise

example:
```
local firstdialog = Talkies.say("title", "message")
local seconddialog = Talkies.say("title", "message")
firstdialog:isShown() //true
seconddialog:isShown() //false, will return true when Talkies.onAction() is called
```

### Building a script

[Erogodic](https://github.com/oniietzschan/erogodic) is a library for scripting
branching interactive narrative in Lua, you can check out it's use by running the
main.lua in that repo.
