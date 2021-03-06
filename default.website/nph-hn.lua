#!/bin/env lua
-- althttpd.c: ProcessOneRequest()
--       If the name of the CGI script begins with 'nph-' then we are
--       dealing with a 'non-parsed headers' CGI script.  Just exec()
--       it directly and let it handle all its own header generation.
--       /* NOTE: No log entry written for nph- scripts */


local socket    = require 'socket'
local cosmo     = require 'cosmo'
local templates = require 'templates'
local sqlite3   = require 'sqlite3'

-- TODO if the file does not exist, fail instead of creating a new database
--local c = sqlite3.open('hn-stories.sqlite')
local c = sqlite3.open('hn-all-stories+comments.sqlite')
--local c = sqlite3.open('hn-all-stories+test_comments.sqlite')
assert(c)

-- TODO end each response line w/ \r\n (escape codes are not interpreted between
-- [==[ and ]==])
local response = {
    [200] = [==[
HTTP/1.1 200 OK
Connection: close
Content-Type: text/html; charset=utf-8
]==],
}

local response_plain = {
    [200] = [==[
HTTP/1.1 200 OK
Connection: close
Content-Type: text/plain; charset=utf-8
]==],
}

--io.write(os.date('!%F %T\r\n'))

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

local function starttimer()
    return socket.gettime()
end

local function stoptimer(t)
    return socket.gettime() -t
end

local function dump(t, str, level)
    level = level or 0
    print(string.rep("  ", level)..(str or tostring(t)))
    for k, v in pairs(t) do
        print(string.rep("  ", level+1), k, type(v), v)
    end
end

local function shallowcopy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

local function getdates(params)
    local since = shallowcopy(params)
--    dump(since)
    if not tonumber(since.year) then
        since.year = 2013
    end
    local periods = {'min', 'hour', 'day', 'month', 'year'}
    local period
    local datefmts = { min = '!%c', hour = '!%c', day = '%a %d %b %Y',
        month = '%b %Y', year = '%Y'}
    local datefmt
    for _, f in ipairs(periods) do
        if tonumber(since[f]) then
            period = f
            datefmt = datefmts[f]
            break
        end
    end
    if not tonumber(since.month) then
        since.month = 1
    end
    if not tonumber(since.day) then
        since.day = 1
    end
    if not tonumber(since.hour) then
        since.hour = 0
    end
    if not tonumber(since.min) then
        since.min = 0
    end
    local untilt = shallowcopy(since)
--    dump(untilt)
    untilt[period] = untilt[period] + 1

    -- remove unspecified parameter fields from d table
    -- NOTE: it is safe to remove entries from a table while traversing it
    -- https://stackoverflow.com/questions/6167555/how-can-i-safely-iterate-a-lua-table-while-keys-are-being-removed/6167683#6167683
    local stripdate = function(d)
        for f, _ in pairs(d) do
            if not tonumber(params[f]) then
                d[f] = nil
            end
        end
    end

    -- TODO does os.time() take leap seconds into account?
    local prevdate = os.date('*t', os.time(since)-1)
    stripdate(prevdate)
    local nextdate = os.date('*t', os.time(untilt))
    stripdate(nextdate)

    return since, untilt, prevdate, nextdate, datefmt
end

-- http://www.keplerproject.org/en/LuaGems_08 example1.lua

local function show_stories(params, query)
    local time = starttimer()

    print(response[200])

--    dump(params)

    local need_dates = query.author == nil
    local have_dates = need_dates or tonumber(params.year) ~= nil
    local since, untilt, prevdate, nextdate, datefmt
    if have_dates then
        since, untilt, prevdate, nextdate, datefmt = getdates(params)
    end

