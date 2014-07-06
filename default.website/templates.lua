return {
    comments_head = [==[
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width"/>
<title>$title | Hacker News Digest</title>
</head>
]==],
    comments_body_top = [==[
<body>
    <center>
        <table border=0 cellpadding=0 cellspacing=0 width="85%" bgcolor=#f6f6ef>
            <!-- BEGIN STORY AND COMMENTS -->
            <tr>
                <td>
                    <!-- BEGIN STORY -->
                    <table border=0>
                        <tr>
                            <td>
                            </td>
                            <td class="title"><a href="$url">$title</a><span class="comhead"> ($url_host)</span>
                            </td>
                        </tr>
                        <tr>
                            <td colspan=1></td>
                            <td class="subtext"><span id=score_xxxx>$points points</span>
                                by <a href="https://news.ycombinator.com/user?id=$author">$author</a> | $created_at |
                                <a href="https://news.ycombinator.com/item?id=$objectID">comments</a>
                            </td>
                        </tr>
                        <tr style="height:2px">
                        </tr>
                        <tr>
                            <td></td>
                            <td>$story_text</td>
                        </tr>
                    </table>
                    <br>
                    <br>

                    <!-- BEGIN COMMENTS -->
                    <table border=0>
]==],
    comments_body_thread = [==[
        $yield_thread[[
                       <tr>
                            <!-- BEGIN COMMENT -->
                            <td>
                                <table border=0>
                                    <tr>
                                        <td>
                                            <img src="s.gif" height=1 width=$indentw>
                                        </td>
                                        <td class="default">
                                            <div style="margin-top:2px; margin-bottom:-10px; ">
                                                <span class="comhead">
                                                    <a href="https://news.ycombinator.com/user?id=$author">$author</a>
                                                    | $created_at | $points points |
                                                    <a href="https://news.ycombinator.com/item?id=$objectID">link</a>
                                                </span>
                                            </div>
                                            <br>
                                            <span class="comment"><font color=#000000>$comment_text</font></span>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>]]
]==],
    comments_body_bottom = [==[
                    </table>
                    <br>
                    <br>
                </td>
            </tr>
         </table>
    </center>

<div class="page_footer_text">Page generated in $elapsed seconds </div>

</body>
</html>
]==],

    stories_head = [==[
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width"/>
<title>Hacker News Digest - Stories from $since</title>
<link rel="stylesheet" href="/css/gitweb.css"/>
</head>
]==],
    stories_body_top = [==[
<body>

<div class="page_header">
<a title="git homepage" href="http://git-scm.com/"><img class="logo" height="27" src="/git-logo.png" alt="git" width="72" /></a><a href="/w">repo.or.cz</a> / <a href="/w/sqlite.git">sqlite.git</a> / tree
</div>

<div class="page_nav">
<a href="$prevdateURL">previous</a> | <a href="$nextdateURL">next</a> | <a href="/git-browser/by-commit.html?r=sqlite.git">graphiclog</a> | <a href="/w/sqlite.git/commit/HEAD">commit</a> | <a href="/w/sqlite.git/commitdiff/HEAD">commitdiff</a> | tree | <a href="/w/sqlite.git/refs">refs</a> | <a href="/editproj.cgi?name=sqlite.git">edit</a> | <a href="/regproj.cgi?fork=sqlite.git">fork</a><br/>
snapshot (<a href="/w/sqlite.git/snapshot/HEAD.tar.gz">tar.gz</a> <a href="/w/sqlite.git/snapshot/HEAD.zip">zip</a>)<br/>
</div>

<div class="header">
<span class="title">Hacker News stories from $since ------------- $untilt</span>
</div>
<div class="page_body">
<table class="tree">
]==],
    stories_body_listing = [==[
<tr class="$tr_class">
<td class="mode">$created_at</td>
<td class="size link"><a href="$commentsURL">$num_comments</a></td>
<td class="size">$points</td>
<td class="mode">$author</td>
<td class="link"><a href="$url">$title</a></td>
</tr>
]==],
    stories_body_bottom = [==[
</table>
</div>
<div class="page_footer">
<div class="page_footer_text">$num_stories stories found in $elapsed seconds</div>
<a class="rss_logo" title="log RSS feed" href="/w/sqlite.git/rss">RSS</a>
<a class="rss_logo" title="log Atom feed" href="/w/sqlite.git/atom">Atom</a>
</div>

</body>
</html>
]==],
}
