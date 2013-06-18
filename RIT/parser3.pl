 #!/usr/bin/perl -w 
use     strict          ;    # fun with whitespace
use     LWP::Simple;         # what's that? {provides get($url), just `perldoc`}
use HTML::TokeParser;    # Why? because
 
   #$|=;                        # un buffer
    
   #my $cpanurl = 'http//search.cpan.org/recent';
   
   #my @newest;                # the top  
   #my $lastupdated = '';        # $n distributions have been uploaded since $date
   #my $rawHTML = get($cpanurl); # attempt to d/l the page to mem
   
   #die "LWPSimple messed up $!" unless ($rawHTML);
                                # Habit.  if it's empty, TokeParser would notice
   
   my $tp = HTMLTokeParser->new("file.html") || die "Can't open $!";
   
   
   # And now -- a generic HTMLTokeParser loop
   
   while (my $token = $tp->get_token)
   {
       my $ttype = shift @{ $token };
   
       if($ttype eq "S")    # start tag?
       {
           my($tag, $attr, $attrseq, $rawtxt) = @{ $token };
   
           if($tag eq "a")
           {
               my $a_href = $attr->{'href'};
               my $a_encl = $tp->get_trimmed_text("/$tag");
   
   # be sure you understand what get_trimmed_text or get_text are doing
   # calling either (as well as get_tag) can drastically change
   # the curser position
   # in general calling the no argument version, is preferable here
   
               push ( @newest , [ $a_href, $a_encl ] )
               if( $a_href =~ /\/search\?dist\=/ );
           }
           elsif( ($tag eq "td") and ($rawtxt =~ /colspan=/m) )
           {
             # as opposed to checking the hash like exists $attr->{colspan}
   
               my $p_text = $tp->get_trimmed_text;  # p for potential
   
   # fetches the "trimmed" up until the next "token"
   # passing /td to get_trimmed_text is not advisable, because
   # TokeParser would slurp all the text until the next closing /td
   # which would in effect cause us to skip halfway down the file
   # missing our target links (and pretty much all of them)
   # we could always call unget_token, but this is hard.
   # like swimming up river (but not as enojoyable)
   
               $lastupdated = $p_text
               if($p_text =~ /distributions have been uploaded/m);
           }
       } # since we know what we're looking for, no need for the rest of these
       elsif($ttype eq "T") # text?
       {
       }
       elsif($ttype eq "C") # comment?
       {
       }
       elsif($ttype eq "E") # end tag?
       {
       }
       elsif($ttype eq "D") # declaration?
       {
       }
   
       #last if(scalar @newest == ); # we disappear once we get 
   
   } # endof while (my $token = $p->get_token)
   
   undef $rawHTML; # no more raw html
   undef $tp;      # destroy the HTMLTokeParser object (don't need it no more)
   
   print "<H> $lastupdated </H>\n" if($lastupdated); # just in case we miss it
   
   #for my $arayref (@newest)
   #{
   #    print "<A HREF='http//search.cpan.org";
   #    print $arayref->[];     # the link straingt from href
   #    print "'>";
   #    print $arayref->[];     # the link text
   #    print "</A><BR>\n";
   #}
   
exit;
__END__
