# Talkies
A simple messagebox system for LÖVE, a rewrite of [Moan.lua](https://github.com/tanema/moan.lua)

```lua
Talkies.new("Title", "Hello world!")
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
- Break overflow to new message.
- Rich text, i.e. coloured/bold/italic text

## How to
Download the `talkies.lua` and place it in your project directory.

```lua
local Talkies = require('talkies')

function love.load()
  Talkies.new("Title", "Hello World!")
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

### Talkies.new(title, messages, config)
Create a new dialog of messages.

- **title** : string
- **messages**, a string or a table that contains strings
- **config**, table that contains message configs, takes;
  * `image`, message icon image e.g. `love.graphics.newImage("img.png")`
  * `onstart()`, function to be executed on message start
  * `onmessage(messages_left)`, function called after every message that is acknowledged
  * `oncomplete()`, function executed on message end
  * `options`, table, contains multiple-choice options
    - [1], string, a label for the option
    - [2], function to be called if option is selected

On the final message in the array of messages, the options will be displayed.
Upon pressing return, the function relative to the option will be called. There
can be "infinite" options, however the options will probably overflow depending
on your UI configuration.

To change the appearance of eah message please pass in the theming values described
below

#### Pauses
A double dash `--` causes them message to stop typing, and will only continue when
`Talkies.selectButton` is pressed, each `--` will be replaced with a space.

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

## Theming your message box
All of the following options can be set on the `Talkies.[attribute]` settings and
passed in as config to each new dialog created. For instance to set a default text
speed for all message boxes you would call `Talkies.textSpeed = "fast"` but then if
you wanted a single message to go slower you would create it like this.
`Talkies.new("Old man", "I talk very slow", {textSpeed = "slow"})`

The following are all of the message theme options:
* `textSpeed`, speed that the text is displayed. `slow`, `medium`, `fast` or number, default to fast.
* `typeSound` - Typing sound, should be a very short clip (e.g. `Talkies.typeSound = love.audio.newSource("typeSound.wav", "static")`)
* `optionSwitchSound` - Sound to be played when a option is selected
* `indicatorCharacter` - Character on the bottom right indicating more content (string), default: ">"
* `optionCharacter` - Character before option to indicate selection (string), default: "-"
* `font` - Message box font (e.g. `Talkies.font = love.graphics.newFont("Talkies/main.ttf", 32)`)
* `padding` - padding on the inside of the box, default is `10`
* `titleColor`, title text color.
* `messageColor`, message text color. Default is `{1, 1, 1}`
* `backgroundColor`, background color of the box. Default is `{0, 0, 0, 0.8}`
