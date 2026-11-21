// A model's card (its README from Hugging Face) as the web shows it, as LM Studio does: GitHub's Markdown with the HTML in
// it, pictures fitted to the width. marked (MIT, markedjs/marked, apps/aicenter/marked.umd.js) turns it into HTML here.
// The card is someone else's text: no script of its own runs (CSP), links open in the browser, nothing else loads but pictures.
import QtQuick
import Quickshell
import QtWebEngine
import "../common"

WebEngineView {
    id: view
    property string text: ""
    property string repo: ""
    backgroundColor: "transparent"
    settings.localContentCanAccessRemoteUrls: true      // the pictures of a page made here (file:) are on the web
    settings.javascriptCanOpenWindows: false
    // once for the card and its repository together, whichever came first
    onTextChanged: Qt.callLater(show)
    onRepoChanged: Qt.callLater(show)
    Component.onCompleted: Qt.callLater(show)

    function css(c) { return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + c.a + ")" }
    function show() {
        // "<" as <: the card cannot close the script it is carried in
        const md = JSON.stringify(text).replace(/</g, "\\u003c"), base = JSON.stringify("https://huggingface.co/" + repo + "/resolve/main/")
        loadHtml('<!doctype html><html><head><meta charset="utf-8">'
            + '<meta http-equiv="Content-Security-Policy" content="default-src \'none\'; img-src https: data:; style-src \'unsafe-inline\'; script-src file: \'nonce-card\'">'
            + '<style>:root{color-scheme:light dark}html,body{margin:0;background:transparent;overflow-x:hidden}'
            + 'body{color:' + css(Theme.cream) + ';font:14px/1.6 "' + Theme.font + '",sans-serif;padding:0 6px 24px 0;word-wrap:break-word}'
            + 'a{color:' + css(Theme.gold) + '}img,video{max-width:100%;height:auto}'
            + 'h1,h2,h3,h4{line-height:1.25;margin:24px 0 12px}h1,h2{padding-bottom:6px;border-bottom:1px solid ' + css(Theme.line) + '}'
            + 'h1{font-size:1.7em}h2{font-size:1.4em}h3{font-size:1.15em}p,ul,ol,table,pre,blockquote{margin:0 0 14px}'
            + 'code,pre{font-family:"' + Theme.mono + '",monospace;font-size:12.5px}code{background:' + css(Theme.raised) + ';padding:1px 5px;border-radius:5px}'
            + 'pre{background:' + css(Theme.raised) + ';padding:12px 14px;border-radius:10px;overflow-x:auto}pre code{background:none;padding:0}'
            + 'table{border-collapse:collapse;display:block;max-width:100%;overflow-x:auto}th,td{border:1px solid ' + css(Theme.line) + ';padding:5px 10px}'
            + 'blockquote{border-left:3px solid ' + css(Theme.line) + ';padding-left:12px;color:' + css(Theme.dim) + '}hr{border:0;border-top:1px solid ' + css(Theme.line) + '}'
            + '::-webkit-scrollbar{width:6px;height:6px}::-webkit-scrollbar-button{display:none}::-webkit-scrollbar-track{background:transparent}'
            + '::-webkit-scrollbar-thumb{background:' + css(Theme.faint) + ';border-radius:3px}'
            + '</style><script src="marked.umd.js"></script></head><body><div id="card"></div><script nonce="card">'
            + 'const base=' + base + ',abs=u=>/^([a-z]+:|#|\\/\\/)/i.test(u||"")?u:u.startsWith("/")?"https://huggingface.co"+u:new URL(u,base).href;'
            + 'marked.use({gfm:true,walkTokens:t=>{if((t.type==="image"||t.type==="link")&&t.href)t.href=abs(t.href)}});'
            + 'card.innerHTML=marked.parse(' + md + ');'
            + 'for(const e of card.querySelectorAll("img[src]"))e.src=abs(e.getAttribute("src"));'
            + 'for(const e of card.querySelectorAll("a[href]"))e.href=abs(e.getAttribute("href"));'
            + '</script></body></html>', Qt.resolvedUrl("card.html"))
    }
    // a link goes to the browser; the card itself stays
    onNavigationRequested: r => { if (r.navigationType === WebEngineNavigationRequest.LinkClickedNavigation) { Quickshell.execDetached(["latte-open", String(r.url)]); r.reject() } }
    onNewWindowRequested: r => Quickshell.execDetached(["latte-open", String(r.requestedUrl)])
}
