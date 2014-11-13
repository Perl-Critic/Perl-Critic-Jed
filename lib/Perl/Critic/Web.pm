package Perl::Critic::Web;

use Mojo::Base qw(Mojolicious);
use Perl::Critic;
use PPI::HTML;

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
    my $severity = $self->param('severity');
    my $upload = $self->param('code_file');
    my $source_file = $upload->filename;
    my $source_code = $upload->slurp;

    my $doc = Perl::Critic::Document->new( -source => \$source_code, '-forced-filename' => $source_file);
    my $critic = Perl::Critic->new( -severity => $severity, -theme => 'core' );
    my @violations = $critic->critique( $doc );

    my $formatter = PPI::HTML->new;
    my $source_code_html = $formatter->html( \$source_code );

    my %stash = (violations  => \@violations, source_code => $source_code_html);
    return $self->render(results => %stash);
}

#-----------------------------------------------------------------------------

sub is_in_development_mode { shift->mode eq 'development' }

#-----------------------------------------------------------------------------

sub is_in_production_mode { shift->mode eq 'production' }

#-----------------------------------------------------------------------------
1;

__END__
