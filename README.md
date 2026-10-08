# Crow

C Ruby Object Writer. Utilities for speeding up drudge work parts of writing C extensions.

## What is it?

A set of templates to generate some of the C code for Ruby extensions. I found myself writing a
lot of boiler-plate C for other projects, and the gem includes templates for that C.

Although packaged as a gem, there is no intent to release this onto rubygems. Also, there is an
existing gem `crow` for API mocking, so it would need a name change at the very least.

Feel free to fork this code and adapt it to your code generating needs.

## Generated object contracts

Generation validates declarations and renders the complete requested file set
before writing. Unsupported shapes, pointer/NArray writers, readable `char*`
fields and conflicting names raise `ArgumentError` without changing the target.
Successful generation retains the existing overwrite/skip rules; filesystem
write failures are not transactional updates.

NArray shapes use `shape_exprs` with a fixed rank of 1–62 (inferred from the
list when omitted; the target Numo build may impose a smaller platform limit). The minimal NArray declaration means one dimension of length one.
Pointer fields require `size_expr` and `store: false`. Allocation expressions
support integer literals, integral `$parameter`/`%attribute` references and
checked arithmetic; the pointer `.name` shorthand refers to a constructor
parameter. Storage-control attributes cannot have generated writers.

Generated wrappers support `allocate` followed by one initialization, normal
`dup`/`clone`, and shallow Ruby freezing. Uninitialized access, repeated
initialization and direct copying into an initialized destination raise.
C-owned buffers copy independently; ordinary Ruby VALUE references stay shallow.
Generated helper names remain stable, but private storage bookkeeping changes
native layouts: rebuild all affected native sources after regeneration.

`to_h` snapshots stored fields using C field-name symbol keys. `from_h` preserves
subclasses, validates inputs, reconstructs supported residual storage and copies
NArray logical contents into independent packed storage. Non-stored pointer
contents reset to their initializer; they are not serialized. Models needing
unrecoverable constructor inputs or opaque restoration expressions reject
`from_h` with an explanation. Custom native bindings must honor wrapper freezing,
keep Ruby owners reachable and transfer each raw allocation to only one owner.

Generated specs use exposed Ruby names and shared constructor fixtures. Where a
custom C expression cannot yield a safe automatic expectation, the generated
example is explicitly pending and asks for a user-authored fixture/expectation.

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
