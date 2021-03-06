<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="utf-8" %>
<%
/*******************************************************************************
 *
 * Copyright (C) 2010 JST-BIRD MassBank
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
 ******************************************************************************/
%>

<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.io.BufferedReader" %>
<%@ page import="java.io.File" %>
<%@ page import="java.io.FileReader" %>
<%@ page import="java.io.IOException" %>
<%@ page import="java.util.Enumeration" %>
<%@ page import="java.util.regex.Matcher" %>
<%@ page import="java.util.regex.Pattern" %>
<%@ page import="massbank.GetConfig" %>
<%@ page import="massbank.MassBankEnv" %>
<%@ page import="massbank.AccessionData" %>
<%@ page import="massbank.FileUtil" %>
<%@ page import="massbank.StructureToSvgStringGenerator" %>
<%@ page import="massbank.StructureToSvgStringGenerator.ClickablePreviewImageData" %>
<%
	// ##################################################################################################
	// get parameters
	// http://localhost/MassBank/jsp/RecordDisplay.jsp?id=XXX00001&dsn=MassBank
	//String accession	= "XXX00001";
	//String database	= "MassBank";
	String accession		= null;
	String databaseName		= null;
	
	Enumeration<String> names = request.getParameterNames();
	while ( names.hasMoreElements() ) {
		String key = (String) names.nextElement();
		String val = (String) request.getParameter( key );
		
		switch(key){
			case "id":	accession		= val; break;
			case "dsn":	databaseName	= val; break;
			default: System.out.println("Warning: Unused argument " + key + "=" + val);
		}
	}
	
	if(databaseName != null && databaseName.equals("") && accession != null && !accession.equals("")){
		databaseName	= AccessionData.getDatabaseOfAccession(accession);
		
		// redirect from URL without database parameter to URL with database parameter
		String baseUrl	= MassBankEnv.get(MassBankEnv.KEY_BASE_URL);
		String urlStub	= baseUrl + "jsp/RecordDisplay.jsp";
		String redirectUrl	= urlStub + "?id=" + accession + "&dsn=" + databaseName;
		
		response.sendRedirect(redirectUrl);
		return;
	}
	
	// ##################################################################################################
	// error handling
	if(accession != null && accession.equals(""))
		accession		= null;
	if(databaseName != null && databaseName.equals(""))
		databaseName	= null;
	
	if(accession == null){
		System.out.println("Error: Missing argument 'id'");
		String baseUrl	= MassBankEnv.get(MassBankEnv.KEY_BASE_URL);
		String urlStub	= baseUrl + "jsp/NoRecordPage.jsp";
		String error	= "Error: Missing argument 'id'";
		String redirectUrl	= urlStub + "?id=" + accession + "&dsn=" + databaseName + "&error=" + error;
		
		response.sendRedirect(redirectUrl);
		return;
	}
	if(databaseName == null){
		System.out.println("Error: Missing argument 'dsn'");
		String baseUrl	= MassBankEnv.get(MassBankEnv.KEY_BASE_URL);
		String urlStub	= baseUrl + "jsp/NoRecordPage.jsp";
		String error	= "Error: Missing argument 'dsn'";
		String redirectUrl	= urlStub + "?id=" + accession + "&dsn=" + databaseName + "&error=" + error;
		
		response.sendRedirect(redirectUrl);
		return;
	}
	if(!AccessionData.existsFile(databaseName, accession)){
		System.out.println("Error: accession '" + accession + "' in database '" + databaseName + "' does not exist.");
		String baseUrl	= MassBankEnv.get(MassBankEnv.KEY_BASE_URL);
		String urlStub	= baseUrl + "jsp/NoRecordPage.jsp";
		String error	= "Error: accession '" + accession + "' in database '" + databaseName + "' does not exist.";
		String redirectUrl	= urlStub + "?id=" + accession + "&dsn=" + databaseName + "&error=" + error;
		
		response.sendRedirect(redirectUrl);
		return;
	}
	
	// paths
	String tmpUrlFolder		= MassBankEnv.get(MassBankEnv.KEY_BASE_URL) + "temp";
	//String tmpUrlFolder		= request.getServletContext().getAttribute("ctx").toString() + "/temp";// ${ctx}
	String tmpFileFolder	= MassBankEnv.get(MassBankEnv.KEY_TOMCAT_APPTEMP_PATH);
	
	// ##################################################################################################
	// get accession data
	
	if(false){
		
	//DatabaseManager dbManager	= new DatabaseManager(databaseName);
	//AccessionData accData		= dbManager.getAccessionData(accession);
	//dbManager.closeConnection();
	
	AccessionData accData	= AccessionData.getAccessionDataFromFile(databaseName, accession);
	if(accData == null)
		return;
	
	String shortName	= accData.RECORD_TITLE.split(";")[0].trim();
	
	// ##################################################################################################
	// get clickable image data
	ClickablePreviewImageData clickablePreviewImageData	= StructureToSvgStringGenerator.createClickablePreviewImage(
			accData, tmpFileFolder, tmpUrlFolder,
			80, 200, 436
	);
	
	String svgMedium	= null;
	if(clickablePreviewImageData != null)
		svgMedium	= clickablePreviewImageData.getMediumClickableImage();
	
	// ##################################################################################################
	// compile entry information
	StringBuilder sb	= new StringBuilder();
	
	/*
All links:
----------

'LICENSE:',								'https://creativecommons.org/licenses/',
'PUBLICATION:',							'http://www.ncbi.nlm.nih.gov/pubmed/%s?dopt=Citation',
'COMMENT: \[MSn\]',						'Dispatcher.jsp?type=disp&id=%s&site=%s',
'COMMENT: \[Merging\]',					'Dispatcher.jsp?type=disp&id=%s&site=%s',
'COMMENT: \[Merged\]',					'Dispatcher.jsp?type=disp&id=%s&site=%s',
'COMMENT: \[Mass spectrometry\]',		'',
'COMMENT: \[Chromatography\]',			'',
'COMMENT: \[Profile\]',					'../DB/profile/%s/%s',
'COMMENT: \[Mixture\]',					'Dispatcher.jsp?type=disp&id=%s&site=%s',
'CH\$FORMULA:',							'http://www.chemspider.com/Search.aspx?q=%s',
'CH\$LINK: CAS',						'https://www.google.com/search?q=&quot;%s&quot;',
'CH\$LINK: CAYMAN',						'http://www.caymanchem.com/app/template/Product.vm/catalog/%s',
'CH\$LINK: CHEBI',						'http://www.ebi.ac.uk/chebi/searchId.do?chebiId=CHEBI:%s',
'CH\$LINK: CHEMPDB',					'http://www.ebi.ac.uk/msd-srv/chempdb/cgi-bin/cgi.pl?FUNCTION=getByCode&amp;CODE=%s',
'CH\$LINK: CHEMSPIDER',					'http://www.chemspider.com/%s',
'CH\$LINK: COMPTOX',                    'https://comptox.epa.gov/dashboard/dsstoxdb/results?search=%s',
'CH\$LINK: FLAVONOIDVIEWER',			'http://www.metabolome.jp/software/FlavonoidViewer/',
'CH\$LINK: HMDB',						'http://www.hmdb.ca/metabolites/%s',
'CH\$LINK: INCHIKEY',					'https://www.google.com/search?q=&quot;%s&quot;',
'CH\$LINK: KAPPAVIEW',					'http://kpv.kazusa.or.jp/kpv4/compoundInformation/view.action?id=%s',
'CH\$LINK: KEGG',						'http://www.genome.jp/dbget-bin/www_bget?%s:%s',
'CH\$LINK: KNAPSACK',					'http://kanaya.naist.jp/knapsack_jsp/info.jsp?sname=C_ID&word=%s',
'CH\$LINK: LIPIDBANK',					'http://lipidbank.jp/cgi-bin/detail.cgi?id=%s',
'CH\$LINK: LIPIDMAPS',					'http://www.lipidmaps.org/data/get_lm_lipids_dbgif.php?LM_ID=%s',
'CH\$LINK: NIKKAJI',					'http://nikkajiweb.jst.go.jp/nikkaji_web/pages/top.jsp?SN=%s&CONTENT=syosai',
'CH\$LINK: PUBCHEM',					'http://pubchem.ncbi.nlm.nih.gov/summary/summary.cgi?',
'CH\$LINK: OligosaccharideDataBase',	'http://www.fukuyama-u.ac.jp/life/bio/biochem/%s.html%s',
'CH\$LINK: OligosaccharideDataBase2D',	'http://www.fukuyama-u.ac.jp/life/bio/biochem/%s.html',
'SP\$LINK: NCBI-TAXONOMY',				'http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=%s',
'SP\$SAMPLE: LOCATION', 				'https://www.ebi.ac.uk/ontology-lookup/?termId=%s',
'MS\$RELATED_MS: PREVIOUS_SPECTRUM',	'Dispatcher.jsp?type=disp&id=%s',
#'PK\$SPLASH:', 							'https://www.google.com/search?q=&quot;%s&quot;'
'PK\$SPLASH:',                          'http://mona.fiehnlab.ucdavis.edu/#/spectra/splash/%s'

Links not implemented yet:
--------------------------
'COMMENT: \[MSn\]',						'Dispatcher.jsp?type=disp&id=%s&site=%s'
'COMMENT: \[Merging\]',					'Dispatcher.jsp?type=disp&id=%s&site=%s'
'COMMENT: \[Merged\]',					'Dispatcher.jsp?type=disp&id=%s&site=%s'
'COMMENT: \[Mass spectrometry\]',		''
'COMMENT: \[Chromatography\]',			''
'COMMENT: \[Profile\]',					'../DB/profile/%s/%s'
'COMMENT: \[Mixture\]',					'Dispatcher.jsp?type=disp&id=%s&site=%s'
'SP\$SAMPLE: LOCATION', 				'https://www.ebi.ac.uk/ontology-lookup/?termId=%s'
'MS\$RELATED_MS: PREVIOUS_SPECTRUM',	'Dispatcher.jsp?type=disp&id=%s'

<a href="URL" target="_blank">VAL</a>
"<a href=\"URL\" target=\"_blank\">" + VAL + "</a>"
	*/
	
	sb.append("ACCESSION: " + accData.ACCESSION + "\n");
	if(accData.RECORD_TITLE != null)	sb.append("RECORD_TITLE: " + accData.RECORD_TITLE + "\n");
	if(accData.DATE != null)			sb.append("DATE: " + accData.DATE + "\n");
	if(accData.AUTHORS != null)			sb.append("AUTHORS: " + accData.AUTHORS + "\n");
	if(accData.LICENSE != null)			sb.append("LICENSE: " + "<a href=\"https://creativecommons.org/licenses/\" target=\"_blank\">" + accData.LICENSE + "</a>" + "\n");
	if(accData.COPYRIGHT != null)		sb.append("COPYRIGHT: " + accData.COPYRIGHT + "\n");
	
	if(accData.PUBLICATION != null){
		String value	= accData.PUBLICATION;
		String regex_pmid	= "PMID:[ ]?\\d{8,8}";
		String regex_doi	= "10\\.\\d{3,9}\\/[\\-\\._;\\(\\)\\/:a-zA-Z0-9]+[a-zA-Z0-9]";
		String regex_doiUrl	= "http\\:\\/\\/doi\\.org\\/" + regex_doi;
		Pattern pattern_pmid	= Pattern.compile(".*" + "(" + regex_pmid	+ ")" + ".*");
	    Matcher matcher_pmid	= pattern_pmid.matcher(value);
	    Pattern pattern_doi		= Pattern.compile(".*" + "(" + regex_doi	+ ")" + ".*");
	    Matcher matcher_doi		= pattern_doi.matcher(value);
	    Pattern pattern_doiUrl	= Pattern.compile(".*" + "(" + regex_doiUrl	+ ")" + ".*");
	    Matcher matcher_doiUrl	= pattern_doiUrl.matcher(value);
	    
	    if(matcher_pmid.matches()){
	    	// link pubmed id
	    	String PMID		= value.substring(matcher_pmid.start(1), matcher_pmid.end(1));
	    	String id		= PMID.substring("PMID:".length()).trim();
	    	value			= value.replaceAll(PMID, "<a href=\"http:\\/\\/www.ncbi.nlm.nih.gov/pubmed/" + id + "?dopt=Citation\" target=\"_blank\">" + PMID + "</a>");
	    }
	    if(matcher_doiUrl.matches()){
	    	// link http://dx.doi.org/<doi> url
	    	String doiUrl	= value.substring(matcher_doiUrl.start(1), matcher_doiUrl.end(1));
	    	value			= value.replaceAll(doiUrl, "<a href=\"" + doiUrl + "\" target=\"_blank\">" + doiUrl + "</a>");
	    } else 
	    if(matcher_doi.matches()){
	    	// link doi
	    	String doi	= value.substring(matcher_doi.start(1), matcher_doi.end(1));
	    	value			= value.replaceAll(doi, "<a href=\"http:\\/\\/dx.doi.org/" + doi + "\" target=\"_blank\">" + doi + "</a>");
	    }
	    
		sb.append("PUBLICATION: " + value + "\n");
	}
	
	for(String COMMENT : accData.COMMENT)
		sb.append("COMMENT: " + COMMENT + "\n");
	sb.append("<hr size=\"1\" color=\"silver\" width=\"98%\" align=\"left\">");
	for(String CH$NAME : accData.CH$NAME)
		sb.append("CH$NAME: " + CH$NAME + "\n");
	for(int idx = 0; idx < accData.CH$COMPOUND_CLASS_NAME.length; idx++)
		sb.append("CH$COMPOUND_CLASS: " + accData.CH$COMPOUND_CLASS_CLASS[idx] + " " + accData.CH$COMPOUND_CLASS_NAME[idx] + "\n");
	if(accData.CH$FORMULA != null)		sb.append("CH$FORMULA: " + "<a href=\"http://www.chemspider.com/Search.aspx?q=" + accData.CH$FORMULA + "\" target=\"_blank\">" + accData.CH$FORMULA + "</a>" + "\n");
	if(accData.CH$EXACT_MASS != -1)		sb.append("CH$EXACT_MASS: " + accData.CH$EXACT_MASS + "\n");
	if(accData.CH$SMILES != null)		sb.append("CH$SMILES: " + accData.CH$SMILES + "\n");
	if(accData.CH$IUPAC != null)		sb.append("CH$IUPAC: " + accData.CH$IUPAC + "\n");
	
	// TODO fetch from AccessionData accData
	String CH$CDK_DEPICT_SMILES				= null;//"CCOCCOCCO |Sg:n:3,4,5:2:ht| PEG-2";
	String CH$CDK_DEPICT_GENERIC_SMILES		= null;//"c1ccc(cc1)/C=C/C(=O)O[R]";
	String CH$CDK_DEPICT_STRUCTURE_SMILES	= null;//"c1ccc(cc1)/C=C/C(=O)O";
	
	if(CH$CDK_DEPICT_SMILES != null){
		ClickablePreviewImageData clickablePreviewImageData2	= StructureToSvgStringGenerator.createClickablePreviewImage(
				CH$CDK_DEPICT_SMILES, null, CH$CDK_DEPICT_SMILES,
				tmpFileFolder, tmpUrlFolder,
				80, 200, 436
		);
		if(clickablePreviewImageData2 != null)
			sb.append("CH$CDK_DEPICT_SMILES: " + clickablePreviewImageData2.getMediumClickablePreviewLink("CH$CDK_DEPICT_SMILES", CH$CDK_DEPICT_SMILES));
		else
			sb.append("CH$CDK_DEPICT_SMILES: " + CH$CDK_DEPICT_SMILES + "\n");
	}
	
	if(CH$CDK_DEPICT_GENERIC_SMILES != null){
		ClickablePreviewImageData clickablePreviewImageData3	= StructureToSvgStringGenerator.createClickablePreviewImage(
				CH$CDK_DEPICT_GENERIC_SMILES, null, CH$CDK_DEPICT_GENERIC_SMILES,
				tmpFileFolder, tmpUrlFolder,
				80, 200, 436
		);
		if(clickablePreviewImageData3 != null)
			sb.append("CH$CDK_DEPICT_GENERIC_SMILES: " + clickablePreviewImageData3.getMediumClickablePreviewLink("CH$CDK_DEPICT_GENERIC_SMILES", CH$CDK_DEPICT_GENERIC_SMILES));
		else
			sb.append("CH$CDK_DEPICT_GENERIC_SMILES: " + CH$CDK_DEPICT_GENERIC_SMILES + "\n");
	}
	
	if(CH$CDK_DEPICT_STRUCTURE_SMILES != null){
		ClickablePreviewImageData clickablePreviewImageData4	= StructureToSvgStringGenerator.createClickablePreviewImage(
				CH$CDK_DEPICT_STRUCTURE_SMILES, null, CH$CDK_DEPICT_STRUCTURE_SMILES,
				tmpFileFolder, tmpUrlFolder,
				80, 200, 436
		);
		if(clickablePreviewImageData4 != null)
			sb.append("CH$CDK_DEPICT_STRUCTURE_SMILES: " + clickablePreviewImageData4.getMediumClickablePreviewLink("CH$CDK_DEPICT_STRUCTURE_SMILES", CH$CDK_DEPICT_STRUCTURE_SMILES));
		else
			sb.append("CH$CDK_DEPICT_STRUCTURE_SMILES: " + CH$CDK_DEPICT_STRUCTURE_SMILES + "\n");
	}
	
	for(int idx = 0; idx < accData.CH$LINK_ID.length; idx++){
		String CH$LINK_ID	= accData.CH$LINK_ID[idx];
		switch(accData.CH$LINK_NAME[idx]){
			case "CAS":								CH$LINK_ID	= "<a href=\"https://www.google.com/search?q=&quot;" + CH$LINK_ID + "&quot;"									+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "CAYMAN":                      	CH$LINK_ID	= "<a href=\"https://www.caymanchem.com/app/template/Product.vm/catalog/" + CH$LINK_ID							+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "CHEBI":                       	CH$LINK_ID	= "<a href=\"https://www.ebi.ac.uk/chebi/searchId.do?chebiId=CHEBI:" + CH$LINK_ID								+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "CHEMPDB":                     	CH$LINK_ID	= "<a href=\"https://www.ebi.ac.uk/msd-srv/chempdb/cgi-bin/cgi.pl?FUNCTION=getByCode&amp;CODE=" + CH$LINK_ID	+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "CHEMSPIDER":                  	CH$LINK_ID	= "<a href=\"https://www.chemspider.com/" + CH$LINK_ID															+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "COMPTOX": 	                	CH$LINK_ID	= "<a href=\"https://comptox.epa.gov/dashboard/dsstoxdb/results?search=" + CH$LINK_ID							+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "FLAVONOIDVIEWER":             	CH$LINK_ID	= "<a href=\"http://www.metabolome.jp/software/FlavonoidViewer/"												+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "HMDB":                        	CH$LINK_ID	= "<a href=\"http://www.hmdb.ca/metabolites/" + CH$LINK_ID														+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "INCHIKEY":                    	CH$LINK_ID	= "<a href=\"https://www.google.com/search?q=&quot;" + CH$LINK_ID + "&quot;"									+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "KAPPAVIEW":                   	CH$LINK_ID	= "<a href=\"http://kpv.kazusa.or.jp/kpv4/compoundInformation/view.action?id=" + CH$LINK_ID						+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "KEGG":                        	CH$LINK_ID	= "<a href=\"http://www.genome.jp/dbget-bin/www_bget?cpd:" + CH$LINK_ID											+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "KNAPSACK":                    	CH$LINK_ID	= "<a href=\"http://kanaya.naist.jp/knapsack_jsp/info.jsp?sname=C_ID&word=" + CH$LINK_ID						+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "LIPIDBANK":                   	CH$LINK_ID	= "<a href=\"http://lipidbank.jp/cgi-bin/detail.cgi?id=" + CH$LINK_ID											+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "LIPIDMAPS":                   	CH$LINK_ID	= "<a href=\"http://www.lipidmaps.org/data/get_lm_lipids_dbgif.php?LM_ID=" + CH$LINK_ID							+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "NIKKAJI":                     	CH$LINK_ID	= "<a href=\"https://jglobal.jst.go.jp/en/redirect?Nikkaji_No=" + CH$LINK_ID + "&CONTENT=syosai"		+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "OligosaccharideDataBase":     	CH$LINK_ID	= "<a href=\"http://www.fukuyama-u.ac.jp/life/bio/biochem/" + CH$LINK_ID + ".html" + CH$LINK_ID					+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "OligosaccharideDataBase2D":   	CH$LINK_ID	= "<a href=\"http://www.fukuyama-u.ac.jp/life/bio/biochem/" + CH$LINK_ID + ".html"								+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "NCBI-TAXONOMY":               	CH$LINK_ID	= "<a href=\"https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=" + CH$LINK_ID							+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
			case "PUBCHEM":{
				if(CH$LINK_ID.startsWith("CID:"))	CH$LINK_ID	= "<a href=\"https://pubchem.ncbi.nlm.nih.gov/compound/" + CH$LINK_ID.substring("CID:".length())				+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>";
				if(CH$LINK_ID.startsWith("SID:"))	CH$LINK_ID	= "<a href=\"https://pubchem.ncbi.nlm.nih.gov/substance/" + CH$LINK_ID.substring("SID:".length())				+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>";
				break;
			}
		}
		
		sb.append("CH$LINK: " + accData.CH$LINK_NAME[idx] + " " + CH$LINK_ID + "\n");
	}
	sb.append("<hr size=\"1\" color=\"silver\" width=\"98%\" align=\"left\">");
	sb.append("AC$INSTRUMENT: " + accData.AC$INSTRUMENT + "\n");
	sb.append("AC$INSTRUMENT_TYPE: " + accData.AC$INSTRUMENT_TYPE + "\n");
	for(String AC$MASS_SPECTROMETRY : accData.AC$MASS_SPECTROMETRY)
		sb.append("AC$MASS_SPECTROMETRY: " + AC$MASS_SPECTROMETRY + "\n");
	for(String AC$CHROMATOGRAPHY : accData.AC$CHROMATOGRAPHY)
		sb.append("AC$CHROMATOGRAPHY: " + AC$CHROMATOGRAPHY + "\n");
	sb.append("<hr size=\"1\" color=\"silver\" width=\"98%\" align=\"left\">");
	for(String MS$FOCUSED_ION : accData.MS$FOCUSED_ION)
		sb.append("MS$FOCUSED_ION: " + MS$FOCUSED_ION + "\n");
	for(String MS$DATA_PROCESSING : accData.MS$DATA_PROCESSING)
		sb.append("MS$DATA_PROCESSING: " + MS$DATA_PROCESSING + "\n");
	sb.append("<hr size=\"1\" color=\"silver\" width=\"98%\" align=\"left\">");
	if(accData.PK$SPLASH != null)		sb.append("PK$SPLASH: " + "<a href=\"http://mona.fiehnlab.ucdavis.edu/#/spectra/splash/" + accData.PK$SPLASH + "\" target=\"_blank\">" + accData.PK$SPLASH + "</a>" + "\n"); // https://www.google.com/search?q=&quot;%s&quot;
//	PK$ANNOTATION: m/z tentative_formula formula_count mass error(ppm)
//	  57.0701 C4H9+ 1 57.0699 4.61
//	  67.0542 C5H7+ 1 67.0542 0.35
//	  69.0336 C4H5O+ 1 69.0335 1.14
	sb.append("PK$NUM_PEAK: " + accData.PK$PEAK_MZ.length + "\n");
	
	sb.append("PK$PEAK: m/z int. rel.int." + "\n");
	
	String[] PK$PEAK_MZ		= accData.formatPK$PEAK_MZ(true);
	String[] PK$PEAK_INT	= accData.formatPK$PEAK_INT(true);
	String[] PK$PEAK_REL	= accData.formatPK$PEAK_REL(true);
	for(int idx = 0; idx < accData.PK$PEAK_MZ.length; idx++)
		sb.append("  " + 
				PK$PEAK_MZ [idx] + " " + 
				PK$PEAK_INT[idx] + " " + 
				PK$PEAK_REL[idx] + "\n"
		);
	sb.append("//");
	
	String recordString	= sb.toString();
	}
	
	// read file
	File file	= new File(MassBankEnv.get(MassBankEnv.KEY_ANNOTATION_PATH) + databaseName + File.separator + accession + ".txt");
	List<String> list	= FileUtil.readFromFile(file);
	
	// process record
	final String delimiter	= ": ";
	StringBuilder sb	= new StringBuilder();
	String inchi	= null;
	String smiles	= null;
	String recordTitle	= null;
	// CH, AC, MS, PK
	boolean ch	= false;
	boolean ac	= false;
	boolean ms	= false;
	boolean pk	= false;
	for(String line : list){
		int delimiterIndex	= line.indexOf(delimiter);
		if(delimiterIndex == -1){
			sb.append(line + "\n");
			continue;
		}
		
		String tag		= line.substring(0, delimiterIndex);
		String value	= line.substring(delimiterIndex + delimiter.length());
		
		// horizontal ruler
		if(tag.startsWith("CH$") && (!ch))	{	sb.append("<hr size=\"1\" color=\"silver\" width=\"98%\" align=\"left\">");	ch	= true;	}
		if(tag.startsWith("AC$") && (!ac))	{	sb.append("<hr size=\"1\" color=\"silver\" width=\"98%\" align=\"left\">");	ac	= true;	}
		if(tag.startsWith("MS$") && (!ms))	{	sb.append("<hr size=\"1\" color=\"silver\" width=\"98%\" align=\"left\">");	ms	= true;	}
		if(tag.startsWith("PK$") && (!pk))	{	sb.append("<hr size=\"1\" color=\"silver\" width=\"98%\" align=\"left\">");	pk	= true;	}
		
		switch(tag){
		case "RECORD_TITLE":
			sb.append("RECORD_TITLE: " + value + "\n");
			recordTitle	= value;
			break;
		case "LICENSE":
			sb.append("LICENSE: " + "<a href=\"https://creativecommons.org/licenses/\" target=\"_blank\">" + value + "</a>" + "\n");
			break;
		case "PUBLICATION":
			String regex_pmid	= "PMID:[ ]?\\d{8,8}";
			String regex_doi	= "10\\.\\d{3,9}\\/[\\-\\._;\\(\\)\\/:a-zA-Z0-9]+[a-zA-Z0-9]";
			String regex_doiUrl	= "http\\:\\/\\/doi\\.org\\/" + regex_doi;
			Pattern pattern_pmid	= Pattern.compile(".*" + "(" + regex_pmid	+ ")" + ".*");
		    Matcher matcher_pmid	= pattern_pmid.matcher(value);
		    Pattern pattern_doi		= Pattern.compile(".*" + "(" + regex_doi	+ ")" + ".*");
		    Matcher matcher_doi		= pattern_doi.matcher(value);
		    Pattern pattern_doiUrl	= Pattern.compile(".*" + "(" + regex_doiUrl	+ ")" + ".*");
		    Matcher matcher_doiUrl	= pattern_doiUrl.matcher(value);
		    
		    if(matcher_pmid.matches()){
		    	// link pubmed id
		    	String PMID		= value.substring(matcher_pmid.start(1), matcher_pmid.end(1));
		    	String id		= PMID.substring("PMID:".length()).trim();
		    	value			= value.replaceAll(PMID, "<a href=\"http:\\/\\/www.ncbi.nlm.nih.gov/pubmed/" + id + "?dopt=Citation\" target=\"_blank\">" + PMID + "</a>");
		    }
		    if(matcher_doiUrl.matches()){
		    	// link http://dx.doi.org/<doi> url
		    	String doiUrl	= value.substring(matcher_doiUrl.start(1), matcher_doiUrl.end(1));
		    	value			= value.replaceAll(doiUrl, "<a href=\"" + doiUrl + "\" target=\"_blank\">" + doiUrl + "</a>");
		    } else 
		    if(matcher_doi.matches()){
		    	// link doi
		    	String doi	= value.substring(matcher_doi.start(1), matcher_doi.end(1));
		    	value			= value.replaceAll(doi, "<a href=\"http:\\/\\/dx.doi.org/" + doi + "\" target=\"_blank\">" + doi + "</a>");
		    }
			sb.append("PUBLICATION: " + value + "\n");
			break;
		case "CH$FORMULA":
			sb.append("CH$FORMULA: " + "<a href=\"http://www.chemspider.com/Search.aspx?q=" + value + "\" target=\"_blank\">" + value + "</a>" + "\n");
			break;
		case "CH$SMILES":
			sb.append("CH$SMILES: " + value + "\n");
			smiles	= value;
			break;
		case "CH$IUPAC":
			sb.append("CH$IUPAC: " + value + "\n");
			inchi	= value;
			break;
		case "CH$CDK_DEPICT_SMILES":
		case "CH$CDK_DEPICT_GENERIC_SMILES":
		case "CH$CDK_DEPICT_STRUCTURE_SMILES":
			ClickablePreviewImageData clickablePreviewImageData2	= StructureToSvgStringGenerator.createClickablePreviewImage(
					tag, null, value,
					tmpFileFolder, tmpUrlFolder,
					80, 200, 436
			);
			if(clickablePreviewImageData2 != null)
				sb.append(tag + ": " + clickablePreviewImageData2.getMediumClickablePreviewLink("CH$CDK_DEPICT_SMILES", value));
			else
				sb.append(tag + ": " + value + "\n");
			break;
		case "CH$LINK":
			String delimiter2	= " ";
			int delimiterIndex2	= value.indexOf(delimiter2);
			
			if(delimiterIndex2 == -1){
				sb.append("CH$LINK: " + value + "\n");
				break;
			}
			
			String CH$LINK_NAME	= value.substring(0, delimiterIndex2);
			String CH$LINK_ID	= value.substring(delimiterIndex2 + delimiter2.length());
			
			switch(CH$LINK_NAME){
				case "CAS":								CH$LINK_ID	= "<a href=\"https://www.google.com/search?q=&quot;" + CH$LINK_ID + "&quot;"									+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "CAYMAN":                      	CH$LINK_ID	= "<a href=\"https://www.caymanchem.com/app/template/Product.vm/catalog/" + CH$LINK_ID							+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "CHEBI":                       	CH$LINK_ID	= "<a href=\"https://www.ebi.ac.uk/chebi/searchId.do?chebiId=CHEBI:" + CH$LINK_ID								+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "CHEMPDB":                     	CH$LINK_ID	= "<a href=\"https://www.ebi.ac.uk/msd-srv/chempdb/cgi-bin/cgi.pl?FUNCTION=getByCode&amp;CODE=" + CH$LINK_ID	+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "CHEMSPIDER":                  	CH$LINK_ID	= "<a href=\"https://www.chemspider.com/" + CH$LINK_ID															+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "COMPTOX": 	                	CH$LINK_ID	= "<a href=\"https://comptox.epa.gov/dashboard/dsstoxdb/results?search=" + CH$LINK_ID							+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "FLAVONOIDVIEWER":             	CH$LINK_ID	= "<a href=\"http://www.metabolome.jp/software/FlavonoidViewer/"												+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "HMDB":                        	CH$LINK_ID	= "<a href=\"http://www.hmdb.ca/metabolites/" + CH$LINK_ID														+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "INCHIKEY":                    	CH$LINK_ID	= "<a href=\"https://www.google.com/search?q=&quot;" + CH$LINK_ID + "&quot;"									+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "KAPPAVIEW":                   	CH$LINK_ID	= "<a href=\"http://kpv.kazusa.or.jp/kpv4/compoundInformation/view.action?id=" + CH$LINK_ID						+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "KEGG":                        	CH$LINK_ID	= "<a href=\"http://www.genome.jp/dbget-bin/www_bget?cpd:" + CH$LINK_ID											+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "KNAPSACK":                    	CH$LINK_ID	= "<a href=\"http://kanaya.naist.jp/knapsack_jsp/info.jsp?sname=C_ID&word=" + CH$LINK_ID						+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "LIPIDBANK":                   	CH$LINK_ID	= "<a href=\"http://lipidbank.jp/cgi-bin/detail.cgi?id=" + CH$LINK_ID											+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "LIPIDMAPS":                   	CH$LINK_ID	= "<a href=\"http://www.lipidmaps.org/data/get_lm_lipids_dbgif.php?LM_ID=" + CH$LINK_ID							+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "NIKKAJI":                     	CH$LINK_ID	= "<a href=\"https://jglobal.jst.go.jp/en/redirect?Nikkaji_No=" + CH$LINK_ID + "&CONTENT=syosai"		+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "OligosaccharideDataBase":     	CH$LINK_ID	= "<a href=\"http://www.fukuyama-u.ac.jp/life/bio/biochem/" + CH$LINK_ID + ".html" + CH$LINK_ID					+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "OligosaccharideDataBase2D":   	CH$LINK_ID	= "<a href=\"http://www.fukuyama-u.ac.jp/life/bio/biochem/" + CH$LINK_ID + ".html"								+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "NCBI-TAXONOMY":               	CH$LINK_ID	= "<a href=\"https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=" + CH$LINK_ID							+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>"; break;
				case "PUBCHEM":{
					if(CH$LINK_ID.startsWith("CID:"))	CH$LINK_ID	= "<a href=\"https://pubchem.ncbi.nlm.nih.gov/compound/" + CH$LINK_ID.substring("CID:".length())				+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>";
					if(CH$LINK_ID.startsWith("SID:"))	CH$LINK_ID	= "<a href=\"https://pubchem.ncbi.nlm.nih.gov/substance/" + CH$LINK_ID.substring("SID:".length())				+ "\" target=\"_blank\">" + CH$LINK_ID + "</a>";
					break;
				}
			}
			
			sb.append("CH$LINK: " + CH$LINK_NAME + delimiter2 + CH$LINK_ID + "\n");
			break;
		case "PK$SPLASH":
			sb.append("PK$SPLASH: " + "<a href=\"http://mona.fiehnlab.ucdavis.edu/#/spectra/splash/" + value + "\" target=\"_blank\">" + value + "</a>" + "\n"); // https://www.google.com/search?q=&quot;%s&quot;
			break;
		default:
			sb.append(line + "\n");
			break;
		}
	}
	
	if(recordTitle == null)
		recordTitle	= "NA";
	
	String shortName	= recordTitle.split(";")[0].trim();
	
	ClickablePreviewImageData clickablePreviewImageData	= StructureToSvgStringGenerator.createClickablePreviewImage(
			accession, inchi, smiles, tmpFileFolder, tmpUrlFolder,
			80, 200, 436
	);
	String svgMedium	= null;
	if(clickablePreviewImageData != null)
		svgMedium	= clickablePreviewImageData.getMediumClickableImage();
	
	
	String recordString	= sb.toString();
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html lang="en">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<meta name="author" content="MassBank" />
		<meta name="coverage" content="worldwide" />
		<meta name="Targeted Geographic Area" content="worldwide" />
		<meta name="rating" content="general" />
		<meta name="copyright" content="Copyright (c) 2006 MassBank Project and (c) 2011 NORMAN Association" />
		<meta name="description" content="MassBank Record of <%=accession%>">
		<meta name="keywords" content="<%=shortName%>, mass spectrum, MassBank record, mass spectrometry, mass spectral library">
		<meta name="revisit_after" content="30 days">
		<meta name="hreflang" content="en">
		<meta name="variableMeasured" content="m/z">
		<meta http-equiv="Content-Style-Type" content="text/css">
		<meta http-equiv="Content-Script-Type" content="text/javascript">
		<link rel="stylesheet" type="text/css" href="../css/Common.css">
		<script type="text/javascript" src="../script/Common.js"></script>
		<!-- SpeckTackle dependencies-->
		<script type="text/javascript" src="https://code.jquery.com/jquery-1.8.3.min.js" ></script>
		<script type="text/javascript" src="../script/StructurePreview.js"></script>
		<script type="text/javascript" src="https://d3js.org/d3.v3.min.js"></script>
		<!-- SpeckTackle library-->
		<script type="text/javascript" src="../script/st.min.js" charset="utf-8"></script>
		<!-- SpeckTackle style sheet-->
		<link rel="stylesheet" href="../css/st.css" type="text/css" />
		<!-- SpeckTackle MassBank loading script-->
		<script type="text/javascript" src="../script/massbank_specktackle.js"></script>
		<title><%=shortName%> Mass Spectrum</title>
	</head>
	<body style="font-family:Times;">
		<table border="0" cellpadding="0" cellspacing="0" width="100%">
			<tr>
				<td>
					<h1>MassBank Record: <%=accession%> </h1>
				</td>
			</tr>
		</table>
		<iframe src="../menu.html" width="860" height="30px" frameborder="0" marginwidth="0" scrolling="no"></iframe>
		<hr size="1">
		<br>
		<font size="+1" style="background-color:LightCyan">&nbsp;<%=recordTitle%>&nbsp;</font>
		<hr size="1">
		<table>
			<tr>
				<td valign="top">
					<font style="font-size:10pt;" color="dimgray">Mass Spectrum</font>
					<br>
					<div id="spectrum_canvas" style="height: 200px; width: 750px; background-color: white"></div>
				</td>
				<td valign="top">
					<font style="font-size:10pt;" color="dimgray">Chemical Structure</font><br>
					<% // display svg
					if(clickablePreviewImageData != null){
						// paste small image to web site %>
						<%=svgMedium%><%
					} else {
						// no structure there or svg generation failed%>
						<img src="../image/not_available_s.gif" width="200" height="200" style="margin:0px;">
					<%}%></td>
			</tr>
		</table>
<hr size="1">
<pre style="font-family:Courier New;font-size:10pt">
<%=recordString%>
</pre>
		<hr size=1>
		<iframe src="../copyrightline.html" width="800" height="20px" frameborder="0" marginwidth="0" scrolling="no"></iframe>
	</body>
</html>