#!/bin/env lua
-- althttpd.c: ProcessOneRequest()
--       If the name of the CGI script begins with 'nph-' then we are
--       dealing with a 'non-parsed headers' CGI script.  Just exec()
--       it directly and let it handle all its own header generation.
--       /* NOTE: No log entry written for nph- scripts */

io.write('HTTP/1.0 200 OK\r\n',
    'Connection: close\r\n',
    'Content-Type: text/plain\r\n',
    '\r\n')

local sqlite3 = require 'sqlite3'
local apr = require 'apr'

assert(sqlite3)
assert(apr)

-- TODO if the file does not exist, fail instead of creating a new database
--local c = sqlite3.open('hn-stories.sqlite')
local c = sqlite3.open('hn-all-stories+comments.sqlite')
--local c = sqlite3.open('hn-all-stories+test_comments.sqlite')
assert(c)

io.write(os.date('!%F %T\r\n'))

local function starttimer()
    return apr.time_now()
end

local function stoptimer(t)
    return apr.time_now() -t
end

--do
--    local t = starttimer()
--    os.execute('sleep 2')
--    print ('elapsed', stoptimer(t), 'seconds')
--end

local cgienv = {
     'SERVER_PROTOCOL',
     'SERVER_PORT',
     'REQUEST_METHOD',
     'PATH_INFO',
     'PATH_TRANSLATED',
     'SCRIPT_NAME',
     'QUERY_STRING',
     'REMOTE_HOST',
     'REMOTE_ADDR',
     'AUTH_TYPE',
     'REMOTE_USER',
     'REMOTE_IDENT',
     'CONTENT_TYPE',
     'CONTENT_LENGTH',
     'HTTP_ACCEPT',
     'HTTP_ACCEPT_LANGUAGE',
     'HTTP_USER_AGENT',
     'HTTP_COOKIE',
}

for _, name in ipairs(cgienv) do
    cgienv[name] = os.getenv(name)
--    print(name, cgienv[name])
end

-- http://www.keplerproject.org/en/LuaGems_08 example1.lua

function dump(params)
    for k, v in pairs(params) do
        print(k, v)
    end
end

function show_history(params)
    print('show_history')
end

function show_page(params)
    print('show_page')
end

function show_diff(...)
    print('show_diff')
end

function show_stories(params)
    print('show_stories')
    -- TODO get timestaps as UTC, rather than local time
    local ok, timestamp1 = pcall(os.time, params)
    if not ok then
        timestamp1 = os.time()
    end
    local timestamp2 = timestamp1 - 60*60
    print('ok', ok, 'timestamp1', timestamp1, 'timestamp2', timestamp2)

    local q = 'select objectID, created_at_i, author, title, num_comments'
        ..' from stories'
        ..' where created_at_i between '..timestamp2..' and '..timestamp1
        ..' order by created_at_i desc'

    local t = starttimer()

    local nrows = 0
    for row in c:prepare(q):irows() do
        nrows = nrows + 1
        local author = string.format('%-10s', row[3])
        print(row[1], row[5], os.date('!%F %T', row[2]), author, row[4])
    end
    print (nrows..' rows')

    print ('elapsed '..stoptimer(t)..' seconds')
end

function show_comments(params)
    print('show_comments')

    local root_id = tonumber(params.objectID)
    if not root_id then
        print('no objectID specified')
        return
    end

    print('root_id', root_id)

    local q = 'select objectID, created_at_i, author, comment_text from comments'
        ..' where story_id = '..root_id
        ..' order by created_at_i desc'

    local t = starttimer()

    local nrows = 0
    for row in c:prepare(q):irows() do
        nrows = nrows + 1
        local author = string.format('%-10s', row[3])
        local comment = tostring(row[4])
        if #comment > 80 then
            comment = comment:sub(1, 80)..' ...'
        end
        print(row[1], os.date('!%F %T', row[2]), author, comment)
    end
    print (nrows..' rows')

    print ('elapsed '..stoptimer(t)..' seconds')
end

URLs = {
    {'/show/$page_name/$version', show_page, 'show'},
    {'/history/$page_name/$year/$month/$date', show_history, 'history'},
    {'/diff/$page_name/$version1/$version2', show_diff, 'diff'},
    {'/stories/$year/$month/$day/$hour/$min', show_stories, 'stories'},
    {'/comments/$objectID', show_comments, 'comments'},
}

-- Checks if a URL matches a pattern
function match(url, pattern)
    local params = {}
    local captures = string.gsub(pattern, '(/$[%w_-]+)', '/?([^/]*)')
    local url_parts = {string.match(url, captures)}
    local i = 1
    for name in string.gmatch(pattern, '/$([%w_-]+)') do
        params[name] = url_parts[i]
        i = i + 1
    end
    return next(params) and params
end

-- Maps the correct function for a URL
function map(url)
    for i, v in ipairs(URLs) do
        local pattern, f, name = unpack(v)
        local params = match(url, pattern)
        if params then
            return f, params
        end
    end
end

function makeurl(action_name, params)
    for i, v in ipairs(URLs) do
        local pattern, f, name = unpack(v)
        if name == action_name then
            local url = string.gsub(pattern, '$([%w_-]+)', params)
            url = '' -- cgilua.urlpath..'/'..cgilua.app_name..url
            return url
        end
    end
end

f, args = map(cgienv.PATH_INFO)

if f then
    return f(args)
end

