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
 * ���O�o�̓N���X
 *
 * ver 1.0.1 2008.12.05
 *
 ******************************************************************************/
package massbank;

import java.io.*;
import java.util.*;
import javax.servlet.ServletContext;
import massbank.GetConfig;

public class MassBankLog {

	/**
	 * �G���[���O�o��
	 */
	static public void ErrorLog( String progName, String msg, ServletContext context ) {
		String logHead = "** " + progName + " **\n";
		String outMessage = "Error : " + msg + "\n";
		context.log( logHead + outMessage );
	}

	/**
	 * �g���[�X���O�o��
	 */
	static public void TraceLog( String progName, String msg, ServletContext context, boolean isTrace ) {
		if ( !isTrace ) {
			return;
		}
		String logHead = "** " + progName + " **\n";
		String outMessage = msg + "\n";
		context.log( logHead + outMessage );
	}
}