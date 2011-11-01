#!/usr/bin/perl 
# ABillS User Web interface
#


use vars qw($begin_time %LANG $CHARSET @MODULES $USER_FUNCTION_LIST);

BEGIN 
{
	my $libpath = '../';
	
	$sql_type='mysql';
	unshift(@INC, $libpath ."Abills/$sql_type/");
	unshift(@INC, $libpath ."Abills/");
	unshift(@INC, $libpath);
	unshift(@INC, $libpath . 'libexec/');
	eval { require Time::HiRes; };
	if (! $@) 
	{
	Time::HiRes->import(qw(gettimeofday));
	$begin_time = gettimeofday();
	
	}
	else 
	{
		$begin_time = 0;
	}
}


require "config.pl";
require "Abills/templates.pl";
use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Portal;



$html = Abills::HTML->new( { IMG_PATH => 'img/',
	                           NO_PRINT => 1,
	                           CONF     => \%conf,
	                           CHARSET  => $conf{default_charset},
	                       });

print "Content-Type: text/html\n\n";

my $sql = Abills::SQL->connect($conf{dbtype}, 
                               $conf{dbhost}, 
                               $conf{dbname}, 
                               $conf{dbuser}, 
                               $conf{dbpasswd},
                               { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $db = $sql->{db};
my $Portal = Portal->new($db, $admin, \%conf);
require "../Abills/modules/Portal/lng_russian.pl";

$html->{CHARSET}=$CHARSET if ($CHARSET);

my %OUTPUT; # �������� �� ��������� �������


	#$Portal->{debug}=1;
	# ����� ���� ��� �������
	$list = $Portal->portal_menu_list({ MENU_SHOW => 1});
	if($list->[0]->[0])
	{	
		foreach my $line ( @$list ) 
		{
			# ���� ���� url ������, ��������� ����
			if($line->[2] eq '')
			{
				$url = 'portal.cgi?menu_category=' . $line->[0];
			}
			# ���� ���� url �� ������ ��������� ������� ������ 
			else
			{
				
				# ���� ������ �������� http:// ������� ��� ����
				if ($line->[2] =~ m|http://*|)
				{
					$url = $line->[2];					
				}
				# ���� ������ �� �������� http://  - ��������� 
				else
				{
					$url = 'http://' . $line->[2];
				}
			}
			
			# ���� ������� ���� �� ��������� � �������� ���� �� ������� ���� ��� ���������
			if($FORM{menu_category} != $line->[0])
			{   
				$OUTPUT{MENU} .= $html->tpl_show(_include('portal_menu', 'Portal'), {
													HREF => $url,  
													MENU_NAME => $line->[1],},
													{ OUTPUT2RETURN => 1 });
			} 
			else
			{
				#  ��������� ��������� ���� 
				$OUTPUT{MENU} .= $html->tpl_show(_include('portal_menu_hovered', 'Portal'), { 
													MENU_NAME => $line->[1],},
													{ OUTPUT2RETURN => 1 });
			}							
		}
	} 
	else
	{
		# �������  ��������� "� ������� �� ������� �������"
		$OUTPUT{MENU} = $_NO_MENU;
	}

	if($FORM{menu_category})
	{
		# ���� ������ ������ ����, ��������� ������ ������
		$list = $Portal->portal_articles_list({ARTICLE_ID=>$FORM{menu_category}});
		if($list->[0]->[0])
		{
			my $total_articles = 0;
			foreach my $line ( @$list ) 
			{
				# ���� ���� ������ ������ ��� ����� �� ��� ������� ���� - ������� ������
				if ($line->[6] <= time()) 
				{	 
					 $OUTPUT{CONTENT} .= $html->tpl_show(_include('portal_content', 'Portal'), {
															HREF				=> 'portal.cgi?article=' . $line->[0],  
															TITLE				=> $line->[1],
															SHORT_DESCRIPTION	=> $line->[2]},
															{ OUTPUT2RETURN => 1 });
					$total_articles++;
					
				}
			}
			# ���� � ��������� ����� ������� ��� ������ ������� ������� - "� ���� ��������� ���� ��� ������"
			if($total_articles <= 0) 
			{
				
				$OUTPUT{CONTENT} .= $html->tpl_show(_include('portal_article', 'Portal'), {
														TITLE 	=> '',
														ARTICLE => $_NO_DATA},
														{ OUTPUT2RETURN => 1 });
				
			}
			



		}
		else 
		{
			# ���� � ������ ��������� ���� ��� ������� ������� ��������� - "� ���� ��������� ���� ��� ������"
			 $OUTPUT{CONTENT} .= $html->tpl_show(_include('portal_article', 'Portal'), {
													TITLE 	=> '',
													ARTICLE => $_NO_DATA},
													{ OUTPUT2RETURN => 1 });
		}
	}
	else 
	{
		# ���������� ������ �� �������
		$list = $Portal->portal_articles_list({MAIN_PAGE=>1});
		if($list->[0]->[0])
		{
			# ���� ���� ������ ������ ��� ����� �� ��� ������� ���� - ������� ������
			foreach my $line ( @$list ) 
			{
				if ($line->[6] <= time()) 
				{
				 $OUTPUT{CONTENT} .= $html->tpl_show(_include('portal_content', 'Portal'), {
														HREF => 'portal.cgi?article=' . $line->[0],  
														TITLE => $line->[1],
														SHORT_DESCRIPTION => $line->[2]},
														{ OUTPUT2RETURN => 1 });	
				}
			}
		}
		else
		{
			 # ������� ��������� - "� ���� ��������� ���� ��� ������"
			 $OUTPUT{CONTENT} .= $html->tpl_show(_include('portal_article', 'Portal'), {		
													TITLE => '',
													ARTICLE => $_NO_DATA},
													{ OUTPUT2RETURN => 1 });		
		}

	}
	
			
	if($FORM{article}) {
			# ����������� ������ ���������
			$list = $Portal->portal_articles_list({ID =>$FORM{article}});
			if($list->[0]->[0])
			{
				$OUTPUT{CONTENT} = $html->tpl_show(_include('portal_article', 'Portal'), {
														TITLE 	=> $list->[0]->[1],
														ARTICLE => $list->[0]->[3]},
														{ OUTPUT2RETURN => 1 });	
			}
		
	}


	


	

print $html->tpl_show(_include('portal_body', 'Portal'), {%OUTPUT}) ;



1

