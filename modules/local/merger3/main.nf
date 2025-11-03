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
    base_name=\$(basename "${lst}" .lst)
    OUT="\${base_name}_tax.tsl"

    cat <<'PERL' > script.pl
    use strict;
    use warnings;

    my (\$LSTIN, \$GBIN, \$OUT) = @ARGV;
    
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

    # Read GenBank file - store by accession with and without version
    open my \$G, '<', \$GBIN or die "Cannot open GB file: \$!";
    my %tmp;
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

    # Write output
    open my \$O, '>', \$OUT or die "Cannot write output: \$!";
    for my \$k (sort keys %lst) {
        if (exists \$tmp{\$k}) {
            print \$O "\$k\\t\$tmp{\$k}\\n";
        }
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
    touch sample_tax.tsl

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        merger3: "1.0.0"
    END_VERSIONS
    """
}