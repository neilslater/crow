# Crow

C Ruby Object Writer. Utilities for speeding up drudge work parts of writing C extensions.

## What is it?

A set of templates to generate some of the C code for Ruby extensions. I found myself writing a
lot of boiler-plate C for other projects, and the gem includes templates for that C.

Although packaged as a gem, there is no intent to release this onto rubygems.

This project does not include documentation or tests. Use it at your own risk!

Feel free to fork this code and adapt it to your code generating needs.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
