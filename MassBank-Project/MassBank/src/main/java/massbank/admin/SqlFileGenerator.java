/*******************************************************************************
 *
 * Copyright (C) 2008 JST-BIRD MassBank
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
 * DB登録用のSQLを生成するクラス
 *
 * ver 1.0.15 2011.10.04
 *
 ******************************************************************************/
package massbank.admin;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Hashtable;

import massbank.GetConfig;
import massbank.GetInstInfo;
import massbank.MassBankEnv;

public class SqlFileGenerator {

	private static final int TABLE_RECORD     = 0;
	private static final int TABLE_CH_NAME    = 1;
	private static final int TABLE_CH_LINK    = 2;
	private static final int TABLE_INSTRUMENT = 3;
	private static final int TABLE_COMMENT    = 4;
	private static final int TABLE_CH_COMPOUND_CLASS	= 5;
	private static final int TABLE_AC_MASS_SPECTROMETRY	= 6;
	private static final int TABLE_AC_CHROMATOGRAPHY	= 7;
	private static final int TABLE_MS_FOCUSED_ION		= 8;
	private static final int TABLE_MS_DATA_PROCESSING	= 9;
	
	private int ver = 2;
	private String[] instNo = null;
	private String[] instName = null;
	private String[] instType = null;
	private HashMap<String, Integer> instNew = null;
	private ArrayList<String> usedNoList = null;
	private String valInst = "";
	private String name = "";
	private String value = "";
	private String acc = "";
	private String nameReco = "";
	private String valReco  = "";
	private String acInst   = "";
	private String acInstType = "";
	private String acMsType ="";
	private ArrayList<String> valNames = new ArrayList<String>();
	private ArrayList<String> valLinkNames = new ArrayList<String>();
	private ArrayList<String> valLinkIds = new ArrayList<String>();
	private Hashtable<String, String> existItem = new Hashtable<String, String>();
	
	private ArrayList<String> valCOMMENT = new ArrayList<String>();
	private ArrayList<String> valCH_COMPOUND_CLASS_NAME = new ArrayList<String>();
	private ArrayList<String> valCH_COMPOUND_CLASS_CLASS = new ArrayList<String>();
	private ArrayList<String> valAC_MASS_SPECTROMETRY = new ArrayList<String>();
	private ArrayList<String> valAC_CHROMATOGRAPHY = new ArrayList<String>();
	private ArrayList<String> valMS_FOCUSED_ION = new ArrayList<String>();
	private ArrayList<String> valMS_DATA_PROCESSING = new ArrayList<String>();
	
	/**
	 * コンストラクタ
	 * @param baseUrl ベースURL
	 * @param selDbName DB名
	 * @param ver レコードフォーマットバージョン
	 */ 
	public SqlFileGenerator( String baseUrl, String selDbName, int ver) {
		
		// レコードフォーマットバージョン退避
		this.ver = ver;
		
		// INSTRUMENT情報を取得
		GetInstInfo instInfo = new GetInstInfo(MassBankEnv.get(MassBankEnv.KEY_BASE_URL));
		GetConfig conf = new GetConfig(baseUrl);
		String[] dbNameList = conf.getDbName();
		int dbIndex = 0;
		for ( int i = 0; i < dbNameList.length; i++ ) {
			if ( dbNameList[i].equals(selDbName) ) {
				dbIndex = i;
				break;
			}
		}
		instInfo.setIndex(dbIndex);
		this.instNo = instInfo.getNo();
		this.instName = instInfo.getName();
		this.instType = instInfo.getType();
		this.instNew = new HashMap<String, Integer>();
		usedNoList = new ArrayList<String>();
		for (String no : this.instNo) {
			usedNoList.add(no);
		}
	}

