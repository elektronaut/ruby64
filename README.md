![Build](https://github.com/elektronaut/ruby64/workflows/Build/badge.svg)
[![Code Climate](https://codeclimate.com/github/elektronaut/ruby64/badges/gpa.svg)](https://codeclimate.com/github/elektronaut/ruby64)
[![Code Climate](https://codeclimate.com/github/elektronaut/ruby64/badges/coverage.svg)](https://codeclimate.com/github/elektronaut/ruby64)

# Ruby64

Ruby64 is a Commodore 64 emulator in written in Ruby. It is cycle accurate,
utilizing Fibers to emulate cycles.

Currently the memory map and 6510 CPU is working, sans
interrupts. It's running at about 10% of the original speed, Ruby is
currently too slow for realtime performance. SID emulation is probably
also out of the question.

## TODO

- Interrupts
- VIC-II emulation
- CIA 1/2
- C1541 emulation

## License

Copyright 2016 Inge Jørgensen

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
