process MERGER4 {
    tag "${meta.id}"
    label 'process_high'

    input:
    tuple val(meta), path(lst), path(gbs)


    output:
    tuple val(meta), path("*_tax.tsl"), emit: tsl
    path "versions.yml"             , emit: versions

    script:
    """
    #!/usr/bin/env bash
    set -euo pipefail

    LSTIN="${lst}"
    base_name=\$(basename "${lst}" .lst)
    OUT="\${base_name}_tax.tsl"

    cat <<'PERL' > script.pl
    use strict;
    use warnings;

    my \$LSTIN = shift @ARGV;
    my \$OUT = pop @ARGV;
    my @GBINS = @ARGV;
    
    # Read list file
    open my \$L, '<', \$LSTIN or die "Cannot open list file: \$!";
    my %lst;
    while (<\$L>) { 
        chomp; 
        s/\\r//g;
        s/^\\s+|\\s+\$//g;
        next if /^\\s*\$/;
        \$lst{\$_} = 1;
    }
    close \$L;

    # Read all GenBank files
    my %tmp;
    for my \$gbfile (@GBINS) {
        open my \$G, '<', \$gbfile or die "Cannot open GB file \$gbfile: \$!";
        my \$ACC = '';
        while (<\$G>) {
            chomp;
            if (/^ACCESSION\\s+(\\S+)/) { 
                \$ACC = \$1;
                next;
            }
            if (/^VERSION\\s+(\\S+)/) {
                my \$version_acc = \$1;
                # Store under the VERSION accession (with version number)
                \$ACC = \$version_acc;
                next;
            }
            if (/\\/db_xref=\\"taxon:(\\d+)\\"/) { 
                \$tmp{\$ACC} = \$1 if \$ACC;
            }
        }
        close \$G;
    }

    # Write output
    open my \$O, '>', \$OUT or die "Cannot write output: \$!";
    for my \$k (sort keys %lst) {
        if (exists \$tmp{\$k}) {
            print \$O "\$k\\t\$tmp{\$k}\\n";
        }
    }
    close \$O;
    PERL

    perl script.pl "\$LSTIN" ${gbs} "\$OUT"
    

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonomy_id_check: "1.0.0"
    END_VERSIONS
    """

    stub:
    """
    touch sample_tax.tsl

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        taxonomy_id_check: "1.0.0"
    END_VERSIONS
    """
}