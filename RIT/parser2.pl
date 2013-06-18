    #!/usr/bin/perl
     
    use strict;
    use LWP::Simple;
    use HTML::TokeParser;
     
    #my $content = get("http://www.google.co.cr/");
    #die "Couldn't get it!" unless defined $content;
     
    my $stream = HTML::TokeParser->new("file.html");
     
    while (my $token = $stream->get_token) {
        if ($token->[0] eq 'T') { # text
        # process the text in $token->[1]
        
            $token->[1] =~ s/[\t]//g;
            $token->[1] =~ s/[ ]+//g;
            print $token->[1];  
        
        }
        if ($token->[0] eq 'S') { # tag de html
        # los atributos estan en $token->[2]
            
            $token->[1] =~ s/[\t]//g;
            $token->[1] =~ s/[ ]+//g;
            print $token->[2]{'href'}."\n";
            print $token->[2]{'alt'}."\n";        
        }
    } 
