#use strict;
use LWP::Simple;
use HTML::TokeParser;
use File::Basename;
 
#Arreglo para los stopwords
my @stopwords;

#Hash para los documentos con su id
%documentos;

#Par�metros del Page Rank
$diferencia;
$iteraciones;

#Hash que llevan el valor del PageRank
%PageRankAnterior;
%PageRankActual;
%Ligas;

@TablaEnlaces;

#Variable que va a guardar el id del documento actual
my $id = 0;

#Variable que va a guardar el numero total de documentos
my $N;

#--------------------------MAIN------------------------#
my $comando = shift;

if($comando eq "analizar")
{
    iniciar();
}
if($comando eq "pr")
{
    $diferencia = shift;
    $iteraciones = shift;

    #En caso de que alguno de los par�metros no se proporcione,
    #se les asigna el valor por defecto.
    if(diferencia eq "")
    {
        $diferencia = 0.0001;
    }
    if(iteraciones eq "")
    {
        $iteraciones = 100;
    }
}
#--------------------------MAIN------------------------#

sub iniciar()
{
    crear_stops();
    open_dir();
}

sub open_dir{
    my ($path) = "D:/HTML";
    opendir(DIR, $path) or die("Error, No se pudo abrir el directorio\n");
    my @files = grep(!/^\./,readdir(DIR));
    closedir(DIR);
    my $file;
    my $hash;
    my $filetemp;
    open (DOCS, '>>D:/Documentos.txt');
    print DOCS "DOCID\t\tRUTA\n";
    foreach $file (@files){
        $file = $path.'/'.$file; #path absoluto del fichero o directorio
        #Se mantiene en memoria el arreglo con los documentos
        $documentos{$file} = $id;
        next unless( -f $file or -d $file ); #se rechazan pipes, links, etc ..
        if( -d $file)
        {
            open_dir($file,$hash);
        }
        elsif($file =~ /.html/)
        {
                #Se incrementa la variable id (ID y N�mero de documentos)                
                print DOCS "docId".$id.";".$file."\n";
                $id++;
                &analizar($file);
        }       
    }
    close (DOCS);
    $N = $id;
    #&imprimirDocumentos;
    &procesarDocumentos;

    #&imprimirTablaEnlaces;
    #print "\n\n";
    #&imprimirHashLigas;
}


sub analizar
{   
    my ($path) = ($_[0]);
    # Este es el archivo que va a leer
    my $stream = HTML::TokeParser->new($path);
    
    # Este es el archivo que va a tener los terminos
    open (VOCABULARIO, '>>D:/Vocabulario.txt');
    while (my $token = $stream->get_token)
    {
        if ($token->[0] eq 'T') 
        { # text 
        # process the text in $token->[1]        
            procesar_linea($token->[1]);           
        }
        if ($token->[0] eq 'S') 
        { # tag de html
        # los atributos estan en $token->[2]            
            if($token->[2]{'href'})
            {
                print VOCABULARIO $token->[2]{'href'}.";".$id."\n"; 
            }
            if($token->[2]{'alt'})
            {
                procesar_linea($token->[2]{'alt'});
            }
        }
    }
    close (VOCABULARIO);
}


