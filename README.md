flip-the-tables (╯°□°）╯︵ ┻━┻
============================

flip-the-tables is yet another ruby version switcher, in the vein of [RVM](http://beginrescueend.com/) and
[rbenv](https://github.com/sstephenson/rbenv). The philosophy of flip-the-tables is that choosing ruby
versions should be a trivial task best solved in the simplest manner possible. It was partially inspired by
[this blog post](http://chris.mowforth.com/si-because-rvm-and-rbenv-are-overkill), although I am using a very
different approach.

flip-the-tables works with Bash and Zsh.

Design goals
------------

* I want to switch ruby versions with a shell command or possibly by cd-ing to a directory with a special file
* I want the ruby version to stay the same in my shell until I change it, and I want to change my version
  without affecting other shells
* I don't want to override any common shell functions or replace `ruby`, `irb`, `gem`, etc with shell shims
* I don't want to introduce slow operations into my workflow
* I want as few lines of shell code as possible, because shell scripting sucks

Features
--------

* Hit all design goals

How it works
------------

You don't have to understand how flip-the-tables works, but it's quite simple and knowing what it's doing may
make it easier to use.

Fundamentally, flip-the-tables just manipulates your `$PATH`. Ruby versions are just the names of
subdirectories of `$RUBIES`. When you type `ft 1.9`, flip-the-tables does the following:

* Check to make sure that there is some entry of the form `$RUBIES/<ruby-version>/bin` in your `$PATH`
* Check to see that `1.9` is an unambiguous prefix of a directory in `$RUBIES`
* In your path, `$RUBIES/<ruby-version>/bin` is replaced with `$RUBIES/1.9<blah>/bin`

Project-specific ruby versions work in the following manner:

* When you move to a new directoy (this is checked by a hook in `$PROMPT_COMMAND`), we check for a file
  called `.ft_ruby_<version>` where version is just like a string you might give to `ft` (e.g. "1.9").
* If such a file exists, switch rubies in the same manner as above.
* Recursively repeat this process for all ancestor directories until a file is found or we reach `/`.

That's all, folks!

Installation
------------

First, make sure you have GNU readlink installed. If you're running some flavor of Linux, you should be good;
if you're running Mac OS, you should install greadlink (e.g. `brew install coreutils` or `port install
coreutils`). The BSD readlink will not work with flip-the-tables.

Decide where to keep your rubies (I'll assume `~/.rubies`). This will be `$RUBIES`. In that directory, install
your ruby versions using Sam Stephenson's excellent [ruby-build](https://github.com/sstephenson/ruby-build).
They should each be in folders with their names; e.g. `1.9.2-p290/`.

Next, download `ft.sh` from this repo and put it somewhere on your machine. Add the following lines to your
shell rc file of choice (e.g. `.bash_profile`, `.bashrc`, or `.zshrc`):

    export RUBIES=$HOME/.rubies
    export FT_DEFAULT_RUBY='1.9.2-p290'
    source ~/path/to/ft.sh

Notice that in the first line you should substitute your chosen location, and in the second you should
substitute your desired default Ruby.

In addition, if you're using zsh you'll need to add a call to `_ft_prompt_command` to your `precmd`. It should
look like this:

    function precmd() {
      # Possibly other stuff here -- make sure you don't blow away an existing precmd
      _ft_prompt_command
    }

Open up a new shell or source your rc files and you're all set.

Usage
-----

You use flip-the-tables by making use of the `ft` function. It includes tab completion and help (accessible
from `ft help`), so it should be pretty easy to figure out.

* `ft version` and `ft short-version` show the current Ruby (the second might be useful in a command prompt)
* `ft list` shows all available Rubies and indicates which is currently in use
* `ft 1.9` switches to the first ruby version starting with '1.9' (on my machine, 1.9.2-p290)

Project-specific rubies
-----------------------

You can drop a file named `.ft_ruby_<version>` (example: `.ft_ruby_1.9`) in your project root. If you cd to
any directory at or below this, `ft` will automatically switch that the indicated Ruby. (Note that this does
partial matching on the version, just like the normal `ft` command).

When you switch out of such a directory tree, flip-the-tables automatically switches back to your default ruby
(`$FT_DEFAULT_RUBY`).

Notes
-----

* This won't play nicely with RVM or rbenv.
* ft will complain if you have `$GEM_HOME` or `$GEM_PATH` set, because it's preferable to have separate gems
  for each Ruby.

FAQ
---

* Q: Where does the name come from? A: If you don't know, you're probably normal.
