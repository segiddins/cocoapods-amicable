# cocoapods-amicable

A small CocoaPods plugin that moves the Podfile checksum to a file in the Sandbox,
reducing merge conflicts for teams that don't commit their Pods directory.

## Installation

    $ gem install cocoapods-amicable

## Usage

```ruby
# Podfile

plugin 'cocoapods-amicable'
```
