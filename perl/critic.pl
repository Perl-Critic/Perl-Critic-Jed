#!/usr/bin/perl

#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/perlcritic.com/perl/critic.pl $
#     $Date: 2010-10-06 11:43:16 -0700 (Wed, 06 Oct 2010) $
#   $Author: thaljef $
# $Revision: 3959 $
########################################################################

use strict;
use warnings;
use CGI qw(:standard);
use English qw(-no_match_vars);
use File::Temp qw(tempfile);
use File::Basename qw(basename);
use Syntax::Highlight::Perl::Improved;
use Perl::Critic;
use Template;
use Carp;

#-----------------------------------------------------------------------------
# Persistent variables

our $TT_INCLUDE = '/var/www/vhosts/perlcritic.com/tt2';
our $TT = Template->new( {INCLUDE_PATH => $TT_INCLUDE} );
our $HL = create_highlighter();

#-----------------------------------------------------------------------------

if ( http('HTTP_USER_AGENT') =~ m{ (?: mozilla|msie ) }imx ) {
    eval {
	my $source_fh           = upload('code_file');
	my $source_path         = param('code_file');
        my $severity            = param('severity');
	my ($raw, $cooked)      = load_source_code( $HL, $source_fh );
	my $code_frame_url      = generate_code_frame( $TT, $cooked );
	my @violations          = critique_source_code( $severity, $raw, $source_path );
	my $critique_frame_url  = generate_critique_frame( $TT, $code_frame_url, @violations );
	my $status              = render_page( $TT, $source_path, $code_frame_url, $critique_frame_url );
    };

    if ($EVAL_ERROR) {
	show_error_screen($TT);
    }
}

else {
  my $raw                   = \do{  local $/ = undef; <STDIN> };
  my @violations            = critique_source_code( 1, $raw );
  print header, @violations;
}

#=============================================================================


sub render_page {
    my ($TT, @args) = @_;
    my %TT_vars = ();
    print header;
    @TT_vars{ qw( source_path code_url critique_url ) } = @args;
    $TT->process( 'results.html.tt', \%TT_vars ) or confess $TT->error();
    return 1;
}

#-----------------------------------------------------------------------------

sub critique_source_code {
    my ($severity, $source_ref, $source_path) = @_;
    my $critic = Perl::Critic->new( -severity => $severity, -theme => 'core' );
    my $doc = Perl::Critic::Document->new( -source => $source_ref, '-forced-filename' => $source_path);
    my @viols = $critic->critique( $doc );
    return @viols;
}

#-----------------------------------------------------------------------------

sub load_source_code {
    my ($HL, $source_fh) = @_;
    my $formatted_source_code = q{};
    my $raw_source_code       = q{};
    my $line_number           = 1;

    while( my $line_of_source_code = <$source_fh> ) {
        $raw_source_code .= $line_of_source_code;
	my $formatted_line = $HL->format_string( $line_of_source_code );
        $formatted_source_code .= prepend_line_number($formatted_line, $line_number);
	$line_number++;
    }

    return (\$raw_source_code, \$formatted_source_code);
}

sub prepend_line_number {
    my ($line_text, $line_number) = @_;
    my $anchor = sprintf '<a name="%i">%04i: </a>', $line_number, $line_number;
    return $anchor . $line_text;
}

#-----------------------------------------------------------------------------

sub generate_code_frame{
    my ($TT, $string_ref) = @_;
    my ($temp_fh, $temp_file) = make_tempfile();
    my $template = 'frame-code.html.tt';
    $TT->process($template, {code => ${$string_ref}}, $temp_fh)
      or confess $TT->error();
    return '/tmp/' . basename($temp_file);
}

sub generate_critique_frame {
    my ($TT, $code_frame_url, @violations) = @_;
    my ($temp_fh, $temp_file) = make_tempfile();
    my $template = 'frame-critique.html.tt';
    my $TT_VARS = { violations => \@violations, target => $code_frame_url };
    $TT->process($template, $TT_VARS, $temp_fh)
      or confess $TT->error();
    return '/tmp/' . basename($temp_file);
}

#-----------------------------------------------------------------------------

sub create_highlighter {
    my %color_table = get_color_table();
    my $hl = Syntax::Highlight::Perl::Improved->new();
    $hl->define_substitution('<' => '&lt;', '>' => '&gt;', '&' => '&amp;');

    # Install the formats
    while ( my ( $type, $style ) = each %color_table ) {
	$hl->set_format($type, [ qq{<span style="$style">}, q{</span>} ] );
    }

    return $hl;
}

#-----------------------------------------------------------------------------

sub show_error_screen {
    my ($TT) = @_;
    print header();
    my $template = 'error.html.tt';
    $TT->process($template) or confess $TT->error();
    return 1;
}

#-----------------------------------------------------------------------------

sub get_color_table {

    return (
            'Variable_Scalar'   => 'color:#080;',
            'Variable_Array'    => 'color:#f70;',
            'Variable_Hash'     => 'color:#80f;',
            'Variable_Typeglob' => 'color:#f03;',
            'Subroutine'        => 'color:#980;',
            'Quote'             => 'color:#00a;',
            'String'            => 'color:#00a;',
            'Comment_Normal'    => 'color:#069;font-style:italic;',
            'Comment_POD'       => 'color:#014;font-family:garamond,serif;',
            'Bareword'          => 'color:#3A3;',
            'Package'           => 'color:#900;',
            'Number'            => 'color:#f0f;',
            'Operator'          => 'color:#000;',
            'Symbol'            => 'color:#000;',
            'Keyword'           => 'color:#000;font-weight:bold;',
            'Builtin_Operator'  => 'color:#300;',
            'Builtin_Function'  => 'color:#001;',
            'Character'         => 'color:#800;',
            'Directive'         => 'color:#399;font-style:italic;',
            'Label'             => 'color:#939;font-style:italic;',
            'Line'              => 'color:#000;',
        );
}

#-----------------------------------------------------------------------------

sub make_tempfile {
    my $temp_dir = shift || get_temp_dir();
    return tempfile( DIR => $temp_dir );
}

sub get_temp_dir {
    return $ENV{TMP} || $ENV{TEMP} || '/var/tmp';
}

#-----------------------------------------------------------------------------

#print {$temp_fh} qq{<html><body><pre style="font-size:10pt;color:#336;">\n};
#print {$temp_fh} qq{</pre></body></html>\n};
