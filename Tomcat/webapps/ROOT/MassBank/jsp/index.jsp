<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="utf-8" %>
<%
/*******************************************************************************
 *
 * Copyright (C) 2009 JST-BIRD MassBank
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 *******************************************************************************
 *
 * トップページ表示用モジュール
 *
 * ver 2.0.6 2010.01.27
 *
 ******************************************************************************/
%>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.net.URL" %>
<%@ page import="java.net.URLConnection" %>
<%@ page import="java.io.BufferedReader" %>
<%@ page import="java.io.InputStreamReader" %>
<%!
	/** ニュース表示数 */
	private final int DISP_NEWS_NUM = 3;
	
	/** イベント表示数 */
	private final int DISP_EVENT_NUM = 3;
%>
<%
	//-------------------------------------
	// リクエストパラメータ取得
	//-------------------------------------
	String reqLang = (request.getParameter("lang") != null) ? request.getParameter("lang") : "";
	
	
	//-------------------------------------
	// ブラウザ優先言語取得
	//-------------------------------------
	String browserLang = (request.getHeader("accept-language") != null) ? request.getHeader("accept-language") : "";
	
	
	//-------------------------------------
	// 表示HTML判別フラグ設定
	//-------------------------------------
	boolean isJpTop = true;
	if ( reqLang.equals("") ) {
		// リクエストパラメータがない場合はブラウザ優先言語で判別
		if ( browserLang.startsWith("ja") || browserLang.equals("") ) {
			isJpTop = true;
		}
		else {
			isJpTop = false;
		}
	}
	else if ( reqLang.equals("ja") ) {
		isJpTop = true;
	}
	else {
		isJpTop = false;
	}
	
	
	//-------------------------------------
	// 表示用の外部情報読み込み
	//-------------------------------------
	ArrayList<String> readHtmlList = new ArrayList<String>() {{add("/news.html"); add("/event.html");}};
	ArrayList<String> newsList = new ArrayList<String>(DISP_NEWS_NUM);
	ArrayList<String> eventList = new ArrayList<String>(DISP_EVENT_NUM);
	BufferedReader br = null;
	final String reqUrl = request.getRequestURL().toString();
	String langStr = "ja";
	if ( !isJpTop ) {
		langStr = "en";
	}
	for (String readHtml : readHtmlList) {
		try {
			URL url = new URL( reqUrl.substring(0, reqUrl.indexOf("jsp")) + langStr + readHtml );
			URLConnection con = url.openConnection();
			br = new BufferedReader( new InputStreamReader(con.getInputStream(), "UTF-8") );
			String line;
			String newLine = "";
			boolean readFlag = false;
			int eventDetail = 0;
			while ((line = br.readLine()) != null) {
				//-------------------------------------
				// ニュース読み込み
				//-------------------------------------
				if ( readHtml.equals("/news.html") ) {
					if ( !readFlag && line.indexOf("<h2>") != -1 ) {
						readFlag = true;
					}
					if ( readFlag ) {
						if ( line.indexOf("<em>") != -1 ) {
							// パスを修正後に表示用リストに追加
							newLine = line.replaceAll("\"./", "\"./" + langStr + "/");
							newLine = newLine.replaceAll("\"../", "\"./");
							newsList.add(newLine);
						}
						if ( newsList.size() == DISP_NEWS_NUM ) {
							break;
						}
					}
				}
				//-------------------------------------
				// イベント読み込み
				//-------------------------------------
				else if ( readHtml.equals("/event.html") ) {
					if ( !readFlag && line.indexOf("<h2>") != -1 ) {
						readFlag = true;
					}
					if ( readFlag ) {
						if ( line.indexOf("<a ") != -1 ) {
							newLine = line.replaceAll("\"../", "\"./");
							newLine = newLine.substring(0, newLine.indexOf("</a>")+4);
							eventDetail += 1;
						}
						else if (eventDetail == 1) {
							newLine += line.substring(line.indexOf("&nbsp;:"), line.indexOf("</span>"));
							newLine += "<br />";
							eventList.add(newLine);
							eventDetail = 0;
						}
						if ( eventList.size() == DISP_EVENT_NUM ) {
							break;
						}
					}
				}
			}
		} catch (Exception e) {
			throw e;
		} finally {
			if ( br != null ) {
				br.close();
			}
		}
	}
	
	//-------------------------------------
	// HTML出力
	//-------------------------------------
