package Perl::Critic::Web;

use strict;
use warnings;

use Mojo::Base qw(Mojolicious);
use Mojo::ByteStream qw(b);
use English qw(-no_match_vars);
use File::Temp qw(tempfile);
use File::Basename qw(basename);
use Syntax::Highlight::Perl::Improved;
use Perl::Critic;
use IO::String;
use Carp;

#-----------------------------------------------------------------------------
# Persistent variables

#our $TT_INCLUDE = '/var/www/vhosts/perlcritic.com/tt2';
our $TT = undef; #Template->new( {INCLUDE_PATH => $TT_INCLUDE} );
our $HL = create_highlighter();

#-----------------------------------------------------------------------------

sub startup {
    my $self = shift;
    $self->routes->get('/' => 'index');
    $self->routes->post('critique' => \&critique);
    return $self;
}

#-----------------------------------------------------------------------------

sub critique {
    my $self = shift;
    my $upload = $self->param('code_file');
    my $source_path = $upload->filename;
    my $source_fh = IO::String->new($upload->slurp);
    my $severity = $self->param('severity');
    my $agent = $self->req->headers->user_agent;

    if ( $agent =~ m{ (?: mozilla|msie ) }imx ) {
        eval {
            my ($raw, $cooked)      = load_source_code( $HL, $source_fh );
            my $code_frame_url      = generate_code_frame( $self, $cooked );
            my @violations          = critique_source_code( $severity, $raw, $source_path );
            my $critique_frame_url  = generate_critique_frame( $self, $code_frame_url, @violations );
            my $status              = render_page( $self, $source_path, $code_frame_url, $critique_frame_url );
        };

        if ($EVAL_ERROR) {
            show_error_screen($TT);
        }
    }

    else {
      my $raw                   = \do{  local $/ = undef; <STDIN> };
      my @violations            = critique_source_code( 1, $raw );
      print @violations;
    }
}

#=============================================================================

sub render_page {
    my ($self, @args) = @_;
    my %TT_vars = ();
    @TT_vars{ qw( source_path code_url critique_url ) } = @args;
    $self->render('results' => %TT_vars);
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

sub generate_code_frame {
    my ($self, $string_ref) = @_;
    my ($temp_fh, $temp_file) = make_tempfile();
    my $template = 'frame-code';

    my $code = b(${$string_ref});
    my $out = $self->render_to_string($template => (code => $code));
    print $temp_fh $out;
    close $temp_fh;

    return '/tmp/' . basename($temp_file);
}

sub generate_critique_frame {
    my ($self, $code_frame_url, @violations) = @_;
    my ($temp_fh, $temp_file) = make_tempfile();
    my $template = 'frame-critique';

    my %TT_vars = ( violations => \@violations, target => $code_frame_url );
    my $out = $self->render_to_string($template => %TT_vars);
    print $temp_fh $out;
    close $temp_fh;

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
    die @_;
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
    return tempfile( DIR => $temp_dir, SUFFIX => '.html' );
}

sub get_temp_dir {
    return 'public/tmp';
}

#-----------------------------------------------------------------------------
1;

__END__
