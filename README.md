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

### To do:
- Break overflow to new message.
- Add simple theming interface `setTheme`
- Rich text, i.e. coloured/bold/italic text

## How to
Download the `talkies.lua` and place it in your project directory.

```lua
local Talkies = require('talkies')

function love.load()
  Talkies.new("Title", {"Hello World!"})
end

function love.update(dt)
  Talkies.update(dt)
end

function love.draw()
  Talkies.draw()
end

function love.keypressed(key)
  Talkies.keypressed(key)
end
```

## API

### Talkies.new(title, messages, config)
- **title** : string
- **messages**, a string or a table, contains strings
- **config**, table, contains message configs, takes;
  * `titleColor`, title text color. Default is `{255, 255, 255}`
  * `messageColor`, message text color. Default is `{255, 255, 255}`
  * `boxColor`, background color of the box. Default is `{ 0, 0, 0, 222 }`
  * `image`, message icon image e.g. `love.graphics.newImage("img.png")`
  * `onstart`, function to be executed on message start
  * `oncomplete`, function executed on message end
  * `options`, table, contains multiple-choice options
    - [1], string describing option
    - [2], function to be exected if option is selected

On the final message in the array of messages, the options will be displayed.
Upon pressing return, the function relative to the option will be called. There
can be "infinite" options, however the options will probably overflow depending
on your UI configuration.

#### Pauses
A double dash `--` causes them message to stop typing, and will only continue when
`Talkies.selectButton` is pressed, each `--` will be replaced with a space.


### Talkies.update(dt)
Update will update the UI with the dt and animate the typing

### Talkies.draw()
Draw the UI of the dialog

### Talkies.setSpeed(speed)
Controls the speed at which letters are typed. Speed can be: ["fast", "medium", "slow"]
or a number. Default is `0.01`

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

## Configuration
* `Talkies.typeSound` - Typing sound, should be a very short clip (e.g. `Talkies.typeSound = love.audio.newSource("typeSound.wav", "static")`)
* `Talkies.optionSound` - Sound to be played when a option is selected
* `Talkies.indicatorCharacter` - Character on the bottom right indicating more content (string), default: ">"
* `Talkies.optionCharacter` - Character before option to indicate selection (string), default: "-"
* `Talkies.font` - Message box font (e.g. `Talkies.font = love.graphics.newFont("Talkies/main.ttf", 32)`)
* `Talkies.boxHeight` - height of the dialog box. Default is `118`
* `Talkies.padding` - padding on the inside of the box, default is `10`
