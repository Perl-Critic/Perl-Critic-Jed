package Perl::Critic::Web;

use Mojo::Base qw(Mojolicious);
use Perl::Critic;
use PPI::HTML;

#-----------------------------------------------------------------------------

sub startup {
    my $self = shift;
    $self->routes->get('/' => 'home');
    $self->routes->post('critique' => \&critique);
    return $self;
}

#-----------------------------------------------------------------------------

sub critique {

    my $self = shift;
    my $severity = $self->param('severity');
    my $upload = $self->param('code_file');
    my $source_file = $upload->filename;
    my $source_code = $upload->slurp;

    # Critique code
    my $doc = Perl::Critic::Document->new( -source => \$source_code, '-forced-filename' => $source_file);
    my $critic = Perl::Critic->new( -severity => $severity, -theme => 'core' );
    my @violations = $critic->critique( $doc );

    # Covert code to HTML
    my $formatter = PPI::HTML->new(line_numbers => 1);
    my $source_code_html = $formatter->html( $doc->ppi_document );

    # Wrap each line in a <div>
    my @lines = split /\n/, $source_code_html;
    $lines[$_] = qq{<div class="ppi-line" name="line-@{[$_+1]}">$lines[$_]</div>} for 0..$#lines;
    $source_code_html = join '', @lines;

    return $self->render( filename    => $source_file,
                          violations  => \@violations,
                          severity    => $severity,
                          source_code => $source_code_html,
                          statistics  => $critic->statistics, );
}

#-----------------------------------------------------------------------------
1;

__END__
