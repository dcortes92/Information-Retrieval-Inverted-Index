#Instrucciones:
#generar: perl proyecto1.pl stop.txt D:/man.es \.txt$ PRU
#busqueda vectorial: perl proyecto1.pl buscar vec 1 20 PRU Q1 Rank1 Resultado1 "consulta"
#mostrar pesos: perl proyecto1.pl mostrar pesos PRU_PE.txt D:/man.es/man1/addr2line.1.txt
#mostrar vocab: perl proyecto1.pl mostrar vocab PRU_VO.txt aacute abriendo

# II Tarea programada
# Recuperación de Información Textual
# Daniel Cortés Sáenz
# Isaac Ramírez Solano
# I Semestre, 2013

#Necesario para el manejo de archivos
use File::Basename;
#Necesario para raiz
use Math::Complex;
#Necesario para obtener fecha de creacion de un archivo
use File::stat;
use Time::localtime;
#Para leer todo el archivo de una vez y no línea por línea
use File::Slurp;

#Arreglo para los stopwords
@stopwords;
#Hash para los términos de un documento, usado para el archivo de frecuencias
%terminos;
#Hash para los pesos de un documento
%pesos;
#Numero de documentos
$N;
#Bandera para cuando se escribe el archivo de frecuencias o el de pesos
$bandera_accion;
#Hash para el vocabulario de la colección
%vocabulario = undef;
#Arreglo para el vocabulario de cada archivo.
@vocabulario_archivo;
#Hash para el escalafón de la similitud coseno
%hash_escalafon;
#Hash para los pesos de la consulta
%pesos_consulta;
#Hash para los pesos de un archivo
%pesos_archivo;
#Contador de la suma de la multiplicación del peso de wij * wiq
$t = 0;
#Hash para las frecuencias de los términos de la consulta
%fij_consulta;
#Arreglo que los elementos de una linea del archivo de pesos
@arreglo_linea;
#Norma de la consulta
$norma_consulta;
#Hash que tiene la cantidad de términos distintos de un archivo
%terminos_distintos_archivo;

#----------------------Variables de la línea de comandos-----------------------
#Generar
$comando;
$archivo_stopwords;
$directorio;
$patron;
$prefijo;
#Consulta
$modalidad;
$numinicio;
$numfin;
$prefijoconsulta;
$escalafon;
$archivoHTML;
$consulta;
@parametros_consulta;
#Variables para la busqueda binaria
$cantidad_contadas; #Es la cantidad de aciertos que lleva contadas en un archivo
$cantidad_a_cumplir; #Es la cantidad que debe cumplir un archivo para entrar al escalafon
%archivos_que_cumplen; #Guarda el largo en terminos de un archivo
#mostrar
$comando_mostrar;
$archivo_mostrar;
$posicion_inicial;
$posicion_final;
$archivo_pesos;
#-------------------------Fin variables-------------------------

#Calcular frecuencias
sub calcular_frecuencias
{
	$bandera_accion = 1;
	my ($dir) = ($_[0]);
	&crear_stops;
	print "Creando archivo frecuencias...\n" ;
	&open_dir($dir);
	print "Creando archivo vocabulario...\n";	
	&escribir_archivo_vocabulario;
	&escribir_N;
}

#Calcular pesos
sub calcular_pesos
{
	$bandera_accion = 0;
	my ($dir) = ($_[0]);
	print "Creando archivo pesos...\n" ;
	&open_dir($dir);
}

#Almacena en el arreglo @stopwords las palabras leídas del archivo de texto de stopwords.
sub crear_stops{
	#Ruta del archivo de texto de stopwords.
	#Se abre el archivo y se usa el file handler MYFILE
	open(MYFILE, $archivo_stopwords);
	#Mientras que MYFILE sea distinto de 0
	while (<MYFILE>){
		#Se lee la línea.
		$linea = $_;
		#Quita \n de línea.
		chomp($linea);
		#Se inserta la palabra en el arreglo.		
		push(@stopwords, $linea);
	}	
}

sub open_dir{
	my ($path) = ($_[0]);
	opendir(DIR, $path) or die("Error, No se pudo abrir el directorio\n");
	my @files = grep(!/^\./,readdir(DIR));
	closedir(DIR);
	foreach $file (@files){
		$file = $path.'/'.$file; #path absoluto del fichero o directorio
		next unless( -f $file or -d $file ); #se rechazan pipes, links, etc ..
	   	if( -d $file){
			open_dir($file,$hash);
		}else{
	   		if($file =~ /$patron/){
				#Se incrementa la variable N (Número de documentos)
				if($bandera_accion == 1){
					$N++;
				}
				&abrir_archivo($file);
	   		}
		}		
	}
}

