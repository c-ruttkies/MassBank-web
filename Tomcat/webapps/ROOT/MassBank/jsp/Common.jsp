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
 * 共通JSP（静的インクルード用）
 *
 * ver 1.0.2 2010.02.05
 *
 ******************************************************************************/
%>
<%
	//-------------------------------------
	// 参照先ベースURL
	//-------------------------------------
	/* 通常は慶應サーバを参照する */
	String refBaseUrl = "http://www.massbank.jp/";
//	String refReqUrl = request.getRequestURL().toString();
//	String refBaseUrl = refReqUrl.substring( 0, (refReqUrl.indexOf("/jsp")+1) );
	
	//-------------------------------------
	// ブラウザ優先言語による言語判別
	//-------------------------------------
	String browserLang = (request.getHeader("accept-language") != null) ? request.getHeader("accept-language") : "";
	boolean isJp = false;
	if ( browserLang.startsWith("ja") || browserLang.equals("") ) {
		isJp = true;
	}
	
	//-------------------------------------
	// 各URL設定
	//-------------------------------------
	String SAMPLE_URL = refBaseUrl + "sample/sample.txt";
	String SAMPLE_ZIP_URL = refBaseUrl + "sample/sample.zip";
	String MANUAL_URL = refBaseUrl + "manuals/UserManual_ja.pdf";
	if ( !isJp ) {
		MANUAL_URL = refBaseUrl + "manuals/UserManual_en.pdf";
	}
%>
