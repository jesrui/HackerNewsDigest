#!/bin/env lua
-- althttpd.c: ProcessOneRequest()
--       If the name of the CGI script begins with 'nph-' then we are
--       dealing with a 'non-parsed headers' CGI script.  Just exec()
--       it directly and let it handle all its own header generation.
--       /* NOTE: No log entry written for nph- scripts */


local cosmo     = require 'cosmo'
local templates = require 'templates'
local sqlite3   = require 'sqlite3'
local apr       = require 'apr'

assert(cosmo)
assert(templates)
assert(sqlite3)
assert(apr)

-- TODO if the file does not exist, fail instead of creating a new database
--local c = sqlite3.open('hn-stories.sqlite')
local c = sqlite3.open('hn-all-stories+comments.sqlite')
--local c = sqlite3.open('hn-all-stories+test_comments.sqlite')
assert(c)

-- TODO end each response line w/ \r\n (esacpe codes are not interpreted between
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
    return apr.time_now()
end

local function stoptimer(t)
    return apr.time_now() - t
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

local function show_stories(params)
    local t = starttimer()
    print(response[200])

    local since, untilt, prevdate, nextdate, datefmt = getdates(params)

--    print('show_stories')
--    dump(params, 'params')
--    dump(params, 'params')
--    dump(prevdate, 'prevdate')
--    dump(nextdate, 'nextdate')

    -- NOTE: to get timestaps as UTC, rather than local time, start the server
    -- with an empty TZ environment variable, as in
    --   TZ= ./althttpd ....
    -- This will work on POSIX systems. See http://linux.die.net/man/3/tzset
    -- http://www-01.ibm.com/support/knowledgecenter/SSLTBW_1.12.0/com.ibm.zos.r12.bpxbd00/rttzs.htm%23rttzs?lang=en
    -- For ANSI-C see:
    -- https://stackoverflow.com/questions/2271408/utc-to-time-of-the-day-in-ansi-c/2271512#2271512
    local timestamp1 = os.time(since)
    local timestamp2 = os.time(untilt)

    local dates = {
        since = os.date(datefmt, timestamp1),
        untilt = os.date(datefmt, timestamp2),
        prevdateURL = makeurl('stories', prevdate),
        nextdateURL = makeurl('stories', nextdate),
    }
    local html = cosmo.fill(templates.stories_head, dates)
    print(html)
    html = cosmo.fill(templates.stories_body_top, dates)
    print(html)

    local q = 'select objectID, created_at_i, author, title, num_comments,'
        ..' points, url'
        ..' from stories'
        ..' where created_at_i between '..timestamp1..' and '..timestamp2
        ..' order by created_at_i'


    -- FIXME lsqlite.so hangs sometimes here?
    -- TODO check errors from prepare()
    -- FIXME althttpd only returns ~ 20 MB of data (results till ~ 2013-10-22
    -- when the query is for the whole 2013?)
    local nrows = 0
    for story in c:prepare(q):rows() do
        nrows = nrows + 1
        story.created_at = os.date('!%F %T', story.created_at_i)
        story.tr_class = nrows % 2 == 0 and 'light' or 'dark'
        story.commentsURL = makeurl('comments', story)
        if not story.url or #story.url == 0 then
            story.url = 'https://news.ycombinator.com/item?id='..story.objectID
        end
--        dump(story, 'story')
        html = cosmo.fill(templates.stories_body_listing, story)
        print(html)
    end

    html = cosmo.fill(templates.stories_body_bottom,
        {num_stories = nrows, elapsed = string.format('%.3f', stoptimer(t))})
    print(html)
end

local function show_comments(params)
    local t = starttimer()

    print(response[200])

--    print('show_comments')

    local root_id = tonumber(params.objectID)
    if not root_id then
        print('no objectID specified')
        return
    end

    local q = 'select objectID, title, url, author, points, story_text,'
        ..' num_comments, created_at_i'
        ..' from stories where objectID = '..root_id

    local story
    for row in c:prepare(q):rows() do
        -- TODO
        story = row
        if not story.url or #story.url == 0 then
            story.url = 'https://news.ycombinator.com/item?id='..story.objectID
        end
        story.url_host = string.gsub(story.url, '^https?://', '')
        story.url_host = string.gsub(story.url_host, '/.*$', '')
        story.created_at = os.date('!%F %T', story.created_at_i)
--        dump(story, 'story '..row.objectID)
    end

    local html = cosmo.fill(templates.comments_head, story)
    print(html)
    html = cosmo.fill(templates.comments_body_top, story)
    print(html)

    q = 'select objectID, parent_id, created_at_i, author, comment_text, points'
        ..' from comments where story_id = '..root_id
        ..' order by created_at_i desc'

    local comments = {} -- comments keyed by parent_id
    local flat = {}     -- comments keyed by objectID
    for row in c:prepare(q):rows() do
        local children = comments[row.parent_id] or {}
        children[#children+1] = row
        comments[row.parent_id] = children
        flat[row.objectID] = row
    end

    -- TODO sort children by date or points

    local yield_thread_r
    yield_thread_r = function(parent_id, lvl)
        local comment = flat[parent_id]
        if comment then
            comment.indentw = lvl*40
            comment.created_at = os.date('!%F %T', comment.created_at_i)
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
            story = story,
            yield_thread = function()
                yield_thread_r(root_id, -1)
            end,
        })
    print(html)

    html = cosmo.fill(templates.comments_body_bottom,
        {elapsed = string.format('%.3f', stoptimer(t))})
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
        local pattern, f, name = unpack(v)
        local params = match(url, pattern)
        if params then
            return f, params
        end
    end
end

-- must NOT be local to be accessible to cosmo template functions
function makeurl(action_name, params)
    for i, v in ipairs(URLs) do
        local pattern, f, name = unpack(v)
        if name == action_name then
            local url = string.gsub(pattern, '$([%w_-]+)', params)
            local n
            repeat -- remove undefined param names: '/123/$p1/$p2/' --> '/123'
                url, n = string.gsub(url, '/$[%w_-]+/?$', '')
            until n == 0
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
    return f(args)
end

