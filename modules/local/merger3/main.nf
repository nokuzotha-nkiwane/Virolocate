process MERGER3 {
    tag "${meta.id}"
    label 'process_high'

    input:
    tuple val(meta), path(lst), path(gb)


    output:
    tuple val(meta), path("*_tax.tsl"), emit: tsl
    path "versions.yml"             , emit: versions

    script:
    """
    #!/usr/bin/env bash
    set -euo pipefail

    LSTIN="${lst}"
    GBIN="${gb}"
    OUT="${meta.id}_taxid.tsv"

    cat <<'PERL' > script.pl
    use strict;
    use warnings;

    my (\$LSTIN, \$GBIN, \$OUT) = @ARGV;
    open my \$L, '<', \$LSTIN or die "Cannot open list file: \$!";
    my %lst;
    while (<\$L>) { chomp; \$lst{\$_} = 1; }
    close \$L;

    open my \$G, '<', \$GBIN or die "Cannot open GB file: \$!";
    my %tmp;
    my \$ACC = '';
    while (<\$G>) {
        chomp;
        if (/^ACCESSION\\s+(\\S+)/) { \$ACC = \$1; next; }
        if (/\\/db_xref=\\"taxon:(\\d+)\\"/) { \$tmp{\$ACC} = \$1; }
    }
    close \$G;

    open my \$O, '>', \$OUT or die "Cannot write output: \$!";
    print \$O "Accession\\tTaxId\\n";
    for my \$k (sort keys %lst) {
        print \$O "\$k\\t\$tmp{\$k}\\n" if exists \$tmp{\$k};
    }
    close \$O;
    PERL

    perl script.pl "\$LSTIN" "\$GBIN" "\$OUT"
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        merger3: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch sample_tax.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        merger3: "1.0.0"
    END_VERSIONS
    """
}