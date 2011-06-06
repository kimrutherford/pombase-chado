package PomBase::Chado::CheckLoad;

=head1 NAME

PomBase::Chado::CheckLoad - Check that the loading worked

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomBase::Chado::CheckLoad

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use perl5i::2;
use Moose;

use Carp::Assert;

with 'PomBase::Role::ConfigUser';
with 'PomBase::Role::ChadoUser';
with 'PomBase::Role::CvQuery';

method check
{
  my $chado = $self->chado();

  my $rel_rs = $chado->resultset('Sequence::FeatureRelationship');
  should ($rel_rs->count(), 12);

  my $loc_rs = $chado->resultset('Sequence::Featureloc');
  should ($loc_rs->count(), 24);

  my $feature_prop_rs = $chado->resultset('Sequence::Featureprop');
  should ($feature_prop_rs->count(), 5);

  my $feature_dbxref_rs = $chado->resultset('Sequence::FeatureDbxref');
  should ($feature_dbxref_rs->count(), 8);

  my $pombe = $chado->resultset('Organism::Organism')
    ->find({ species => 'pombe' });

  my $gene_cvterm = $self->get_cvterm('sequence', 'gene');

  my $rs = $chado->resultset('Sequence::Feature')
    ->search({
      type_id => $gene_cvterm->cvterm_id(),
      organism_id => $pombe->organism_id(),
    });

  should ($rs->count(), 5);

  $rs->next();
  my $gene = $rs->next();

  should ($gene->uniquename(), "SPAC977.10");
  should ($gene->feature_cvterms()->count(), 14);

  my $cvterms_rs =
    $gene->feature_cvterms()->search_related('cvterm');

  should ($cvterms_rs->count(), 14);

  assert (grep { $_->name() eq 'plasma membrane' } $cvterms_rs->all());

  my $seq_feat_cv = $self->get_cv('sequence_feature');
  my $seq_feat_rs =
    $chado->resultset('Cv::Cvterm')->search({ cv_id => $seq_feat_cv->cv_id() });

  should ($seq_feat_rs->count(), 4);

  for my $feat ($seq_feat_rs->all()) {
    print $feat->name(), "\n";
  }

  my $coiled_coil_cvterm = $self->get_cvterm('sequence_feature', 'coiled-coil');

  my $feature_cvterm_rs =
    $gene->feature_cvterms()->search({
      cvterm_id => $coiled_coil_cvterm->cvterm_id()
    });

  my $feature_cvterm = $feature_cvterm_rs->next();

  my @props = sort map { $_->value(); } $feature_cvterm->feature_cvtermprops();

  should ($props[0], '19700101');
  should ($props[1], 'predicted');
  should ($props[2], 'region');
}

