package MyParser;
    use base qw(HTML::Parser);

    # This parser only looks at opening tags
    sub start { 
	my ($self, $tagname, $attr, $attrseq, $origtext) = @_;
		#if ($tagname eq 'a') {
	    	#print "URL found: ", $attr->{ href }, "\n";
		#}
			print "Tag encontrado: ".$tagname."\n";
    }

    package main;

    my $parser = MyParser->new;
    $parser->parse_file( "file.html" );
