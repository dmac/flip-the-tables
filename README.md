flip-the-tables (╯°□°）╯︵ ┻━┻
============================

flip-the-tables is yet another ruby version switcher, in the vein of [RVM](http://beginrescueend.com/) and
[rbenv](https://github.com/sstephenson/rbenv). The philosophy of flip-the-tables is that choosing ruby
versions should be a trivial task best solved in the simplest manner possible. It was partially inspired by
[this blog post](http://chris.mowforth.com/si-because-rvm-and-rbenv-are-overkill), although I am using a very
different approach.

Design goals
------------

* I want to switch ruby versions with a shell command or possibly by cd-ing to a directory with a special file
* I want the ruby version to stay the same in my shell until I change it, and I want to change my version
  without affecting other shells
* I don't want to override any common shell functions or replace `ruby`, `irb`, `gem`, etc with shell shims
* I want ruby switching to be _fast_
* I want as few lines of bash as possible, because bash scripting sucks

Installation
------------

Decide where to keep your rubies (I'll assume `~/.rubies`). This will be `$RUBIES`. In that directory, install
your ruby versions using Sam Stephenson's excellent [ruby-build](https://github.com/sstephenson/ruby-build).
They should each be in folders with their names; e.g. `1.9.2-p290/`.

Next, download `ft.sh` from this repo and put it somewhere on your machine. Add the following lines to your
`.bash_profile` or `.bashrc`:

    export RUBIES=$HOME/.rubies
    export PATH=$RUBIES/1.9.2-p290/bin:$PATH
    source ~/path/to/ft.sh

Notice that in the first line you should substitute your chosen location, and in the second you should
substitute the path to your desired default Ruby.

Open up a new shell or source your rc files and you're all set.

Usage
-----

You use flip-the-tables by making use of the `ft` function. It includes tab completion and help (accessible
from `ft help`, so it should be pretty easy to figure out.

* `ft version` and `ft short-version` show the current Ruby (the second might be useful in a bash prompt)
* `ft list` shows all available Rubies and indicates which is currently in use
* `ft 1.9` switches to the first ruby version starting with '1.9' (on my machine, 1.9.2-p290)

FAQ
---

* Q: Where does the name come from? A: If you don't know, you're probably normal.
