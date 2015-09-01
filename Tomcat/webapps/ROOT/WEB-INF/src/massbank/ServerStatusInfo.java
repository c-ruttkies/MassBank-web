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
 * �T�[�o�E�X�e�[�^�X���f�[�^�N���X
 *
 * ver 1.0.0 2009.01.26
 *
 ******************************************************************************/
package massbank;

public class ServerStatusInfo {
	private String svrName = "";
	private String url     = "";
	private String dbName  = "";
	private boolean status = true;

	/**
	 * �R���X�g���N�^
	 * @param svrName �T�[�o�� 
	 * @param url URL
	 * @param dbName DB��
	 */
	public ServerStatusInfo(String svrName, String url, String dbName) {
		this.svrName = svrName;
		this.url     = url;
		this.dbName  = dbName;
	}

	/**
	 * �X�e�[�^�X��ݒ肷��
	 * @param isActive �X�e�[�^�X
	 */
	public void setStatus(boolean isActive) {
		this.status = isActive;
	}

	/**
	 * �T�[�o�����擾����
	 * return �T�[�o��
	 */
	public String getServerName() {
		return this.svrName;
	}
	/**
	 * URL���擾����
	 * return URL
	 */
	public String getUrl() {
		return this.url;
	}

	/**
	 * DB�����擾����
	 * return DB��
	 */
	public String getDbName() {
		return this.dbName;
	}

	/**
	 * �X�e�[�^�X���擾����
	 * return �X�e�[�^�X
	 */
	public boolean getStatus() {
		return this.status;
	}
}