sub procesar_linea
{
    my ($linea) = ($_[0]);
    my @palabras;
    @palabras = split (' ', $linea);

    my $word;

    for $word (@palabras)
    {
        $word =~ s/&aacute;/a/g;
        $word =~ s/&eacute;/a/g;
        $word =~ s/&iacute;/a/g;
        $word =~ s/&oacute;/a/g; 
        $word =~ s/&uacute;/a/g;
        $word =~ tr/[A-Z]/[a-z]/;
        $word =~ tr/������������������/aaeeiiooouuuaeioouu/;
        $word =~ s/[\.]/ /g;
        $word =~ s/[\;]/ /g;
        $word =~ s/[\,]/ /g;
        $word =~ s/[\(]/ /g;
        $word =~ s/[\)]/ /g;
        $word =~ s/[\[]/ /g;
        $word =~ s/[\]]/ /g;
        $word =~ s/[\{]/ /g;
        $word =~ s/[\}]/ /g;
        $word =~ s/[\:]/ /g;
        $word =~ s/[\�]/ /g;
        $word =~ s/[\!]/ /g;
        $word =~ s/[\@]/ /g;
        $word =~ s/[\#]/ /g;
        $word =~ s/[\$]/ /g;
        $word =~ s/[\%]/ /g;
        $word =~ s/[\^]/ /g;
        $word =~ s/[\&]/ /g;
        $word =~ s/[\*]/ /g;
        $word =~ s/[\=]/ /g;
        $word =~ s/[\\]/ /g;
        $word =~ s/[\"]/ /g;
        $word =~ s/[\�]/ /g;
        $word =~ s/[\?]/ /g;
        $word =~ s/[\<]/ /g;
        $word =~ s/[\>]/ /g;
        $word =~ s/[\']/ /g;
        $word =~ s/[\`]/ /g;
        $word =~ s/[\|]/ /g;
        $word =~ s/[\/]/ /g;
        $word =~ s/[\+]/ /g;
        $word =~ s/[\~]/ /g;
        $word =~ s/[\t]//g;
        $word =~ s/[ ]//g;
        $word =~ s/[\n]//g;

        if (($word =~ m/[-_�a-z0-9]+/))
        {
            if(esta($word) == 1)
            {
                if($word cmp "")
                {
                    print VOCABULARIO $word.";".$id."\n";
                }
            }
        }
    }    
}


#Almacena en el arreglo @stopwords las palabras le�das del archivo de texto de stopwords.
sub crear_stops{
    #Ruta del archivo de texto de stopwords.
    #Se abre el archivo y se usa el file handler MYFILE
    open(MYFILE, "stop.txt");
    #Mientras que MYFILE sea distinto de 0
    while (<MYFILE>){
        #Se lee la l�nea.
        my $linea = $_;
        #Quita \n de l�nea.
        chomp($linea);
        #Se inserta la palabra en el arreglo.       
        push(@stopwords, $linea);
    }   
}

sub esta{
    my ($termino) = ($_[0]);
    my $i;
    for ($i = 0; $i < 37; $i++) 
    {
        my $elem = $stopwords[$i]."\n";
        my  $num = ($elem =~ /^$termino$/);
        if ($num == 1) {
            return 0;
        }
    }
    return 1;
}

sub imprimirDocumentos
{
    print "Lista de documentos:\n";
    foreach $doc(sort {$documentos{$a} <=> $documentos{$b} } keys %documentos)
    {
        if($doc cmp "")
        {
            print $doc." id: ".$documentos{$doc}."\n";
        }
    }
}

#Inicia el PageRank de cada documento en 1
sub inicializarPageRank
{
    foreach $doc(sort {$documentos{$a} <=> $documentos{$b} } keys %documentos)
    {
        if($doc cmp "")
        {
            $PageRankAnterior{$doc} = 1;
            $PageRankActual{$doc} = 1;
        }
    }
}

#Obtiene qui�n apunta a qui�n
sub procesarDocumentos
{
    my ($path) = "D:/HTML";
    opendir(DIR, $path) or die("Error, No se pudo abrir el directorio\n");
    my @files = grep(!/^\./,readdir(DIR));
    closedir(DIR);
    my $file;
    foreach $file (@files){
        $file = $path.'/'.$file; #path absoluto del fichero o directorio
        if($file =~ /.html/)
        {
            &procesarEnlaces($file);
        }
    }
}

sub procesarEnlaces
{
    my ($path) = ($_[0]);
    # Este es el archivo que va a leer
    my $stream = HTML::TokeParser->new($path);

    $file = basename($path);
    
    while (my $token = $stream->get_token)
    {
        if ($token->[0] eq 'S') 
        { # tag de html
        # los atributos estan en $token->[2]            
            if($token->[2]{'href'})
            {
                $j = entaceEstaEnColeccion($token->[2]{'href'});
                if($j != -1)
                {
                    $i = $documentos{$file};
                    #Hay enlace entre I,J
                    if($TablaEnlaces[$i][$j] != 1)
                    {
                        $TablaEnlaces[$i][$j] = 1;
                        #Se incrementa el n�mero de ligas
                        $Ligas{$file}++;

                        #if($file eq "authors.html")
                        #{
                        #    print $token->[2]{'href'}."\n";
                        #}
                    }
                }
            }
        }
    }
}

#Determina si un enlace es interno o externo, los enlaces externos son ignorados
sub entaceEstaEnColeccion
{
    my ($termino) = ($_[0]);
    foreach $doc(sort {$documentos{$a} <=> $documentos{$b} } keys %documentos)
    {
        if(basename($doc) eq $termino)
        {
            return $documentos{$doc};
        }
    }
    return -1;
}

sub imprimirTablaEnlaces
{
    print "Tabla Enlaces\n";
    print @$_, "\n" foreach ( @TablaEnlaces );
}

sub imprimirHashLigas
{
    print "Ligas:\n";
    foreach $doc(sort {$Ligas{$a} <=> $Ligas{$b} } keys %Ligas)
    {
        if($doc cmp "")
        {
            print "Documento: ".$doc." Cantidad de Ligas: ".$Ligas{$doc}."\n";
        }
    }
}