	/**
	 * レコードファイル読込み
	 * @param filePath レコードファイルのパス
	 */ 
	public void readFile( String filePath ) {
		try {
			this.valInst = "";
			this.name = "";
			this.value = "";
			this.acc = "";
			this.nameReco = "";
			this.valReco  = "";
			this.valNames.clear();
			this.valLinkNames.clear();
			this.valLinkIds.clear();
			this.valCOMMENT.clear();
			this.valCH_COMPOUND_CLASS_NAME.clear();
			this.valCH_COMPOUND_CLASS_CLASS.clear();
			this.valAC_MASS_SPECTROMETRY.clear();
			this.valAC_CHROMATOGRAPHY.clear();
			this.valMS_FOCUSED_ION.clear();
			this.valMS_DATA_PROCESSING.clear();
			
			String line = "";

			existItem.clear();

			// ファイル読込み
			BufferedReader in = new BufferedReader( new FileReader(filePath) );
			while ( ( line = in.readLine() ) != null ) {
				this.cutItem( line );
				if ( name.equals("ACCESSION") ) {
					this.acc = value;
				}
				//***********************************************
				// テーブル:RECORD,INSTRUMENT
				//***********************************************
				else if (name.equals("CH$FORMULA")
					  || name.equals("CH$EXACT_MASS")
					  || name.equals("CH$SMILES")
					  || name.equals("CH$IUPAC")
					  || name.equals("DATE")
					  
					  || name.equals("RECORD_TITLE")
					  || name.equals("AUTHORS")
					  || name.equals("LICENSE")
					  || name.equals("COPYRIGHT")
					  || name.equals("PUBLICATION")
					  || name.equals("PK_SPLASH")
				) {
					this.setRecord();
				}
				else if ( name.equals("AC$INSTRUMENT") ) {
					this.acInst = value;
				}
				else if ( name.equals("AC$INSTRUMENT_TYPE") ) {
					this.acInstType = value.trim();
//					if ( ver == 1 ) {
//						this.acMsType = "N/A";	// フォーマットバージョンが1の場合はMS_TYPEが必須項目ではないため必ずN/Aとする
//						this.setRecord();
//					}
				}
				else if ( name.equals("AC$MASS_SPECTROMETRY") && value.startsWith("MS_TYPE") && ver != 1 ) {
					this.acMsType = value.replaceAll("MS_TYPE", "").trim();
					this.setRecord();
				}
				//***********************************************
				// Tables COMMENT, CH_COMPOUND_CLASS, AC_MASS_SPECTROMETRY, AC_CHROMATOGRAPHY, MS_FOCUSED_ION, MS_DATA_PROCESSING
				//***********************************************
				else if ( name.equals("COMMENT") ) {
					this.setCOMMENT();
				}
				else if ( name.equals("CH$COMPOUND_CLASS") ) {
					this.setCH_COMPOUND_CLASS();
				}
				else if ( name.equals("AC$MASS_SPECTROMETRY") ) {
					this.setAC_MASS_SPECTROMETRY();
				}
				else if ( name.equals("AC$CHROMATOGRAPHY") ) {
					this.setAC_CHROMATOGRAPHY();
				}
				else if ( name.equals("MS$FOCUSED_ION") ) {
					this.setMS_FOCUSED_ION();
				}
				else if ( name.equals("MS$DATA_PROCESSING") ) {
					this.setMS_DATA_PROCESSING();
				}
				//***********************************************
				// テーブル:CH_NAME
				//***********************************************
				else if ( name.equals("CH$NAME") ) {
					this.setChName();
				}
				//***********************************************
				// テーブル:CH_LINK
				//***********************************************
				else if ( name.equals("CH$LINK") ) {
					this.setChLink();
				}
			}
			in.close();
		}
		catch (Exception ex) {
			ex.printStackTrace();
		}
	}

	/**
	 * 各情報有無チェック
	 * @param type レコードファイルのパス
	 * @return true:あり/false:なし
	 */ 
	public boolean isExist( int type ) {
		boolean ret = true;
		switch ( type ) {
		case TABLE_RECORD:
			if ( nameReco.equals("") )  { ret = false; } break;
		case TABLE_CH_NAME:
			if ( valNames.size() == 0 ) { ret = false; } break;
		case TABLE_CH_LINK:
			if ( valLinkNames.size() == 0 ) { ret = false; } break;
		case TABLE_INSTRUMENT:
			if ( valInst.equals("") )  { ret = false; } break;
		case TABLE_COMMENT:
			if ( valCOMMENT.size() == 0 ) { ret = false; } break;
		case TABLE_CH_COMPOUND_CLASS:
			if ( valCH_COMPOUND_CLASS_NAME.size() == 0 ) { ret = false; } break;
		case TABLE_AC_MASS_SPECTROMETRY:
			if ( valAC_MASS_SPECTROMETRY.size() == 0 ) { ret = false; } break;
		case TABLE_AC_CHROMATOGRAPHY:
			if ( valAC_CHROMATOGRAPHY.size() == 0 ) { ret = false; } break;
		case TABLE_MS_FOCUSED_ION:
			if ( valMS_FOCUSED_ION.size() == 0 ) { ret = false; } break;
		case TABLE_MS_DATA_PROCESSING:
			if ( valMS_DATA_PROCESSING.size() == 0 ) { ret = false; } break;
		default: break;
		}
		return ret;
	}

