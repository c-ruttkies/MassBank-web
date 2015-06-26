#! /usr/bin/perl
#-------------------------------------------------------------------------------
#
# Copyright (C) 2008 JST-BIRD MassBank
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#===============================================================================
#
# 全ての化合物名リスト取得
#
# ver 3.0.1  2008.12.05
#
#-------------------------------------------------------------------------------
use CGI;
use DBI;

$query = new CGI;
$name = $query->param('name');
$wc = $query->param('wc');
$db_name = $query->param('dsn');
if ( $db_name eq '' ) {
	$db_name = "MassBank";
}
open(F, "DB_HOST_NAME");
while ( <F> ) {
	chomp;
	$host_name .= $_;
}

print "Content-Type: text/plain\n\n";

$SQLDB = "DBI:mysql:$db_name:$host_name";
$User = 'bird';
$PassWord = 'bird2006';
$dbh  = DBI->connect($SQLDB, $User, $PassWord) || exit(0);
$sql = "select NAME, ID from SPECTRUM";
if ( $name ne '' ) {
	$sql .= " where left(NAME,instr(NAME,';')-1) ";
	if ( $wc eq 'both' ) {
		$sql .= "like '\%$name\%'";
	} elsif ( $wc eq 'start' ) {
		$sql .= "like '\%$name'";
	} elsif ( $wc eq 'end' ) {
		$sql .= "like '$name\%'";
	} else {
		$sql .= "='$name'";
	}
}
$sql .= " order by ID";

@ans = &MySql( $sql );
foreach $rec ( @ans ) {
	print join("\t", @$rec) ,"\n";
}
$dbh->disconnect;
exit(0);

sub MySql() { local($sql) = @_;
	local($sth, $n, $i, @ans, @ret);
	@ret = ();
	$sth = $dbh->prepare($sql);
	$sth->execute || exit(0);
	$n = $sth->rows;
	for ( $i = 0; $i < $n; $i ++ ) {
		@ans = $sth->fetchrow_array;
		push(@ret, [@ans]);
	}
	$sth->finish;
	return @ret;
}

1;

