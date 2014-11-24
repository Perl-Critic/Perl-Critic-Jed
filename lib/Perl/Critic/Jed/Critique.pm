package Perl::Critic::Jed::Critique;

use Mojo::Base 'Mojolicious::Controller';
use Perl::Critic;
use PPI::HTML;


#-----------------------------------------------------------------------------

sub critique {
    my $self = shift;

    return $self->_oops('Please select a severity.')
        unless $self->param('severity');

    return $self->_oops('Please paste some code (or upload a file.')
        if $self->param('type') eq 'paste' && !$self->param('pasted');

    return $self->_oops(q{Please select a file (or paste some code).})
        if $self->param('type') eq 'file' && !$self->param('upload')->filename;

    return $self->_oops('That file is empty. Got another one?')
        if $self->param('type') eq 'file' && !$self->param('upload')->size;

    return $self->_oops('Something went wrong. Was that Perl source code?' . $self->param('type'))
        unless eval { $self->_critique; 1 };
}

#-----------------------------------------------------------------------------

sub _critique {
    my $self = shift;

    my $severity = $self->param('severity');

    # Critique code
    my $document = $self->_get_document;
    my $critic = Perl::Critic->new(-severity => $severity, %{ $self->app->config->{perlcritic} || {} });
    my $violations = [ reverse sort {$a->severity <=> $b->severity || $b->location->[0] <=> $a->location->[0]} $critic->critique($document) ];

    # Covert raw source code to HTML
    my $formatter = PPI::HTML->new(line_numbers => 1);
    my $source_code_html = $formatter->html($document->ppi_document);

    # Wrap each line in a numbered <div>
    my @lines = split /\n/, $source_code_html;
    my $fmt = q{<div class="line" name="line-%d">%s</div>};
    $lines[$_] = sprintf $fmt, $_+1, $lines[$_] for 0..$#lines;
    $source_code_html = join '', @lines;

    $self->render(
        template    => 'critique',
        filename    => $document->filename ? $document->filename : 'Pasted code',
        violations  => $violations,
        severity    => $severity,
        source_code => $source_code_html,
        statistics  => $critic->statistics,
    );
}

#-----------------------------------------------------------------------------

sub _get_document {
    my $self = shift;

    my $pasted_code = $self->param('pasted');
    return Perl::Critic::Document->new(-source => \$pasted_code) if $self->param('type') eq 'paste';

    my $upload = $self->param('upload');
    my $source_filename = $upload->filename;
    my $source_code_raw = $upload->slurp;

    return Perl::Critic::Document->new(-source => \$source_code_raw, '-forced-filename' => $source_filename);

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
