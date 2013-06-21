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
%Ligas; #Cantidad de ligas de cada documento

@TablaEnlaces;

#Variable que va a guardar el id del documento actual
my $id = 0;

#Variable que va a guardar el numero total de documentos
my $N;

#Variable que va a guardar la consulta
my $consulta;

#Variable que va a guardar la consulta
my @parametros_consulta;

#Hash para las frecuencias de los t�rminos de la consulta
%fij_consulta;
#Hash para el vocabulario de la colecci�n
%vocabulario_inicio = undef;
%vocabulario_docs = undef;
#Hash para los pesos de la consulta
%pesos_consulta;
#Hash para los resultados de la consulta
%documento_resultado;

#--------------------------MAIN------------------------#
my $comando = shift;

if($comando eq "analizar")
{
    iniciar();
}
if($comando eq "consulta")
{
    $consulta = shift;

    @a_consulta = split(" ", $consulta);

    for $word (@a_consulta)
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
                    push(@parametros_consulta, $word);
                }
            }
        }
    }
    &busqueda_vectorial;

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

    &calcularPageRank;
}
#--------------------------MAIN------------------------#

sub iniciar()
{
    crear_stops();
    open_dir();
}

sub open_dir{
    my ($path) = "D:/Prueba";
    opendir(DIR, $path) or die("Error, No se pudo abrir el directorio\n");
    my @files = grep(!/^\./,readdir(DIR));
    closedir(DIR);
    my $file;
    my $hash;
    my $filetemp;
    open (DOCS, '>>D:/Documentos.txt');
    foreach $file (@files){
        $file = $path.'/'.$file; #path absoluto del fichero o directorio
        #Se mantiene en memoria el arreglo con los documentos
        #$documentos{$file} = $id;
        next unless( -f $file or -d $file ); #se rechazan pipes, links, etc ..
        if( -d $file)
        {
            open_dir($file,$hash);
        }
        elsif($file =~ /.html/)
        {
                #Se incrementa la variable id (ID y N�mero de documentos)                
                print DOCS $id.";".$file."\n";
                $id++;
                &analizar($file);
        }       
    }
    close (DOCS);
    $N = $id;
    #Se guarda el archivo que tiene la cantidad de archivos de la colecci�n
    &guardarArchivoN;
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


#Busca usando la similitud coseno.
sub busqueda_vectorial
{
    &cargar_vocabulario;

    #print "Calculando fiq\n";
    &calcular_fij_consulta;

    #print "Calculando peso de la consulta\n";
    &calcular_pesos_consulta;
    
    &calcular_resultados_consulta;
    
    #print "Creando archivo $consulta.txt ...\n";

    open(NUEVO, ">>$consulta.txt");
    foreach $pal (sort { $documento_resultado{$b} <=> $documento_resultado{$a} } keys %documento_resultado) {
        if($pal cmp "")
        {
            printf NUEVO $pal."\t\t"."%.4f",$documento_resultado{$pal};
            print NUEVO "\n";            
        }
    }
    close(NUEVO);
    
}

#Para calcular las frecuencias de cada termmino en la consulta
sub cargar_vocabulario
{    
    open(MYFILE, "D:/Vocabulario.txt");
    #Mientras que MYFILE sea distinto de 0
    while (<MYFILE>){
        #Se lee la l�nea.
        $linea = $_;
        #Quita \n de l�nea.
        chomp($linea);
        @arreglo = split(";", $linea);
        $palabra = $arreglo[0];
        $apariciones = $arreglo[1];
        $inicio = $arreglo[2];
        $vocabulario_inicio{$palabra} = $inicio;
        $vocabulario_docs{$palabra} = $apariciones;
    }
    close(MYFILE);
}

#Para calcular las frecuencias de cada termmino en la consulta
sub calcular_fij_consulta
{
    
    for $palabra (@parametros_consulta)
    {
        $fij_consulta{$palabra}++;
    }
}


sub calcular_pesos_consulta{
    #Se calculan los pesos de los wiq
    foreach $pal (@parametros_consulta) 
    {   
        if($pal cmp "")
        {            
            $ni = $vocabulario_docs{$pal};
            $fij = $fij_consulta{$pal};
            print "$ni --- $fij -- $N";
            if($fij > 0){
                $pesos_consulta{$pal} = ((log($fij)/log(2))+1)*(log($N/$ni)/log(2));
            }
        }
    }
}


sub calcular_resultados_consulta{
    #Se calculan los pesos de los wiq
    foreach $pal (@parametros_consulta) 
    {   
        $inicio = $vocabulario_inicio{$pal};
        $docs = $vocabulario_docs{$pal};
        $pesoq = $pesos_consulta{$pal};
        open(POSTINGS, "D:/Postings.txt");
        $i = 0;
        while (<POSTINGS>) 
        {
            print "$pal -> inicio $inicio";
            print "$pal -> docs   $docs";
            if ($inicio == $i) 
            {
                $linea = $_;
                chomp($linea);
                @arreglo = split(";", $linea);
                $id = $arreglo[0];
                $peso = $arreglo[1];
                $documento_resultado{$id} += (peso * pesoq);
            }
            $i++;
        }
        close(POSTINGS);
    }
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

sub guardarArchivoN
{
    open(DOCS, '>>D:/N.txt');
    print DOCS $N;
    close(DOCS);
}

sub abrirArchivoN
{
    open (MYFILE, '<D:/N.txt');
    while(<MYFILE>)
    {
        $N = $_;
    }
    close(MYFILE);
}

sub abrirArchivoDocumentos
{
    open (MYFILE, '<D:/Documentos.txt');
    while(<MYFILE>)
    {
        $linea = $_;
        chomp($linea);
        @arreglo_linea = split(';', $linea);
        $documentos{$arreglo_linea[1]} = $arreglo_linea[0];
        @arreglo_linea = undef;
    }
    close(MYFILE);
}

######################################################## PAGE RANK ###########################################################

sub calcularPageRank
{
    #Se inicializan los hash con los page rank
    &abrirArchivoN;
    &abrirArchivoDocumentos;
    #Se inician los PR en 1
    &inicializarPageRank;
    #Se inicia la tabla de enlaces en 0
    &inicializarTablaEnlaces;
    &procesarDocumentos;
    &imprimirTablaEnlaces;
    &calcularPageRankCiclo;
}

sub calcularPageRankCiclo
{
    $i = 0;
    $j = 0;
    $bandera = 1;
    foreach $doc(sort {$documentos{$a} <=> $documentos{$b} } keys %documentos)
    {
        if($doc cmp "")
        {
            $id = $documentos{$doc};
            print "Procesando documento $doc con id $id\n\n";
            while($i < $N)
            {
                if($TablaEnlaces[$i][$id] == 1)
                {
                    $bandera = 1;
                    print "[$i][$id]\n";
                    $docAux = &obtenerDocPorID($i);
                    if($docAux != -1)
                    {                        
                        $PageRankActual{$doc} += ($PageRankAnterior{$docAux} / $Ligas{$docAux});
                    }
                }
                $i++;
            }
            $i = 0;

            if($bandera) 
            {
                $PageRankActual{$doc} = 0.15 + 0.85 * $PageRankActual{$doc};
                $bandera = 0;
            }
            else
            {
                $PageRankActual{$doc} = 0.15;
            }
        }
    }
    &imprimirPageRankActual;   
}

sub obtenerDocPorID
{
    $temp = ($_[0]);

    foreach $llave(sort {$documentos{$a} <=> $documentos{$b} } keys %documentos)
    {
        if($llave cmp "")
        {
            if($documentos{$llave} eq $temp)
            {
                return $llave;
            }
        }
    }
    return 0;
}

#Inicia el PageRank de cada documento en 1
sub inicializarPageRank
{
    foreach $doc(sort {$documentos{$a} <=> $documentos{$b} } keys %documentos)
    {
        if($doc cmp "")
        {
            $PageRankAnterior{$doc} = 1;
            $PageRankActual{$doc} = 0;
        }
    }
}

sub inicializarTablaEnlaces
{
    $i = 0;
    $j = 0;

    for ($i = 0; $i < $N; $i++)
    {
        for ($j = 0; $j < $N; $j++)
        {
            $TablaEnlaces[$i][$j] = 0;
        }
    }
}

#Obtiene qui�n apunta a qui�n
sub procesarDocumentos
{
    my ($path) = "D:/Prueba";
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

#Se crea una 'tabla' de enlaces entre los documentos y se actualiza la cantidad
#de ligas de cada documento.
sub procesarEnlaces
{
    my ($path) = ($_[0]);
    # Este es el archivo que va a leer
    my $stream = HTML::TokeParser->new($path);

    my $file = $path;
    print "Enlaces de $file\n";
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
                    my $i = $documentos{$file};
                    print "[$i][$j]\n";
                    #Hay enlace entre I,J
                    if($TablaEnlaces[$i][$j] != 1)
                    {
                        $TablaEnlaces[$i][$j] = 1;
                        $Ligas{$file}++;
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
    for $i ( 0 .. $#TablaEnlaces ) 
    {
        for $j ( 0 .. $#{ $TablaEnlaces[$i] } ) 
        {
            print "$TablaEnlaces[$i][$j]";
        }
        print "\n";
    }
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

sub imprimirPageRankActual
{
    foreach $doc(sort {$PageRankActual{$b} <=> $PageRankActual{$a} } keys %PageRankActual)
    {
        print "Documento: $doc Page Rank $PageRankActual{$doc}\n";
    }
}