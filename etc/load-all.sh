#!/bin/sh -

DB=pombase-build-24

cd $HOME/pombe/pombe-embl/
svn update || exit 1

cd $HOME/git/pombase-run; vp) || exit 1

PERL5LIB=$HOME/git/pombase-run/lib

cd $HOME/chado/embl_load
log_file=log.`date_string`
$HOME/git/pombase-run/script/load-chado.pl -d --mapping "pt_mod:PSI-MOD:$HOME/Dropbox/pombase/chado_load_warnings/modification_map.txt" --mapping "phenotype:fission_yeast_phenotype:$HOME/Dropbox/pombase/phenotype/phenotype-map.txt" --obsolete-term-map $HOME/pombe/go-doc/obsoletes-exact $HOME/db/load-chado.yaml $DB $HOME/pombe/pombe-embl/*.contig 2>&1 | tee $log_file
$HOME/git/pombase-run/etc/process-log.pl $log_file

cd $HOME/db
./script/pombase-import.pl ./load-chado.yaml biogrid sloth $DB kmr44 kmr44 < $HOME/downloads/BIOGRID-ORGANISM-Schizosaccharomyces_pombe-3.1.78.tab2.txt)

./script/pombase-import.pl ./load-chado.yaml gaf --assigned-by-filter=GeneDB_Spombe sloth pombe-chado-ng-v13-full-goa kmr44 kmr44 < $HOME/Work/pombe/pombe-embl/external-go-data/go_comp.tex
./script/pombase-import.pl ./load-chado.yaml gaf --assigned-by-filter=GeneDB_Spombe sloth pombe-chado-ng-v13-full-goa kmr44 kmr44 < $HOME/Work/pombe/pombe-embl/external-go-data/go_proc.tex
./script/pombase-import.pl ./load-chado.yaml gaf --assigned-by-filter=GeneDB_Spombe sloth pombe-chado-ng-v13-full-goa kmr44 kmr44 < $HOME/Work/pombe/pombe-embl/external-go-data/go_func.tex
./script/pombase-import.pl ./load-chado.yaml gaf --term-id-filter-filename=~kmr44/pombe/pombe-embl/goa-load-fixes/filtered_GO_IDs --db-ref-filter-filename=~kmr44/pombe/pombe-embl/goa-load-fixes/filtered_mappings --assigned-by-filter=GeneDB_Spombe sloth pombe-chado-ng-v13-full-goa kmr44 kmr44 < $HOME/Work/pombe/sources/gene_association.GeneDB_Spombe.inf.gaf
./script/pombase-import.pl ./load-chado.yaml gaf --assigned-by-filter=GeneDB_Spombe sloth pombe-chado-ng-v13-full-goa kmr44 kmr44 < $HOME/Work/pombe/pombe-embl/external-go-data/From_curation_tool
./script/pombase-import.pl ./load-chado.yaml gaf --assigned-by-filter=GeneDB_Spombe sloth pombe-chado-ng-v13-full-goa kmr44 kmr44 < $HOME/Work/pombe/pombe-embl/external-go-data/GO_ORFeome_localizations2.tex
./script/pombase-import.pl ./load-chado.yaml gaf --term-id-filter-filename=~kmr44/pombe/pombe-embl/goa-load-fixes/filtered_GO_IDs --db-ref-filter-filename=~kmr44/pombe/pombe-embl/goa-load-fixes/filtered_mappings --assigned-by-filter=InterPro,UniProtKB sloth pombe-chado-ng-v13-full-goa kmr44 kmr44 < ~/Work/pombe/gene_association.goa_uniprot.pombe
./script/filter-redundant-go.sh
