package PomBase::Role::PhenotypeFeatureFinder;

=head1 NAME

PomBase::Role::PhenotypeFeatureFinder - Code for finding and creating allele

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PomBase::Role::PhenotypeFeatureFinder

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use perl5i::2;
use Moose::Role;

requires 'get_cvterm';
requires 'find_chado_feature';
requires 'find_organism_by_full_name';

method get_gene($gene_data)
{
  if (!defined $gene_data) {
    croak 'no $gene_data passed to get_gene()';
  }
  my $gene_uniquename = $gene_data->{uniquename};
  my $organism_name = $gene_data->{organism};
  my $organism = $self->find_organism_by_full_name($organism_name);

  return $self->find_chado_feature($gene_uniquename, 1, 1, $organism);
}

method get_transcript($gene_data)
{
  my $gene_uniquename = $gene_data->{uniquename};
  my $organism_name = $gene_data->{organism};
  my $organism = $self->find_organism_by_full_name($organism_name);

  return $self->find_chado_feature("$gene_uniquename.1", 1, 1, $organism);
}

func _get_allele_description($allele) {
  my $description_prop = $allele->search_featureprops('description')->first();
  if (defined $description_prop) {
    return $description_prop->value();
  } else {
    return undef;
  }
}

method get_allele($allele_data)
{
  my $allele;
  my $gene;

  if (ref $allele_data->{gene} eq 'HASH') {
    $gene = $self->get_gene($allele_data->{gene});
  } else {
    $gene = $allele_data->{gene};
  }

  if (exists $allele_data->{primary_identifier}) {
    $allele = $self->chado()->resultset('Sequence::Feature')
                   ->find({ uniquename => $allele_data->{primary_identifier},
                            organism_id => $gene->organism()->organism_id() });
    if (!defined $allele) {
      use Data::Dumper;
      die "failed to find allele from: ", Dumper([$allele_data]);
    }

    return $allele;
  } else {
    if (!defined $allele_data->{name} && !defined $allele_data->{description}) {
      croak "internal error - no name or description passed to get_allele()";
    }

    my $gene_uniquename = $gene->uniquename();
    my $instance_of_cvterm = $self->get_cvterm('relationship', 'instance_of');
    my $existing_rs = $gene->search_related('feature_relationship_objects')
                           ->search({ 'me.type_id' => $instance_of_cvterm->cvterm_id() },
                                    { prefetch => 'subject' })
                           ->search_related('subject');

    if (defined $allele_data->{name}) {
      $existing_rs = $existing_rs->search({ name => $allele_data->{name} });

      if ($existing_rs->count() > 1) {
        die 'database inconsistency - there exists more than one allele feature ' .
        'with the name "' . $allele_data->{name} . '"' . "\n";
      }

      my $existing_allele = $existing_rs->first();

      if (defined $existing_allele) {
        my $existing_description = _get_allele_description($existing_allele);

        if ($existing_allele->name() eq $allele_data->{name}) {
          if (defined $existing_description && defined $allele_data->{description} &&
              $existing_description eq $allele_data->{description} ||
              !defined $existing_description && !defined $allele_data->{description}) {
            # descriptions match - same allele
            return $existing_allele;
          } else {
            die 'description for new allele "' . $allele_data->{name} . '(' .
              ($allele_data->{description}  // 'undefined') . ')" does not ' .
              'match the existing allele with the same name "' .
              $allele_data->{name} . '(' . ($existing_description // 'undefined') . ')"' . "\n";
          }
        }
      }
    } else {
      # no name so check for existing alleles that match our description
      while (defined (my $existing_allele = $existing_rs->next())) {
        my $existing_description = _get_allele_description($existing_allele);

        if ($allele_data->{description} eq $existing_description) {
          return $existing_allele;
        }
      }
    }

    # fall through - no allele exists with matching name or description
    my $new_uniquename = $self->get_new_uniquename($gene_uniquename . ':allele-', 1);
    $allele = $self->store_feature($new_uniquename,
                                   $allele_data->{name}, [], 'allele',
                                   $gene->organism());

    $self->store_feature_rel($allele, $gene, $instance_of_cvterm);

    if (defined $allele_data->{description}) {
      $self->store_featureprop($allele, 'description', $allele_data->{description});
    }

    return $allele;
  }
}

1;
