

<!-- $OUT=$FILE_APACHE_CONF_DELIM 
-->
#------------------------------------------------------------------------------
#
#  Start of WebDyne section
#
#------------------------------------------------------------------------------
#
#
#  Any modification between the <!-- 


my $delim=$FILE_APACHE_CONF_DELIM;
$delim=~s/^.//;
$OUT=$delim;

--> lines
#  will be lost in the next install/upgrade cycle. 
#
#  Do not edit this section !
#

Include "<!-- $OUT=File::Spec->catfile($DIR_APACHE_CONF,$FILE_WEBDYNE_CONF) -->"


#------------------------------------------------------------------------------
#
#  End of WebDyne section
#
#------------------------------------------------------------------------------
<!-- $OUT=$FILE_APACHE_CONF_DELIM -->