	/**
	 * 生成したSQL文を取得
	 * @param type 種別
	 * @return SQL文
	 */ 
	public String getSql( int type ) {
		String sql = "";
		switch ( type ) {
		case TABLE_RECORD:
			sql = "INSERT INTO RECORD(ID" + nameReco + ") VALUES('"
					+ acc + "'" + valReco + ");";
			break;
		case TABLE_CH_NAME:
			sql	= SqlFileGenerator.generateSqlForIdVersusValueTable("CH_NAME",				acc, valNames);
			break;
		case TABLE_CH_LINK:
			for ( int i = 0; i < valLinkNames.size(); i++ ) {
				sql += "INSERT INTO CH_LINK VALUES('" + acc + "', '" + valLinkNames.get(i) + "', '" + valLinkIds.get(i) + "');";
				if ( i < valLinkNames.size() - 1 ) {
					sql += "\n";
				}
			}
			break;
		case TABLE_INSTRUMENT:
			sql = "INSERT INTO INSTRUMENT(INSTRUMENT_NO, INSTRUMENT_TYPE, INSTRUMENT_NAME) VALUES(" + valInst + ");";
			break;
		case TABLE_COMMENT:
			sql	= SqlFileGenerator.generateSqlForIdVersusValueTable("COMMENT",				acc, valCOMMENT);
			break;
		case TABLE_CH_COMPOUND_CLASS:
			StringBuilder sqlSB = new StringBuilder();
			for ( int i = 0; i < valCH_COMPOUND_CLASS_NAME.size(); i++ ) {
				sqlSB.append("INSERT INTO " + "CH_COMPOUND_CLASS" + " VALUES('" + acc + "', '" + valCH_COMPOUND_CLASS_CLASS.get(i) + "', '" + valCH_COMPOUND_CLASS_NAME.get(i) + "');");
				if ( i < valCH_COMPOUND_CLASS_NAME.size() - 1 ) {
					sqlSB.append("\n");
				}
			}
			sql	= sqlSB.toString();
			break;
		case TABLE_AC_MASS_SPECTROMETRY:
			sql	= SqlFileGenerator.generateSqlForIdVersusValueTable("AC_MASS_SPECTROMETRY",	acc, valAC_MASS_SPECTROMETRY);
			break;
		case TABLE_AC_CHROMATOGRAPHY:
			sql	= SqlFileGenerator.generateSqlForIdVersusValueTable("AC_CHROMATOGRAPHY",	acc, valAC_CHROMATOGRAPHY);
			break;
		case TABLE_MS_FOCUSED_ION:
			sql	= SqlFileGenerator.generateSqlForIdVersusValueTable("MS_FOCUSED_ION",		acc, valMS_FOCUSED_ION);
			break;
		case TABLE_MS_DATA_PROCESSING:
			sql	= SqlFileGenerator.generateSqlForIdVersusValueTable("MS_DATA_PROCESSING",	acc, valMS_DATA_PROCESSING);
			break;
		default:
			break;
		}
		return sql;
	}
	private static String generateSqlForIdVersusValueTable(String tableName, String acc, ArrayList<String> val){
		StringBuilder sql = new StringBuilder();
		for ( int i = 0; i < val.size(); i++ ) {
			sql.append("INSERT INTO " + tableName + " VALUES('" + acc + "', '" + val.get(i) + "');");
			if ( i < val.size() - 1 ) {
				sql.append("\n");
			}
		}
		return sql.toString();
	}

