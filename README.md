# Crow

C Ruby Object Writer. Utilities for speeding up drudge work parts of writing C extensions.

## What is it?

A set of templates to generate some of the C code for Ruby extensions. I found myself writing a
lot of boiler-plate C for other projects, and the gem includes templates for that C.

Although packaged as a gem, there is no intent to release this onto rubygems. Also, there is an
existing gem `crow` for API mocking, so it would need a name change at the very least.

Feel free to fork this code and adapt it to your code generating needs.

## Development

Crow requires Ruby 3.3 or newer. The maintained CI matrix covers Ruby 3.3, 3.4, and 4.0.

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

Run the complete validation gate with `bundle exec rake`. RuboCop inherits the
shared base, Rake, RSpec, and native-extension profiles from
`ncs_rubocop_conf` v0.2.0. Refactor lint offenses by default and consult the
operator before adding, retaining, or widening an exception. Every approved
local exception must have an immediately preceding `# RuboCop rationale:`
comment. Run `bundle exec ncs-rubocop-conf-audit` after lint changes and report
the final local exception inventory.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
