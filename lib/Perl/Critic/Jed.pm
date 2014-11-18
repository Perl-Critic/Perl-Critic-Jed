package Perl::Critic::Jed;

use Mojo::Base qw(Mojolicious);
use Perl::Critic;
use PPI::HTML;

#-----------------------------------------------------------------------------

sub startup {
    my $self = shift;
    $self->moniker('pcjd');
    $self->plugin(Config => {});
    $self->routes->get('/' => 'index');
    $self->routes->post('critique' => \&critique);
    return $self;
}

#-----------------------------------------------------------------------------

sub critique {

    my $c = shift; # controller
    my $severity = $c->param('severity');
    my $upload = $c->param('upload');
    my $source_filename = $upload->filename;
    my $source_code_raw = $upload->slurp;

    # Critique code
    my $config = $c->app->config->{perlcritic} || {};
    my $document = Perl::Critic::Document->new(-source => \$source_code_raw, '-forced-filename' => $source_filename);
    my $critic = Perl::Critic->new(-severity => $severity, %{ $config });
    my @violations = $critic->critique($document);

    # Covert raw source code to HTML
    my $formatter = PPI::HTML->new(line_numbers => 1);
    my $source_code_html = $formatter->html($document->ppi_document);

    # Wrap each line in a numbered <div>
    my @lines = split /\n/, $source_code_html;
    my $fmt = q{<div class="line" name="line-%d">%s</div>};
    $lines[$_] = sprintf $fmt, $_+1, $lines[$_] for 0..$#lines;
    $source_code_html = join '', @lines;

    return $c->render(
        filename    => $source_filename,
        violations  => \@violations,
        severity    => $severity,
        source_code => $source_code_html,
        statistics  => $critic->statistics,
    );
}

#-----------------------------------------------------------------------------
1;

__END__
