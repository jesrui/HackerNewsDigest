return {
    comments = [==[

<H1>$title $flat</H1>
<P>Example 6 - using Cosmo for content generation</P>
<UL>
$list_comments[[
<LI>$author $comment_text
</LI>]]
</UL>


]==],

    stories = [==[
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width"/>
<title>Hacker News Digest - Stories from $since till $untilt</title>
<link rel="stylesheet" href="/css/gitweb.css"/>
</head>

<body>

<div class="page_header">
<a title="git homepage" href="http://git-scm.com/"><img class="logo" height="27" src="/git-logo.png" alt="git" width="72" /></a><a href="/w">repo.or.cz</a> / <a href="/w/sqlite.git">sqlite.git</a> / tree
</div>

<div class="page_nav">
<a href="/w/sqlite.git">summary</a> | <a href="/w/sqlite.git/shortlog/HEAD">log</a> | <a href="/git-browser/by-commit.html?r=sqlite.git">graphiclog</a> | <a href="/w/sqlite.git/commit/HEAD">commit</a> | <a href="/w/sqlite.git/commitdiff/HEAD">commitdiff</a> | tree | <a href="/w/sqlite.git/refs">refs</a> | <a href="/editproj.cgi?name=sqlite.git">edit</a> | <a href="/regproj.cgi?fork=sqlite.git">fork</a><br/>
snapshot (<a href="/w/sqlite.git/snapshot/HEAD.tar.gz">tar.gz</a> <a href="/w/sqlite.git/snapshot/HEAD.zip">zip</a>)<br/>
</div>

<div class="header">
<span class="title"><a class="title" href="/w/sqlite.git/commit/HEAD">Add another test to verify that SQLite is using stat4 data for composite primary... </a><span class="refs"><span class="head" title="heads/master"><a href="/w/sqlite.git/shortlog/refs/heads/master">master</a></span></span><a class="cover" href="/w/sqlite.git/commit/HEAD"></a></span>
</div>

<div class="page_body">
<table class="tree">
$list_story[[
<tr class="$tr_class">
<td class="mode">$created_at</td>
<td class="size">$num_comments</td>
<td class="size">$points</td>
<td class="mode">$author</td>
<td class="link"><a href="$commentsURL">$title</a></td>
</tr>]]
</table>

</tr>
</table>
</div>

<div class="page_footer">
<div class="page_footer_text">Unofficial git mirror of the SQLite sources</div>
<a class="rss_logo" title="log RSS feed" href="/w/sqlite.git/rss">RSS</a>
<a class="rss_logo" title="log Atom feed" href="/w/sqlite.git/atom">Atom</a>
</div>

</body>
</html>
]==],
}