	/**
	 * RECORD,INSTRUMENTテーブルSQL文セット
	 */ 
	private void setRecord() {
		if ( name.equals("CH$FORMULA")
	 	  || name.equals("CH$EXACT_MASS")
	 	  || name.equals("CH$SMILES")
	 	  || name.equals("CH$IUPAC")
	 	  
	 	  || name.equals("PK$SPLASH")
	 	) {
			String exist = (String)this.existItem.get(name);
			if ( exist == null ) {
				existItem.put(name, "true");
			}
			else {
				return;
			}
			
			// handle special fields: MASS_SPECTROMETRY, CHROMATOGRAPHY
			nameReco += ", " + this.name.substring(3);
			valReco += ", ";
			if ( name.equals("CH$EXACT_MASS") ) {
				try {
					double emass = Double.parseDouble(value);
					if ( emass > 0.0d ) {
						valReco += value;
					}
					else {
						valReco += "0";
					}
				}
				catch ( NumberFormatException e ) {
					valReco += "0";
				}
			}
			else {
				valReco += "'" + value + "'";
			}
		}
		else if ( name.equals("DATE")
				|| name.equals("RECORD_TITLE")
			 	|| name.equals("AUTHORS")
			 	|| name.equals("LICENSE")
			 	|| name.equals("COPYRIGHT")
			 	|| name.equals("PUBLICATION")
		) {
			nameReco += ", " + name;
			valReco += ", '" + value + "'";
		}
		else if ( (ver == 1 && name.equals("AC$INSTRUMENT_TYPE"))
				 || ver != 1 && name.equals("AC$MASS_SPECTROMETRY") && value.startsWith("MS_TYPE") ) {
			
			boolean isFound = false;
			int i = 0;
			for ( i = 0; i < this.instNo.length; i++ ) {
				if (  this.acInstType.equals(this.instType[i]) && this.acInst.equals(this.instName[i]) ) {
					isFound = true;
					break;
				}
			}
			if ( isFound ) {
				// DBに登録済みINSTRUMENTの場合
				// instrument is registered in DB
				valReco += ", " + this.instNo[i];
			}
			else {
				// DBに未登録INSTRUMENTの場合
				// instrument is not registered in DB
				int instNo = 1;
				String keyStr = this.acInstType + "\t" + this.acInst;
				if ( this.instNew.containsKey(keyStr) ) {
					// 既に新規登録処理を行っているINSTRUMENTの場合
					// instrument is already pending registration
					instNo = this.instNew.get(keyStr);
				}
				else {
					// まだ新規登録処理を行っていないINSTRUMENTの場合
					// instrument is unknown so far
					for (int tmpNo=instNo; tmpNo<Integer.MAX_VALUE; tmpNo++) {
						if (!usedNoList.contains(String.valueOf(tmpNo))) {
							usedNoList.add(String.valueOf(tmpNo));
							instNo = tmpNo;
							break;
						}
					}
					this.instNew.put(keyStr, instNo);
					valInst = "'" + instNo + "', '" + this.acInstType + "', '" + this.acInst + "'";
				}
				valReco += ", " + String.valueOf(instNo);
			}
			nameReco += ", INSTRUMENT_NO";
			
			nameReco += ", MS_TYPE";
			valReco += ", '" + this.acMsType + "'";	
		}
	}
	private void setCOMMENT() {
		valCOMMENT.add( value );
	}
	private void setCH_COMPOUND_CLASS() {
		if(value.indexOf("; ") == -1){
			valCH_COMPOUND_CLASS_CLASS.add( "NA" );
			valCH_COMPOUND_CLASS_NAME.add( value );
		} else {
			String[] tmp	= value.split("; ");
			valCH_COMPOUND_CLASS_CLASS.add( tmp[0] );
			valCH_COMPOUND_CLASS_NAME.add( value.substring( (tmp[0] + "; ").length() ) );
		}
	}
	private void setAC_MASS_SPECTROMETRY() {
		valAC_MASS_SPECTROMETRY.add( value );
	}
	private void setAC_CHROMATOGRAPHY() {
		valAC_CHROMATOGRAPHY.add( value );
	}
	private void setMS_FOCUSED_ION() {
		valMS_FOCUSED_ION.add( value );
	}
	private void setMS_DATA_PROCESSING() {
		valMS_DATA_PROCESSING.add( value );
	}
	/**
	 * CH_NAMEテーブルSQL文セット
	 */ 
	private void setChName() {
		value = value.trim().replaceAll( "'", "\\\\'" );
		valNames.add( value );
	}

	/**
	 * CH_LINKテーブルSQL文セット
	 */ 
	private void setChLink() {
		int pos = value.trim().indexOf(" ");
		if ( pos > 0 ) {
			value = value.trim().replaceAll( "'", "\\\\'" );
			valLinkNames.add( value.substring( 0, pos ) );
			valLinkIds.add( value.substring( pos + 1 ) );
		}
	}

	/**
	 * 項目名と値の分割
	 * @param line 分割対象文字列
	 */ 
	private void cutItem( String line ) {
		this.name = "";
		this.value = "";
		int pos = line.indexOf(":");
		if ( pos >= 0 ) {
			this.name = line.substring( 0, pos );
			if ( line.length() > pos + 2 ) {
				this.value = line.substring( pos + 2 );
			}
		}
	}
}
