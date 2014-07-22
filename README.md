# Hacker News Digest

Hacker News Digest is a little web application to browse the SQLite database of
[Hacker News](https://news.ycombinator.com/) stories and comments created with
[hn2sqlite](https://github.com/jesrui/hn2sqlite)

## Requirements

* sqlite3 and a web server, obviously
* Lua 5.2
* [lsqlitelib](https://github.com/jesrui/lsqlite3lib/tree/lua52) Lua bindings
for sqlite (lua52 branch)

## Setup with [althttpd](https://github.com/jesrui/alhttpd)

* Compile lsqlitelib and copy `sqlite.so` to
`HackerNewsDigest/default.website`. Alternatively, set `LUA_CPATH` to an
appropiate value so that Lua can find the module (e.g `export
LUA_CPATH="$HOME/lsqlite3lib/?.so;./?.so"`)

* move the database created with
[hn2sqlite](https://github.com/jesrui/hn2sqlite) to 
`HackerNewsDigest/default.website`. The app expects the database to be called
`hn-all-stories+comments.sqlite`; change as appropiate.

* Start the web server:

        TZ= ~/althttpd/althttpd -logfile logfile -root $HOME/althttpd/HackerNewsDigest/ -port 8080

The `TZ` enviroment variable is set to an empty string to get timestaps as
UTC, rather than local time.

## Browsing stories and comments

The application serves just two URLs: one for stories listed by date and one
for the comments of a specific story.

* The story URL looks like
`http://localhost:8080/nph-hn.lua/stories/$year/$month/$day/$hour/$min?author=$author`.
The `?author=...` part and all date and time fields are optional, so that for example
<http://localhost:8080/nph-hn.lua/stories/2013/12/31> lists all the stories for
31 Dec 2013.

* The comments URL looks like
`http://localhost:8080/nph-hn.lua/comments/$objectID` but I don't think this is
too important as you would access it normally from the stories page.

## Acknowdledgements

* This service draws much code and ideas from
[MVC Web Development with Kepler](http://www.keplerproject.org/en/LuaGems_08).
* The javascript code for collapsing/expanding threaded comments is taken from
<https://github.com/niyazpk/Collapsible-comments-for-Hacker-News>
* The CSS code of the story listing page is original from
[repo.or.cz](http://repo.or.cz/gitweb.css)

## License

`HackerNewsDigest` is distributed under the
[MIT license](http://opensource.org/licenses/MIT).