#Abrir cada archivo de la colección
sub abrir_archivo{
	my ($path) = ($_[0]);
	open (MYFILE, $path);
	#hash que tiene los términos de cada archivo
	%terminos =  undef;
	$ultima_palabra = undef;
	$bandera = 0;
	
	while (<MYFILE>) {
		$linea = $_;
		$linea =~ tr/A-Z/a-z/;	
		$linea =~ tr/áéíóúüÁÉÍÓÚÜ/aeiouuaeiouu/;
		$linea =~ s/[\.]/ /g;
		$linea =~ s/[\;]/ /g;
		$linea =~ s/[\,]/ /g;
		$linea =~ s/[\(]/ /g;
		$linea =~ s/[\)]/ /g;
		$linea =~ s/[\[]/ /g;
		$linea =~ s/[\]]/ /g;
		$linea =~ s/[\{]/ /g;
		$linea =~ s/[\}]/ /g;
		$linea =~ s/[\:]/ /g;
		$linea =~ s/[\¡]/ /g;
		$linea =~ s/[\!]/ /g;
		$linea =~ s/[\@]/ /g;
		$linea =~ s/[\#]/ /g;
		$linea =~ s/[\$]/ /g;
		$linea =~ s/[\%]/ /g;
		$linea =~ s/[\^]/ /g;
		$linea =~ s/[\&]/ /g;
		$linea =~ s/[\*]/ /g;
		$linea =~ s/[\=]/ /g;
		$linea =~ s/[\\]/ /g;
		$linea =~ s/[\"]/ /g;
		$linea =~ s/[\¿]/ /g;
		$linea =~ s/[\?]/ /g;
		$linea =~ s/[\<]/ /g;
		$linea =~ s/[\>]/ /g;
		$linea =~ s/[\']/ /g;
		$linea =~ s/[\`]/ /g;
		$linea =~ s/[\|]/ /g;
		$linea =~ s/[\/]/ /g;
		$linea =~ s/[\+]/ /g;
		$linea =~ s/[\~]/ /g;
		
		$linea =~ s/-//g;
		
		@palabras = undef;
		$largo = 0;
		@palabras = split (' ', $linea);
		$largo = @palabras;
		
		#Para unir el resto de la palabra detectada en el renglon anterior con - al final 
		if($bandera == 1){			
			$primera_palabra = $palabras[0];
			$palabra_final = $ultima_palabra.$primera_palabra;
			if(esta($palabra_final) == 1){
				$terminos{$palabra_final}++;
			}
			$bandera = 0;
			delete @palabras[0];
		}
				
		#Para guardar la palabra con - al final del renglon que posteriormente sera unida con en resto de la palabra
		if($palabras[$largo-1] =~ m/[a-z0-9_]+­$/){	
			$palabras[$largo-1] =~ s/­//;
			$ultima_palabra = $palabras[$largo-1];		
			$bandera = 1;
			delete @palabras[$largo-1];	
		}
		
		for $word (@palabras){
			if (($word =~ m/[a-z0-9_]+/)&!($word =~ m/^[0-9]+/)){
				if(esta($word) == 1){
					$terminos{$word}++;
				}
			}
		}		
		$largo = 0;
		@palabras = undef;
	}
	close (MYFILE);
	
	$largo = scalar(keys %terminos)-1;
	@sorted = undef;
	@sorted = sort { $terminos{$a} < $terminos{$b} } keys %terminos;
	$primero = $sorted[0];
	@sorted = undef;
	
	#Frecuencias
	if($bandera_accion == 1)
	{
		open (NUEVO, '>>'.$prefijo.'_FC.txt');
		print NUEVO $path.";".fileparse($path).";".$largo.";".$terminos{$primero}.";";
			foreach $palabra (sort keys (%terminos)) {
				if($palabra cmp "")
				{
					print NUEVO "(".$palabra.",".$terminos{$palabra}.");";
				}
			}
		print NUEVO "\n";
		$largo = 0;
		close (NUEVO);
		
		#Se almacena el vocabulario de cada archivo para el hash de vocabulario de la colección
		foreach $word(sort keys (%terminos))
		{
			if($word cmp "")
			{	
				push(@vocabulario_archivo, $word);
			}		
		}	
		
		#Se actualiza el hash de vocabulario
		&actualizar_vocabulario;
	}
	else #Pesos
	{
		$norma = 0;
		foreach $pal(sort keys(%terminos))
		{
			if($pal cmp "")
			{
				$ni = $vocabulario{$pal};
				$fij = $terminos{$pal};
				if($fij > 0){
					$pesos{$pal} = ((log($fij)/log(2))+1)*(log($N/$ni)/log(2));
				}
				else
				{
					$pesos{$pal} = 0;
				}
				$norma += $pesos{$pal} ** 2;
			}			
		}
		$norma = sqrt($norma);
		open (NUEVO, '>>'.$prefijo.'_PE.txt');
		printf NUEVO $path.";".$largo.";"."%.4f;",$norma;
		foreach $palabra (sort keys (%pesos)) {
			if($palabra cmp "")
			{
				printf NUEVO "(".$palabra.",%.4f);", $pesos{$palabra};
			}
		}
		print NUEVO "\n";
		close (NUEVO);
		
	}	
	%pesos = undef;
	%terminos = undef;
	@vocabulario_archivo = undef; 
}

sub esta{
	my ($termino) = ($_[0]);
	for ($i = 0; $i < 37; $i++) {
		$elem = $stopwords[$i]."\n";
		$num = ($elem =~ /^$termino$/);
		if ($num == 1) {
			return 0;
		}
	}
	return 1;
}


#Para el par de (termino, ni) -> vocabulario de la colección
sub actualizar_vocabulario
{
	for $palabra(@vocabulario_archivo)
	{
		if($palabra cmp "")
		{
			$vocabulario{$palabra}++;
		}		
	}
}

#Escribe el archivo con el vocabulario de la colección y el ni
sub escribir_archivo_vocabulario
{
	if(%vocabulario)
	{
		open (NUEVO, '>'.$prefijo.'_VO.txt');
		foreach $pal(sort keys (%vocabulario)) {
			if($pal cmp "")
			{
				print NUEVO "(".$pal.",".$vocabulario{$pal}.")\n";
			}
		}
		close(NUEVO);
	}
	else
	{
		print "Error, vocabulario no tiene elementos\n";
	}
}

#Escribe el N para no tener que recorrer innecesariamente la colección
sub escribir_N
{
	open (N, '>'.$prefijo.'_N.txt');
		print N $N;
	close (N);
}

#Busca usando la similitud coseno.
sub busqueda_vectorial
{
	$t = @parametros_consulta;
	print "Obtieniendo los ni\n";
	&obtener_ni;
	print "Obtieniendo N\n";
	&obtener_N;	
	print "Calculando fiq\n";
	&calcular_fij_consulta;
	print "Calculando peso de la consulta\n";
	&calcular_pesos_consulta;

	print "Leyendo archivo ".$prefijo."_PE.txt\n";
	&abrir_archivo_pesos;
	
	print "Creando archivo ".$prefijoconsulta.'_'.$escalafon.".txt ...\n";
	
	#Se abre el archivo HTML
	open(ESCALAFON, '>>'.$prefijoconsulta.'_'.$archivoHTML.'.html');
		print ESCALAFON "<html><head><title>Resultados b&uacute;squeda</title></head><body>";
		print ESCALAFON "<h1>Resultados b&uacute;squeda &ldquo;".$consulta."&rdquo;</h1><hr><br>";		
	close(ESCALAFON);
	
	&escribir_archivo_escalafon;
	
	print "Creando archivo ".$prefijoconsulta.'_'.$archivoHTML.".html ...\n";
	&escribir_archivo_HTML;
	
	#Cierre del archivo HTML
	open(ESCALAFON, '>>'.$prefijoconsulta.'_'.$archivoHTML.'.html');
		print ESCALAFON "</body></html>";
	close(ESCALAFON);
	
	#Se invoca al navegador predeterminado (funciona solo en windows)
	my @command = ('start', $prefijoconsulta.'_'.$archivoHTML.'.html');
	system(@command);
}

#Se leen los ni del archivo de vocabulario
sub obtener_ni
{
	my $linea;
	my @arreglo;
	open(NIS, '<'.$prefijo."_VO.txt");
	while(<NIS>)
	{
		$linea = $_;
		chomp($linea);
		$linea =~ s/[\(]//g;
		$linea =~ s/[\)]//g;
		@arreglo = split(',', $linea);
		$vocabulario{$arreglo[0]} = $arreglo[1];
		@arreglo = undef;
	}
	close(NIS);
}

#Se lee N (tamaño de la coleccion) del archivo
sub obtener_N
{
	my $linea;
	open (N, '<'.$prefijo."_N.txt");
	while(<N>)
	{
		$linea = $_;
		chomp($linea);
		$N = $linea;
	}
	close(NIS);
}

#Para calcular las frecuencias de cada termmino en la consulta
sub calcular_fij_consulta
{
	
	for $palabra(@parametros_consulta)
	{
		$fij_consulta{$palabra}++;
	}
}

#Para obtener los datos del archivo de pesos
sub abrir_archivo_pesos
{
	my $linea;
	my @arreglo_linea;	
	
	open (PESOS, '<'.$prefijo."_PE.txt");
	while(<PESOS>)
	{
		$linea = $_;
		chomp($linea);
		@arreglo_linea = split(';', $linea);
		&calcular_peso_doci(@arreglo_linea);
		@arreglo_linea = undef;
		%pesos_archivo = undef;
	}
	close(PESOS);	
}

sub calcular_peso_doci
{
	my @arreglo = @_;
	#Ruta relativa del archivo
	$ruta_archivo = $arreglo[0];
	#Número de términos distintos del archivo, se almacena en memoria para evitar
	#abrir de nuevo el archivo de pesos para escribir el archivo HTML
	$terminos_distintos_archivo{$ruta_archivo} = $arreglo[1];
	#Norma vectorial del archivo
	$norma = $arreglo[2];
	#print "NORMA: ".$norma."\n";
	#Largo de la línea
	$largo = @arreglo;
	#Suma de multiplicacion de los pesos
	$numerador = 0;
	#Se guarda en un hash los pesos de un archivo
	for ($i = 3; $i < $largo; $i++)
	{
		$linea = $arreglo[$i];
		$linea =~ s/[\(]//g;
		$linea =~ s/[\)]//g;
		@arreglo_temp = split(",", $linea);
		$pesos_archivo{$arreglo_temp[0]} = $arreglo_temp[1];
		@arreglo_temp = undef;
	}	
	
	#Fórmula de similitud de coseno
	foreach $pal(sort keys(%pesos_consulta))
	{
		if($pal cmp "")
		{
			if($pesos_consulta{$pal} != 0)
			{
				$numerador += ($pesos_consulta{$pal} * $pesos_archivo{$pal});
			}
		}
	}
	
	#Formula de similitud de coseno, se almacena en el hash
	if($norma > 0)
	{
		$hash_escalafon{$ruta_archivo} = $numerador / ($norma * $norma_consulta);
		system("cls");
		print "Calculada similitud con archivo ".fileparse($ruta_archivo)."\n";
	}
}

sub calcular_pesos_consulta{
	#Se calculan los pesos de los wiq
	foreach $pal(sort keys(%vocabulario)) 
	{	
		if($pal cmp "")
		{
			$ni = $vocabulario{$pal};
			$fij = $fij_consulta{$pal};
			if($fij > 0){
				$pesos_consulta{$pal} = ((log($fij)/log(2))+1)*(log($N/$ni)/log(2));
				$norma_consulta += $pesos_consulta{$pal} ** 2;
			}
			else
			{
				$pesos_consulta{$pal} = 0;
			}
		}
	}
	$norma_consulta = sqrt($norma_consulta);
}

sub escribir_archivo_escalafon
{
	if(%hash_escalafon)
	{
		$contador = 1;
		open (NUEVO, '>'.$prefijoconsulta.'_'.$escalafon.'.txt');
		print NUEVO "Posición\tRuta Archivo\t\tSimilitud\n";
		#Se ordena descendentemente el hash
		foreach $pal (sort { $hash_escalafon{$b} <=> $hash_escalafon{$a} } keys %hash_escalafon) {
			if($pal cmp "")
			{
				printf NUEVO $contador.".\t".$pal."\t\t"."%.4f",$hash_escalafon{$pal};
				print NUEVO "\n";
				$contador++;
				
			}
		}
		close(NUEVO);
	}
	else
	{
		print "Error, escalafon no tiene elementos\n";
	}
}

sub escribir_archivo_HTML
{
	if(%hash_escalafon)
	{
		#Contador i para el rango del escalafon
		$i = 1;
		#Contador j para el rango del escalafon
		$j = 1;
		#Contador de posiciones en el escalafon
		$posicion;
		#Numero de lineas del archivo
		$lineas_archivo;
		#Tamaño en bytes del archivo;
		$bytes_archivo;
		#Fecha de creacion del archivo
		$fecha_creacion;
		#Número de términos distintos del archivo
		$terminos;
		#Primeros 200 caracteres del archivo.
		$prim_200_caracteres;
		
		$posicion = $i;	
		
		open(ESCALAFON, '>>'.$prefijoconsulta.'_'.$archivoHTML.'.html');
		
		foreach $pal (sort { $hash_escalafon{$b} <=> $hash_escalafon{$a} } keys %hash_escalafon) {
			if($pal cmp "")
			{
				if($i == $numinicio)
				{
					last if($j > $numfin);
					
					$lineas_archivo = &obtener_lineas_archivo($pal);
					$bytes_archivo = &obtener_bytes_archivo($pal);
					$fecha_creacion = &obtener_fecha_creacion_archivo($pal);
					if($modalidad =~ "min")
					{
							$terminos = $archivos_que_cumplen{$pal};
					}					
					else
					{
						$terminos = $terminos_distintos_archivo{$pal};
					}					
					$prim_200_caracteres = &obtener_caracteres_archivo($pal);
					
					print ESCALAFON "<table border = 1><tr><th>Pos.</th><th>Similitud</th><th>Ruta</th><th>Fecha Creci&oacute;n</th><th>Tama&ntilde;o en Bytes</th><th>N&uacute;mero de l&iacute;neas</th><th>Cantidad de palabras</th></tr>";
					print ESCALAFON "<tr><td>".$posicion.".</td><td>".$hash_escalafon{$pal}."</td><td>".$pal."</td><td>".$fecha_creacion."</td><td>".$bytes_archivo."</td><td>".$lineas_archivo."</td><td>".$terminos."</td></tr></table><br>";
					print ESCALAFON "<b>Vista preliminar del archivo:</b> <p>".$prim_200_caracteres."...</p><hr><br>";				
					$j++;
					$posicion++;
					
					$lineas_archivo = undef;
					$bytes_archivo = undef;
					$fecha_creacion = undef;
					$terminos = undef;
					$prim_200_caracteres = undef;
				}
				else
				{
					$i++;
					$j++;
				}				
			}
		}

		close(ESCALAFON);
		
	}
	else
	{
		print "Error, el escalafon no tiene elementos\n";
	}
}

#Se obtiene el número de líneas del archivo
sub obtener_lineas_archivo
{
	my ($dir) = ($_[0]);
	open(ARCHIVO, $dir);
	my @temp = <ARCHIVO>;
	close(ARCHIVO);
	$lineas_archivo = @temp;
	$lineas_archivo -= 1;
	
	return $lineas_archivo;
}

#Se obtienen el tamaño en bytes del archivo
sub obtener_bytes_archivo
{
	my ($dir) = ($_[0]);
	$bytes = -s $dir;
	
	return $bytes;
}

#Se obtiene la fecha de creación del archivo
sub obtener_fecha_creacion_archivo
{
	my ($dir) = ($_[0]);
	$fecha = ctime( stat($dir)->ctime);
	
	return $fecha;
}

#Obtiene los primeros 200 caracteres del archivo.
sub obtener_caracteres_archivo
{
	my ($dir) = ($_[0]);
	#print "Leyendo ".$dir."\n";
	my $texto = read_file($dir);
	#Reemplaza dos o más espacios por uno solo
	$texto =~ tr/  +/ /s;
	#Remplaza los cambios de línea por 3 espacios.
	$texto =~ tr/\n/   /s;
	my $texto = substr($texto, 0, 200);
	
	return $texto;
}

#---- Este metodo recibe los parametros a buscar en los archivos con la busqueda binaria ----#
sub busqueda_binaria
{	
	print "Buscando los archivos que cumplen la busqueda\n";
	&comparar_archivos_frecuencias
}

sub comparar_archivos_frecuencias
{
	open(MYFILE, $prefijo."_FC.txt");
	#Mientras que MYFILE sea distinto de 0
	while (<MYFILE>)
	{
		#Se lee la línea.
		$linea = $_;
		$linea =~ s/[\(]//g;
		$linea =~ s/[\)]//g;
		$linea =~ s/[\,]/;/g;
		@palabras_en_linea = split(';', $linea);
		$ruta_archivo = $palabras_en_linea[0]; #guarda la ruta del archivo en caso de necesitar guardarla
				
		$limite_pc = @parametros_consulta;
		$limite_pl = @palabras_en_linea;
		$frecuencia_validos;
		$frecuencia_todos;
		
		#Se inicia en 1 para evitar el primer parametro innecesario
		for($i = 1; $i < $limite_pc; $i++)
		{
			$palabra = $parametros_consulta[$i];
			#Se inicia en 4 para evitar los primeros parametros innecesarios
			for($j = 4; $j < $limite_pl; $j++)
			{
				$termino = $palabras_en_linea[$j];
				if($termino == /[0-9]+/)
				{
					$frecuencia_todos += $termino;
				}
				elsif($termino eq $palabra)
				{
					#print "entre iguales\n";
					$frecuencia_validos += $palabras_en_linea[$j+1];
					$cantidad_contadas++;
				}
			}
		}
		#Valida si cumple las condiciones para entrar en el escalafon
		if($cantidad_contadas >= $cantidad_a_cumplir)
		{
			$archivos_que_cumplen{$ruta_archivo} = $palabras_en_linea[2];
			$hash_escalafon{$ruta_archivo} = ($frecuencia_validos/log($frecuencia_todos));
			print "\t\tArchivo valido ".$ruta_archivo." ".($frecuencia_validos/log($frecuencia_todos))." \n";
		}		
		#Se reinician las variables para calcular a otros archivos
		$frecuencia_validos = 0;
		$frecuencia_todos = 0;
		$cantidad_contadas = 0;
	}
	close(MYFILE);
	#Llama la funcion que crea el escalafon y el HTML con el escalafon
	&terminar_consulta_binaria;		
}

sub terminar_consulta_binaria
{
	#Se abre el archivo HTML
	open(ESCALAFON, '>>'.$prefijoconsulta.'_'.$archivoHTML.'.html');
		print ESCALAFON "<html><head><title>Resultados b&uacute;squeda</title></head><body>";
		print ESCALAFON "<h1>Resultados b&uacute;squeda &ldquo;".$consulta."&rdquo;</h1><hr><br>";		
	close(ESCALAFON);
	
	&escribir_archivo_escalafon;
	
	print "Creando archivo ".$prefijoconsulta.'_'.$archivoHTML.".html ...\n";
	&escribir_archivo_HTML();
	
	#Cierre del archivo HTML
	open(ESCALAFON, '>>'.$prefijoconsulta.'_'.$archivoHTML.'.html');
		print ESCALAFON "</body></html>";
	close(ESCALAFON);
	
	#Se invoca al navegador predeterminado (funciona solo en windows)
	my @command = ('start', $prefijoconsulta.'_'.$archivoHTML.'.html');
	system(@command);
}

################################## Herramientas Adicionales ###############################

#muestra todos los términos entre TérminoInicial y TérminoFinal que aparecen en ArchivoVocabulario para cada término se lista su ni.
sub mostrar_vocabulario
{
	my ($dir) = ($_[0]);
	open (VOCABULARIO, '<'.$dir);
	$bandera = 0;
	print "Vocabulario, Ni\n";
	while(<VOCABULARIO>)
	{
		$linea = $_;
		$linea = $_;
		chomp($linea);
		$linea =~ s/[\(]//g;
		$linea =~ s/[\)]//g;
		@arreglo_linea = split(',', $linea);
		$palabra = $arreglo_linea[0];
		$ni = $arreglo_linea[1];
		
		#Si se encuentra la palabra inicial del rango, continúe imprimiendo.
		if($palabra eq $posicion_inicial)
		{
			$bandera = 1;
		}
		
		#Si se encuentra la palabra final del rango, imprímala y termine el ciclo	.
		if($palabra eq $posicion_final)
		{
			print $palabra.", ".$ni."\n";  
			last;
		}
		
		#Si se encontró la palabra inicial, continúe imprimiendo hasta que se encuentre el final.
		if($bandera)
		{
			print $palabra.", ".$ni."\n";
		}
		
		@arreglo_linea = undef;
	}
	close(VOCABULARIO);
}

sub mostrar_frecuencuas
{
	my ($archivo_abrir) = ($_[0]);
	my ($ruta) = ($_[1]);
	
	#print $archivo_abrir." ".$ruta."\n";
	
	open(FRECUENCIA, "<".$archivo_abrir);
	while (<FRECUENCIA>)
	{
		#Se lee la línea.
		$linea = $_;
		$linea =~ s/[\(]//g;
		$linea =~ s/[\)]//g;
		$linea =~ s/[\,]/;/g;
		@palabras_en_linea = split(';', $linea);
		$ruta_archivo = $palabras_en_linea[0];
		$limite = @palabras_en_linea;
		
		if($ruta_archivo eq $ruta)
		{
			print "\n";
			for($j = 4; $j < $limite-1; $j+=2)
			{
				$termino = $palabras_en_linea[$j];
				$frecuencia = $palabras_en_linea[$j+1];
				print $termino." --> ".$frecuencia."\n";
			}
		}
	}
	close(FRECUENCIA);
}

sub mostrar_escalafon
{
	my $texto = read_file($archivo_mostrar);
	@arreglo_escalafon = split("\n", $texto);
	$largo = @arreglo_escalafon;
	#print $largo."\n";
		#Si se encuentra la palabra inicial del rango, continúe imprimiendo.
		if($posicion_inicial > $posicion_final)
		{
			print "Error, la posicion final es menor que la inicial"
		}
		elsif($posicion_inicial > ($largo - 1) || $posicion_final > ($largo - 1))
		{
			print "Error el largo del escalafon es menor que los datos que desea mostrar"
		}
		else
		{
			for($i = $posicion_inicial; $i < $posicion_final + 1; $i++)
			{
				print $arreglo_escalafon[$i]."\n";
			}	
		}
}

sub mostrar_pesos
{
	my ($archivo_abrir) = ($_[0]);
	my ($ruta) = ($_[1]);
	$encontrado = 0;
	open(PESOS, '<'.$archivo_abrir) or die print "Archivo de pesos no encontrado\n";
	while(<PESOS>)
	{
		#Se lee la línea.
		$linea = $_;
		$linea =~ s/[\(]//g;
		$linea =~ s/[\)]//g;
		@palabras_en_linea = split(';', $linea);
		$ruta_recuperada = $palabras_en_linea[0];
		
		#Se pregunta si la ruta leída del archivo es la misma que la de que quiere el usuario
		if($ruta_recuperada eq $ruta)
		{
			$encontrado = 1;
			print "Mostrar pesos del archivo $ruta\n";
			print "Numero de terminos: ". $palabras_en_linea[1]."\n";
			print "Termino, peso:\n";
			$contador = 3;
			$largo = @palabras_en_linea;
			
			while($contador < $largo)
			{
				print $palabras_en_linea[$contador]."\n";
				$contador++;
			}
			
			last;
		}
	}
	
	close (PESOS);
	
	if($encontrado == 0)
	{
		print "Ruta no encontrada dentro del archivo de pesos\n";
	}
}

#--------------------------MAIN------------------------#
$comando = shift;
if($comando eq "generar")
{
	$archivo_stopwords = shift;
	$directorio = shift;
	$patron = shift;
	$prefijo = shift;
	
	if($archivo_stopwords eq "" or $directorio eq "" or $patron eq "" or $prefijo eq "")
	{
		print "Error, faltan parametros para generar\n";
	}
	else
	{
		&calcular_frecuencias($directorio);
		&calcular_pesos($directorio);
	}
}
elsif($comando eq "buscar")
{
	$modalidad = shift;
	$numinicio = shift;
	$numfin = shift;
	$prefijo = shift;
	$prefijoconsulta = shift;
	$escalafon = shift;
	$archivoHTML = shift;
	$consulta = shift;
	
	if($modalidad eq "" or $numinicio eq "" or $numfin eq "" or $prefijo eq "" or $prefijoconsulta eq "" or $escalafon eq "" or $archivoHTML eq "" or $consulta eq "")
	{
		print "Error, faltan parametros para buscar\n";
	}
	else
	{
		if(($numinicio <= 0 or $numfin <= 0) and ($numinicio > $numfin))
		{
			print "Error, el rango del escalafon tiene que ser positivo"
		}
		else
		{
			$consulta =~ tr/A-Z/a-z/;	
			$consulta =~ tr/áéíóúüÁÉÍÓÚÜ/aeiouuaeiouu/;
			$consulta =~ s/[\.]/ /g;
			$consulta =~ s/[\;]/ /g;
			$consulta =~ s/[\,]/ /g;
			$consulta =~ s/[\(]/ /g;
			$consulta =~ s/[\)]/ /g;
			$consulta =~ s/[\[]/ /g;
			$consulta =~ s/[\]]/ /g;
			$consulta =~ s/[\{]/ /g;
			$consulta =~ s/[\}]/ /g;
			$consulta =~ s/[\:]/ /g;
			$consulta =~ s/[\¡]/ /g;
			$consulta =~ s/[\!]/ /g;
			$consulta =~ s/[\@]/ /g;
			$consulta =~ s/[\#]/ /g;
			$consulta =~ s/[\$]/ /g;
			$consulta =~ s/[\%]/ /g;
			$consulta =~ s/[\^]/ /g;
			$consulta =~ s/[\&]/ /g;
			$consulta =~ s/[\*]/ /g;
			$consulta =~ s/[\=]/ /g;
			$consulta =~ s/[\\]/ /g;
			$consulta =~ s/[\"]/ /g;
			$consulta =~ s/[\¿]/ /g;
			$consulta =~ s/[\?]/ /g;
			$consulta =~ s/[\<]/ /g;
			$consulta =~ s/[\>]/ /g;
			$consulta =~ s/[\']/ /g;
			$consulta =~ s/[\`]/ /g;
			$consulta =~ s/[\|]/ /g;
			$consulta =~ s/[\/]/ /g;
			$consulta =~ s/[\+]/ /g;
			$consulta =~ s/[\~]/ /g;		
			$consulta =~ s/-//g;
				
			@parametros_consulta = split (' ', $consulta);
			if($parametros_consulta[0] =~ m/[0-9]+/ & $modalidad =~"min")
			{
				#Busqueda binaria
				$cantidad_a_cumplir = $parametros_consulta[0];
				$largo = @parametros_consulta;
				if($cantidad_a_cumplir > ($largo - 1))
				{
					print "Error, la cantidad a coincidir es mayor que la de terminos dados";
				}
				else
				{
					&busqueda_binaria;
				}
			}
			else
			{
				#Busqueda vectorial
				print "Búsqueda vectorial\n";
				&busqueda_vectorial
			}
		}
	}
}
elsif($comando eq "mostrar")
{
	$comando_mostrar = shift;
	if($comando_mostrar eq "vocab")
	{
		$archivo_mostrar = shift;
		$posicion_inicial = shift;
		$posicion_final = shift;
		
		if($archivo_mostrar eq "" or $posicion_inicial eq "" or $posicion_final eq "")
		{
			print "Error, faltan parametros para mostrar\n";
		}
		else
		{
			#Mostrar vocabulario
			&mostrar_vocabulario($archivo_mostrar);
		}
	}
	elsif($comando_mostrar eq "frec")
	{
		$archivo_frecuencias = shift;
		$ruta_documento = shift;
		
		if($archivo_frecuencias eq "" or $ruta_documento eq "")
		{
			print "Error, faltan parametros para mostrar\n";
		}
		else
		{
			#Mostrar frecuencias
			&mostrar_frecuencuas($archivo_frecuencias, $ruta_documento);
		}
	}
	elsif($comando_mostrar eq "esca")
	{
		$archivo_mostrar = shift;
		$posicion_inicial = shift;
		$posicion_final = shift;
		
		if($archivo_mostrar eq "" or $posicion_inicial eq "" or $posicion_final eq "")
		{
			print "Error, faltan parametros para mostrar\n";
		}
		else
		{
			#Mostrar escalafon
			&mostrar_escalafon();
		}
	}
	elsif($comando_mostrar eq "pesos")
	{
		$archivo_pesos = shift;
		$archivo_mostrar = shift;
		
		if($archivo_pesos eq "" or $archivo_mostrar eq "")
		{
			print "Error, faltan parametros para mostrar\n";
		}
		else
		{
			#mostrar pesos
			&mostrar_pesos($archivo_pesos, $archivo_mostrar);
		}
	}
	else
	{
		print "Error, comando no reconocido\n";
	}
}
else
{
	print "Error, comando no reconocido\n";
}