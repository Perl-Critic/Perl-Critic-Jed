package Perl::Critic::Jed;

use Mojo::Base qw(Mojolicious);

#-----------------------------------------------------------------------------

sub startup {
    my $self = shift;

    $self->moniker('pcjd');
    $self->plugin(Config => {});
    push @{$self->routes->namespaces}, __PACKAGE__;

    $self->routes->get('/' => 'index');
    $self->routes->post('/critique/:type')->name('critique')->to('critique#critique');

    # Redirect everything else back home (no 404s)
    $self->routes->any('/*' => sub { $_[0]->redirect_to('/') });

    return $self;
}

#-----------------------------------------------------------------------------
1;

__END__