%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%
	if ( isJpTop ) {
%>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta http-equiv="Content-Script-Type" content="text/javascript" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta name="author" content="MassBank.jp" />
<meta name="description" content="MassBank は日本質量分析学会の公式データベースです。MassBank は JST-BIRD プロジェクトとして開発しています。マススペクトルを測定した研究者がインターネットで公開する分散型データベースです。" />
<meta name="keywords" content="MassBank, massbank, マスバンク, データベース, マススペクトル, resolution, spectral, database, 慶應義塾大学, 先端生命, 研究所" />
<meta name="revisit_after" content="10 days">
<link rel="stylesheet" href="./css/import.css" type="text/css" media="all" />
<title>MassBank | High Resolution Mass Spectral Database</title>
</head>

<body id="home">

<!--ここから▼ヘッダー-->
<div id="header"><h1 class="hide_text"><a href="./index.html?lang=ja" name="pagetop" id="pagetop">MassBank | High Resolution Mass Spectral Database</a></h1></div>
<!--ここまで▲ヘッダー-->


<!--ここから▼コンテンツ-->
<div id="wrap" class="clr">

<div id="content" class="clr">

<!--ここから▼右カラムメインコンテンツ-->
<div id="main" class="fr clr">

<!--ここから▼JS OFF対応-->
<noscript>
<p id="js_use" class="clr">
<em class="e16">MassBankではJavascriptを使用しています。</em><br />
&nbsp;&nbsp;MassBank では Javascript を使用しています。 Javascript が Off になっていると正常にご利用いただけません。お手数ですが Javascript を使用可能にした後、再度ページを読み込んでください。
</p>
</noscript>
<!--ここまで▲JS OFF対応-->

<!--ここから▼ニュース-->
<h2 id="h_news" class="hide_text">ニュース</h2>
<p id="headline">
<%
	//-------------------------------------
	// ニュース表示
	//-------------------------------------
	for (String outStr : newsList) {
		out.print(outStr + System.getProperty("line.separator"));
	}
%>
</p>
<div id="home_news" class="text_right separate"><a href="./ja/news.html" class="bullet_link">過去のニュース</a></div>
<!--ここまで▲ニュース-->

<!--ここから▼データベースサービス　ショートカットボタン一覧-->
<h2 id="h_home_massdb" class="hide_text">データベースサービス</h2>
<div class="massdb_bg clr">
<ul id="line1" class="hide_text">
<li id="home_btn1"><a href="./SearchPage.html" title="Spectrum Search">Spectrum Search</a></li>
<li id="home_btn2"><a href="./QuickSearch.html" title="Quick Search">Quick Search</a></li>
<li id="home_btn3"><a href="./PeakSearch.html" title="Peak Search">Peak Search</a></li>
<li id="home_btn4"><a href="./StructureSearch.html" title="Substructure Search">Substructure Search</a></li>
<li id="home_btn5"><a href="./PeakSearchAdv.html" title="Peak Search Advanced">Peak Search Advanced</a></li>
</ul>
<ul id="line2" class="hide_text">
<li id="home_btn6"><a href="./PackageView.html" title="Spectral Browser">Spectral Browser</a></li>
<li id="home_btn7"><a href="./BatchSearch.html" title="Batch Service">Batch Service</a></li>
<li id="home_btn8"><a href="./BrowsePage.html" title="Browse Page">Browse Page</a></li>
<li id="home_btn9"><a href="./RecordIndex.html" title="Record Index">Record Index</a></li>
</ul>
</div><!--div class="massdb_bg"-->
<p class="p_dbsammary separate">
MassBank は、<a href="http://www.mssj.jp/index-jp.html" target="_blank">日本質量分析学会</a> の公式データベースです。
</p>
<p />
<!--ここまで▲データベースサービス　ショートカットボタン一覧-->

<!--ここから▼イベント-->
<h2 id="h_event" class="hide_text">イベント</h2>
<p id="headline">
<%
	//-------------------------------------
	// イベント表示
	//-------------------------------------
	for (String outStr : eventList) {
		out.print(outStr + System.getProperty("line.separator"));
	}
%>
</p>
<div id="home_event" class="text_right"><a href="./ja/event.html" class="bullet_link">関連イベント一覧</a></div>
<!--ここまで▲イベント-->

</div><!--div id="main" class="fr clr"-->
<!--ここまで▲右カラムメインコンテンツ-->


<!--ここから▼左カラムナビゲーション-->
<div id="navi" class="fl clr">
<ul id="navi_global" class="hide_text clr">
<li id="navi_g01" ><a href="./ja/database.html" title="データベースサービス">データベースサービス</a></li>
<li id="navi_g02" ><a href="./ja/published.html" title="公開データ">公開データ</a></li>
<li id="navi_g03" ><a href="./ja/document.html" title="ドキュメント">ドキュメント</a></li>
<li id="navi_g04" ><a href="./ja/download.html" title="ダウンロード">ダウンロード</a></li>
<li id="navi_g05" ><a href="./ja/manual.html" title="マニュアル">マニュアル</a></li>
<li id="navi_g06" ><a href="./ja/about.html" title="MassBankについて">MassBankについて</a></li>
<li id="navi_g07" ><a href="./ja/contact.html" title="お問い合わせ">お問い合わせ</a></li>
<li id="navi_g08" ><a href="./ja/group.html" title="研究協力グループ">研究協力グループ</a></li>
</ul>
<!--ここから▼左カラム機能ナビ-->
<ul id="navi_function" class="hide_text clr">
<li id="navi_f01" ><a href="./ja/sitemap.html" title="サイトマップ">サイトマップ</a></li>
<li id="navi_f02" ><a href="./ja/regulation.html" title="利用規定">利用規定</a></li>
<li id="navi_f03" ><a href="./ja/copyright.html" title="著作権・免責事項">著作権・免責事項</a></li>
<li id="navi_f04" ><a href="./index.html?lang=en" title="English Site">English Site</a></li>
</ul>
<!--ここまで▲左カラム機能ナビ-->
</div>
<!--ここまで▲左カラムナビゲーション-->

</div><!--div id="content"-->



<!--ここから▼フッター-->
<div id="footer" class="clr">
<iframe src="./copyrightline.html" frameborder="0" marginwidth="0" marginheight="0" scrolling="no"></iframe>
<div class="fr above"><a href="./index.html?lang=ja#pagetop" title="最上部へ" class="text_right bullet_up">最上部へ</a></div>
</div>
<!--ここまで▲フッター-->


</div><!--div id="wrap" class="clr"-->
<!--ここまで▲コンテンツ-->

</body>
</html>

<%
	}
	else {
%>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta http-equiv="Content-Script-Type" content="text/javascript" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta name="author" content="MassBank.jp" />
<meta name="description" content="The Mass Spectorometry Society of Japan officially supports MassBank. MassBank is supported by JST-BIRD project. MassBank is a distributed database on the internet in order to open a spectrum to the public by a researcher who measured it." />
<meta name="keywords" content="MassBank, massbank, resolution, mass, spectral, database, Keio" />
<meta name="revisit_after" content="10 days">
<link rel="stylesheet" href="./css/import.css" type="text/css" media="all" />
<title>MassBank | High Resolution Mass Spectral Database</title>
</head>

<body id="home">

<!--st▼header-->
<div id="header"><h1 class="h1_en hide_text"><a href="./index.html?lang=en" name="pagetop" id="pagetop">MassBank | High Resolution Mass Spectral Database</a></h1></div>
<!--ed▲header-->


<!--st▼contents-->
<div id="wrap" class="clr">

<div id="content" class="clr">

<!--st▼right column main-->
<div id="main" class="fr clr">

<!--st▼JS OFF support-->
<noscript>
<p id="js_use" class="clr">
<em class="e16">Javascript is used in this site</em><br />
&nbsp;&nbsp;Javascript is used in this site. If Javascript cannot be used, it is not correctly displayed. Please enable the use of Javascript. And reload.
</p>
</noscript>
<!--ed▲JS OFF support-->

<!--st▼news-->
<h2 id="h_news_en" class="hide_text">News</h2>
<p id="headline">
<%
	//-------------------------------------
	// show news
	//-------------------------------------
	for (String outStr : newsList) {
		out.print(outStr + System.getProperty("line.separator"));
	}
%>
</p>
<div id="home_news" class="text_right separate"><a href="./en/news.html" class="bullet_link">All news</a></div>
<!--ed▲news-->

<!--st▼mass spectrum database shortcut button list-->
<h2 id="h_home_massdb_en" class="hide_text">Database Service</h2>
<div class="massdb_bg clr">
<ul id="line1" class="hide_text">
<li id="home_btn1"><a href="./SearchPage.html" title="Spectrum Search">Spectrum Search</a></li>
<li id="home_btn2"><a href="./QuickSearch.html" title="Quick Search">Quick Search</a></li>
<li id="home_btn3"><a href="./PeakSearch.html" title="Peak Search">Peak Search</a></li>
<li id="home_btn4"><a href="./StructureSearch.html" title="Substructure Search">Substructure Search</a></li>
<li id="home_btn5"><a href="./PeakSearchAdv.html" title="Peak Search Advanced">Peak Search Advanced</a></li>
</ul>
<ul id="line2" class="hide_text">
<li id="home_btn6"><a href="./PackageView.html" title="Spectral Browser">Spectral Browser</a></li>
<li id="home_btn7"><a href="./BatchSearch.html" title="Batch Service">Batch Service</a></li>
<li id="home_btn8"><a href="./BrowsePage.html" title="Browse Page">Browse Page</a></li>
<li id="home_btn9"><a href="./RecordIndex.html" title="Record Index">Record Index</a></li>
</ul>
</div><!--div class="massdb_bg"-->
<p class="p_dbsammary separate">
<a href="http://www.mssj.jp/index.html" target="_blank">The Mass Spectorometry Society of Japan</a> officially supports MassBank.
</p>
<p />
<!--ed▲mass spectrum database shortcut button list-->

<!--st▼event-->
<h2 id="h_event_en" class="hide_text">Event</h2>
<p id="headline">
<%
	//-------------------------------------
	// show event
	//-------------------------------------
	for (String outStr : eventList) {
		out.print(outStr + System.getProperty("line.separator"));
	}
%>
</p>
<div id="home_event" class="text_right"><a href="./en/event.html" class="bullet_link">All related event</a></div>
<!--ed▲event-->

</div><!--div id="main" class="fr clr"-->
<!--ed▲right column main-->


<!--st▼left column navi-->
<div id="navi" class="fl clr">
<ul id="navi_global_en" class="hide_text clr">
<li id="navi_g01_en" ><a href="./en/database.html" title="Database Service">Database Service</a></li>
<li id="navi_g02_en" ><a href="./en/published.html" title="Statistics">Statistics </a></li>
<li id="navi_g03_en" ><a href="./en/document.html" title="Document">Document</a></li>
<li id="navi_g04_en" ><a href="./en/download.html" title="Download">Download</a></li>
<li id="navi_g05_en" ><a href="./en/manual.html" title="Manual">Manual</a></li>
<li id="navi_g06_en" ><a href="./en/about.html" title="About MassBank">About MassBank</a></li>
<li id="navi_g07_en" ><a href="./en/contact.html" title="Contact">Contact</a></li>
<li id="navi_g08_en" ><a href="./en/group.html" title="Consortium Members">Consortium Members</a></li>
</ul>
<!--st▼left column function navi-->
<ul id="navi_function_en" class="hide_text clr">
<li id="navi_f01_en" ><a href="./en/sitemap.html" title="Site Map">Site Map</a></li>
<li id="navi_f02_en" ><a href="./en/regulation.html" title="Use Restrictions">Use Restrictions</a></li>
<li id="navi_f03_en" ><a href="./en/copyright.html" title="Copyright">Copyright</a></li>
<li id="navi_f04_en" ><a href="./index.html?lang=ja" title="Japanese Site">Japanese Site</a></li>
</ul>
<!--ed▲left column function navi-->
</div>
<!--ed▲left column navi-->

</div><!--div id="content"-->



<!--st▼footer-->
<div id="footer" class="clr">
<iframe src="./copyrightline.html" frameborder="0" marginwidth="0" marginheight="0" scrolling="no"></iframe>
<div class="fr above"><a href="./index.html?lang=en#pagetop" title="To top" class="text_right bullet_up">To top</a></div>
</div>
<!--ed▲footer-->


</div><!--div id="wrap" class="clr"-->
<!--ed▲contents-->

</body>
</html>

<%
	}
%>

