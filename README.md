Pivotal Tracker to Todo.txt integration
=======================================

Imports stories from [Pivotal Tracker](http://pivotaltracker.com) as [Todo.txt](http://todotxt.com) lines.

Configuration
-------------

    cp config.example.rb config.rb

And change the values of `config.rb` to match your setup.

Usage
-----

    ./pt2todo

Limitations
-----------

Currently pt2todo is just a one-way import from Pivotal Tracker to Todo.txt, as in it will not create 
stories from your Todo.txt lines. However, it is meant to be run repeatedly (with `cron` or some other
scheduler), so it will not create duplicate Todos, keeping Todo.txt up to date with Pivotal Tracker.
