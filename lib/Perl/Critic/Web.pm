package Perl::Critic::Web;

use Mojo::Base qw(Mojolicious);
use Perl::Critic;

#-----------------------------------------------------------------------------

sub startup {
    my $self = shift;
    $self->plugin(PPI => {no_check_file => 1});
    $self->routes->get('/' => 'index');
    $self->routes->post('critique' => \&critique);
    return $self;
}

#-----------------------------------------------------------------------------

sub critique {
    my $self = shift;
    my $severity = $self->param('severity');
    my $upload = $self->param('code_file');
    my $source_path = $upload->filename;
    my $source_code = $upload->slurp;
    my $agent = $self->req->headers->user_agent;

    my @violations = critique_source_code( $severity, \$source_code, $source_path );
    my $status     = render_page( $self, $source_path, \$source_code, \@violations );
}

#-----------------------------------------------------------------------------

sub render_page {
    my ($self, @args) = @_;
    my %stash;
    @stash{ qw( filename source_code violations ) } = @args;
    $self->render('results' => %stash);
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

sub is_in_development_mode { shift->mode eq 'development' }

#-----------------------------------------------------------------------------

sub is_in_production_mode { shift->mode eq 'production' }

#-----------------------------------------------------------------------------
1;

__END__
