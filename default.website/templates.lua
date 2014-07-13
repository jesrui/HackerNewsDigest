return {
    comments_head = [==[
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width"/>
<link rel="shortcut icon" href="/favicon.ico">
<title>$title | Hacker News Digest</title>
<script type="text/javascript" src="/js/jquery-1.7.2.min.js"></script>
<script type="text/javascript">
$(document).ready(function(){
    if (typeof jQuery !== 'undefined') {
        if (!$('body').hasClass('collapsible-comments')) {
            $('body').addClass('collapsible-comments');
            $('.expand-handle').live('click', function () {
                current_level_width = parseInt($(this).closest('tr').find('td:eq(0) > img').attr('width'), 10);
                $(this).closest('table').closest('tr').nextAll().each(function (index, el) {
                    var elWidth = parseInt($('tbody > tr > td > img', this).attr('width'), 10);
                    if (elWidth > current_level_width) {
                        if (elWidth <= inner_level_width) {
                            inner_level_width = 1000;
                            $(this).hide()
                        }
                        if (inner_level_width == 1000 && $('.comment', this).css('display') == 'none') {
                            inner_level_width = elWidth
                        }
                    } else {
                        return false
                    }
                });
                inner_level_width = 1000;
                $(this).text('[+]').addClass('expand-handle-collapsed').removeClass('expand-handle');
                $(this).closest('td').next().nextAll().hide();
                $(this).closest('td').next().find('div').nextAll().hide();
                $(this).closest('td').next().css({
                    'margin-left': '18px',
                    'margin-top': '2px',
                    'margin-bottom': '5px'
                })
            });
            $('.expand-handle-collapsed').live('click', function () {
                current_level_width = parseInt($(this).closest('tr').find('td > img').attr('width'), 0);
                $(this).closest('table').closest('tr').nextAll().each(function (index, el) {
                    var elWidth = parseInt($('tbody > tr > td > img', this).attr('width'), 0);
                    if (elWidth > current_level_width) {
                        if (elWidth <= inner_level_width) {
                            inner_level_width = 1000;
                            $(this).show()
                        }
                        if (inner_level_width == 1000 && $('.comment', this).css('display') == 'none') {
                            inner_level_width = elWidth
                        }
                    } else {
                        return false
                    }
                });
                inner_level_width = 1000;
                $(this).text('[-]').addClass('expand-handle').removeClass('expand-handle-collapsed');
                $(this).closest('td').next().nextAll().show();
                $(this).closest('td').next().find('div').nextAll().show();
                $(this).closest('td').next().css({
                    'margin-left': '0',
                    'margin-bottom': '-10px'
                })
            })
        }
    }
    var current_level_width = 0;
    var inner_level_width = 1000
});
</script>
</head>
]==],
    comments_body_top = [==[
<body>
    <center>
        <!-- BEGIN STORY AND COMMENTS -->
        <table border=0 cellpadding=0 cellspacing=0 width="85%" bgcolor=#f6f6ef>
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
                                $num_comments <a href="https://news.ycombinator.com/item?id=$objectID">comments</a>
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
                        <!-- BEGIN COMMENT -->
                        <tr>
                            <td>
                                <table border=0>
                                    <tr>
                                        <td>
                                            <img src="/s.gif" height=1 width=$indentw>
                                        </td>
                                        <td valign=top>
                                            <span style='cursor:pointer;margin-right:10px;' class='expand-handle'>[-]
                                            </span>
                                        </td>
                                        <td class="default" valign=top>
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
<span class="title">Hacker News stories from $since</span>
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
<div class="page_footer_text">$num_stories stories found</div>
<a class="rss_logo" title="log RSS feed" href="/w/sqlite.git/rss">RSS</a>
<a class="rss_logo" title="log Atom feed" href="/w/sqlite.git/atom">Atom</a>
</div>

</body>
</html>
]==],
}
