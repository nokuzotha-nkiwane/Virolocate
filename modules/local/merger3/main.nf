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
        s/\\r//g;  # Remove carriage returns
        s/^\\s+|\\s+\$//g;  # Trim whitespace
        next if /^\\s*\$/;  # Skip empty lines
        \$lst{\$_} = 1;
        warn "LIST: '\$_'\\n";  # Debug output
    }
    close \$L;

    # Read GenBank file
    open my \$G, '<', \$GBIN or die "Cannot open GB file: \$!";
    my %tmp;
    my \$ACC = '';
    while (<\$G>) {
        chomp;
        if (/^ACCESSION\\s+(\\S+)/) { 
            \$ACC = \$1;
            warn "FOUND ACC: '\$ACC'\\n";  # Debug output
            next;
        }
        if (/\\/db_xref=\\"taxon:(\\d+)\\"/) { 
            \$tmp{\$ACC} = \$1 if \$ACC;
            warn "TAXON for \$ACC: \$1\\n";  # Debug output
        }
    }
    close \$G;

    # Write output
    open my \$O, '>', \$OUT or die "Cannot write output: \$!";
    print \$O "Accession\\tTaxId\\n";
    my \$matched = 0;
    for my \$k (sort keys %lst) {
        if (exists \$tmp{\$k}) {
            print \$O "\$k\\t\$tmp{\$k}\\n";
            \$matched++;
        } else {
            warn "NO MATCH for: '\$k'\\n";  # Debug output
        }
    }
    close \$O;
    
    warn "Total matched: \$matched out of " . scalar(keys %lst) . " accessions\\n";
    PERL

    perl script.pl "\$LSTIN" "\$GBIN" "\$OUT" 2>&1 | head -100
    
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