--[[
    print('show_stories', 'have_dates', have_dates)
    dump(params, 'params')
    if have_dates then
        dump(prevdate, 'prevdate')
        dump(nextdate, 'nextdate')
    end
--]]

    -- NOTE: to get timestaps as UTC, rather than local time, start the server
    -- with an empty TZ environment variable, as in
    --   TZ= ./althttpd ....
    -- This will work on POSIX systems. See http://linux.die.net/man/3/tzset
    -- http://www-01.ibm.com/support/knowledgecenter/SSLTBW_1.12.0/com.ibm.zos.r12.bpxbd00/rttzs.htm%23rttzs?lang=en
    -- For ANSI-C see:
    -- https://stackoverflow.com/questions/2271408/utc-to-time-of-the-day-in-ansi-c/2271512#2271512
    local timestamp1, timestamp2
    if have_dates then
        timestamp1 = os.time(since)
        timestamp2 = os.time(untilt)
    end

    local tparams = {
        if_dates = function()
            if have_dates then
                cosmo.yield({
                    since = os.date(datefmt, timestamp1),
                    untilt = os.date(datefmt, timestamp2),
                    prevdateURL = makeurl('stories', prevdate, query),
                    nextdateURL = makeurl('stories', nextdate, query),
                })
            end
        end,
        if_author = function()
            if query.author then
                cosmo.yield({author = query.author})
            end
        end
    }
    local html = cosmo.fill(templates.stories_head, tparams)
    print(html)
    html = cosmo.fill(templates.stories_body_top, tparams)
    print(html)

    local q = 'select objectID, created_at_i, author, title, num_comments,'
        ..' points, url'
        ..' from stories'
        ..' where 1 = 1'
    local binds = {}
    if have_dates then
        binds[':timestamp1'] = timestamp1
        binds[':timestamp2'] = timestamp2
        q = q..' and created_at_i between :timestamp1 and :timestamp2'
    end
    if query.author then
        binds[':author'] = query.author
        q = q ..' and author = :author'
    end

    q = q..' order by created_at_i'

--    print('q', q)

    -- FIXME sqlite.so hangs sometimes here?
    -- TODO check errors from prepare()
    -- FIXME althttpd only returns ~ 20 MB of data (results till ~ 2013-10-22)
    -- when the query is for the whole 2013?)
    local nrows = 0
    local p = c:prepare(q)
    p:bind(binds)
    for story in p:rows() do
        nrows = nrows + 1
        story.created_at = os.date('!%F %T', story.created_at_i)
        story.tr_class = nrows % 2 == 0 and 'light' or 'dark'
        story.comments_url = cgienv.SCRIPT_NAME..'/comments/'..story.objectID
        if not story.url or #story.url == 0 then
            story.url = 'https://news.ycombinator.com/item?id='..story.objectID
        end
        story.author_url = cgienv.SCRIPT_NAME..'/stories?author='..story.author
--        dump(story, 'story')
        html = cosmo.fill(templates.stories_body_listing, story)
        print(html)
    end

    html = cosmo.fill(templates.stories_body_bottom,
        {num_stories = nrows, elapsed = string.format('%.3f', stoptimer(time))})
    print(html)
end

local function show_comments(params)
    local time = starttimer()

    print(response[200])

--    print('show_comments')

    local root_id = tonumber(params.objectID)
    if not root_id then
        print('no objectID specified')
        return
    end

    local q = 'select objectID, title, url, author, points, story_text,'
        ..' num_comments, created_at_i'
        ..' from stories where objectID = :root_id'
    local binds = { [':root_id'] = root_id }

    local story
    local p = c:prepare(q)
    p:bind(binds)
    for row in p:rows() do
        story = row
        if not story.url or #story.url == 0 then
            story.url = 'https://news.ycombinator.com/item?id='..story.objectID
        end
        story.url_host = string.gsub(story.url, '^https?://', '')
        story.url_host = string.gsub(story.url_host, '/.*$', '')
        story.created_at = os.date('!%F %T', story.created_at_i)
        story.author_url = cgienv.SCRIPT_NAME..'/stories?author='..story.author
