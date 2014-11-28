package Perl::Critic::Jed::Critique;

use Mojo::Base 'Mojolicious::Controller';
use Perl::Critic;
use PPI::HTML;


#-----------------------------------------------------------------------------

sub critique {
    my $self = shift;

    return $self->_oops('Please select a severity.')
        unless $self->param('severity');

    return $self->_oops("Please select a file.")
        unless $self->param('upload')->filename;

    return $self->_oops('That file is empty. Got another one?')
        unless $self->param('upload')->size;

    return $self->_oops('Something went wrong. Was that Perl source code?')
        unless eval { $self->_critique; 1 };
}

#-----------------------------------------------------------------------------

sub _critique {
    my $self = shift;

    my $severity = $self->param('severity');
    my $upload = $self->param('upload');
    my $source_filename = $upload->filename;
    my $source_code_raw = $upload->slurp;

    # Critique code
    my $document = Perl::Critic::Document->new(-source => \$source_code_raw, '-forced-filename' => $source_filename);
    my $critic = Perl::Critic->new(-severity => $severity, %{ $self->app->config->{perlcritic} || {} });
    my $violations = [ reverse sort {$a->severity <=> $b->severity || $b->location->[0] <=> $a->location->[0]} $critic->critique($document) ];

    # Convert raw source code to HTML
    my $formatter = PPI::HTML->new(line_numbers => 1);
    my $source_code_html = $formatter->html($document->ppi_document);

    # Wrap each line in a numbered <div>
    my @lines = split /\n/, $source_code_html;
    my $fmt = q{<div class="line" name="line-%d">%s</div>};
    $lines[$_] = sprintf $fmt, $_+1, $lines[$_] for 0..$#lines;
    $source_code_html = join '', @lines;

    $self->render(
        template    => 'critique',
        filename    => $source_filename,
        violations  => $violations,
        severity    => $severity,
        source_code => $source_code_html,
        statistics  => $critic->statistics,
    );
}

#-----------------------------------------------------------------------------

sub _oops {
    my ($self, $alert) = @_;
    $self->flash(alert => $alert);
    $self->redirect_to('/');
}

#-----------------------------------------------------------------------------
1;

__END__
