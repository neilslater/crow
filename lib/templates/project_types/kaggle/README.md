# KaggleSkeleton

Ruby skeleton solver for Kaggle Christmas competitions e.g. *Helping Santa's Helpers*
from December 2014.

For competition details, and problem data (which you will need to fetch separately to run this code),
see e.g. http://www.kaggle.com/c/helping-santas-helpers

This is not a fully functional library. You can use this code as a project template for data optimisation
competitions. To do so requires good knowledge of Ruby with native extensions in C.

The project template includes some implementations in C of algorithms that might be useful for a
Kaggle competition:

 * Mersenne Twister PRNG. Although this is available in core Ruby, it can be more efficient to use the C lib directly.

## Installation

 * You need a Ruby interpreter, recommended version 2.1.4 or higher, with support for compiling native extensions.

 * Copy this repo locally, and make the directory with the README.md your current directory

 * Install dependencies:


    $ bundle install


 * Place a copy of ```data.csv``` in the ```data``` folder.

 * Compile, import, test and run:


    $ bundle exec rake


This should compile the C code, import the problem data from the CSV file (into Ruby's NArray
format), run the unit tests, and then run the default solution. The process should take
around XX minutes in total. The output is saved to ```data/submission.csv```.


## Contributing

1. Fork it ( https://github.com/slobo777/kaggle_skeleton/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