--        dump(story, 'story '..row.objectID)
    end

    if not story then
        print('no story found with that objectID')
        return
    end

    local html = cosmo.fill(templates.comments_head, story)
    print(html)
    html = cosmo.fill(templates.comments_body_top, story)
    print(html)

    q = 'select objectID, parent_id, created_at_i, author, comment_text, points'
        ..' from comments where story_id = :root_id'
        ..' order by created_at_i desc'
    binds = { [':root_id'] = root_id }

    local comments = {} -- comments grouped by parent_id
    local flat = {}     -- comments keyed by objectID
    local p = c:prepare(q)
    p:bind(binds)
    for row in p:rows() do
        local children = comments[row.parent_id] or {}
        children[#children+1] = row
        comments[row.parent_id] = children
        flat[row.objectID] = row
    end

    local yield_thread_r
    yield_thread_r = function(parent_id, lvl)
        local comment = flat[parent_id]
        if comment then
            comment.indentw = lvl*40
            comment.created_at = os.date('!%F %T', comment.created_at_i)
            comment.author_url = cgienv.SCRIPT_NAME..'/stories?author='..comment.author
            cosmo.yield(comment)
        end
        local children = comments[parent_id]
        if children then
            for i, comment in ipairs(children) do
                yield_thread_r(comment.objectID, lvl+1)
            end
        end
    end

    html = cosmo.fill(templates.comments_body_thread, {
            yield_thread = function()
                yield_thread_r(root_id, -1)
            end,
        })
    print(html)

    html = cosmo.fill(templates.comments_body_bottom,
        {elapsed = string.format('%.3f', stoptimer(time))})
    print(html)
end

local URLs = {
    {'/stories/$year/$month/$day/$hour/$min', show_stories, 'stories'},
    {'/comments/$objectID', show_comments, 'comments'},
}

-- Checks if a URL matches a pattern
local function match(url, pattern)
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
local function map(url)
    for i, v in ipairs(URLs) do
        local pattern, f, name = table.unpack(v)
        local params = match(url, pattern)
        if params then
            return f, params
        end
    end
end

-- URL handling functions taken from Pogramming in Lua 2nd Ed.

local function URLescape(s)
    s = string.gsub(s, '[&=+%%%c]', function (c)
            return string.format('%%%02X', string.byte(c))
        end)
    s = string.gsub(s, ' ', '+')
    return s
end

local function URLunescape(s)
    s = string.gsub(s, '+', ' ')
    s = string.gsub(s, '%%(%x%x', function (h)
            return string.char(tonumber(h, 16))
        end)
    return s
end

local function URLencode(t)
    local b = {}
    for k, v in pairs(t) do
        b[#b + 1] = URLescape(k)..'='..URLescape(v)
    end
    return table.concat(b, '&')
end

local function URLdecode(s)
    local t = {}
    for name, value in string.gmatch(s, '([^&=]+)=([^&=]+)') do
        name = URLunescape(name)
        value = URLunescape(value)
        t[name] = value
    end
    return t
end

-- must NOT be local to be accessible to cosmo template functions
function makeurl(action_name, params, query)
    for i, v in ipairs(URLs) do
        local pattern, f, name = table.unpack(v)
        if name == action_name then
            local url = string.gsub(pattern, '$([%w_-]+)', params)
            local n
            repeat -- remove undefined param names: '/123/$p1/$p2/' --> '/123'
                url, n = string.gsub(url, '/$[%w_-]+/?$', '')
            until n == 0
            if query and next(query, nil) then -- query table not empty?
                url = url..'?'..URLencode(query)
            end
            url = cgienv.SCRIPT_NAME..url
            return url
        end
    end
end

-- DEBUG ONLY: define this to be able to call the script from the command
-- line
--cgienv.PATH_INFO = '/comments/6000502'
--cgienv.PATH_INFO = 'stories/2013/12/30'

local f, args = map(cgienv.PATH_INFO)

if f then
    local query = URLdecode(cgienv.QUERY_STRING or '')
--  dump(cgienv.query, 'cgienv.query')
    return f(args, query)
end
