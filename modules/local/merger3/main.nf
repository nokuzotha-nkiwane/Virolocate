process MERGER3 {
    tag "${meta.id}"
    label 'process_high'

    input:
    tuple val(meta), path(lst), path(gbs)


    output:
    tuple val(meta), path("*_tax.tsl"), emit: tsl
    path "versions.yml"             , emit: versions

    script:
    """
    #!/bin/env perl
    perl -e '
        my (\$LSTIN, \$GBIN, \$OUT) = @ARGV;
        open L, "<", \$LSTIN or die "Cannot open list file: \$!";
        my %lst;
        while (<L>) { chomp; \$lst{\$_} = 1; }
        close L;

        open G, "<", \$GBIN or die "Cannot open GB file: \$!";
        my %tmp;
        my \$ACC = "";
        while (<G>) {
            chomp;
            if (/^ACCESSION\\s+(\\S+)/) { \$ACC = \$1; next; }
            if (/\\/db_xref=\\"taxon:(\\d+)\\"/) { \$tmp{\$ACC} = \$1; }
        }
        close G;

        open O, ">", \$OUT or die "Cannot write output: \$!";
        print O "Accession\\tTaxId\\n";
        for my \$k (sort keys %lst) {
            print O "\$k\\t\$tmp{\$k}\\n" if exists \$tmp{\$k};
        }
        close O;
    ' "\$LSTIN" "\$GBIN" "\$OUT"
    
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