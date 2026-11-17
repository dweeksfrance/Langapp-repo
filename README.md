# Langapp

An iOS app for writing messages that picks the keyboard language from the contact's phone number.

| Contact's number | Keyboard |
|---|---|
| UK (+44) | English (UK) |
| US (+1) | English (US) |
| French, including overseas (+33, +262, +508, +590, +594, +596, +681, +687, +689, or 0X XX XX XX XX) | Asks you the first time, then remembers your choice for that contact |
| Anything else | Left as it is |

If a contact has several numbers, the first UK, US or French number in the contact card decides. For French contacts, the globe button in the compose screen lets you change the remembered language.

Numbers without a country code are read using the iPhone's region setting.

The app can only switch to keyboards you have enabled in **Settings › General › Keyboard › Keyboards**. If the right keyboard isn't enabled, the compose screen tells you. You can still change keyboard by hand with the globe key at any time.

Sending hands the text to Messages.

## Build

```sh
brew install xcodegen
xcodegen            # creates Langapp.xcodeproj
open Langapp.xcodeproj
```

Set your team and bundle identifier under *Signing & Capabilities*, then run on a device. The simulator usually has only one keyboard, so switching is hard to see there.

## Tests

The phone-number rules and the remembered choices are in `Packages/LangappCore`:

```sh
cd Packages/LangappCore && swift test
```
