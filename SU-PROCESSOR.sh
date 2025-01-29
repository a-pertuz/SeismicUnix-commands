
#!/bin/bash


echo -e "\n **SU-PROCESSOR** \n"

echo -e "Version 27-02-2024"




# Nombre del SEGY proporcionado
indata="$1"

# Archivo .frec que contiene las frecuencias y tiempos para el filtro de paso de banda
archivo_frec="filtro.txt"

# El analisis de velocidad debe tener el mismo nombre que el ST original pero con extensión .bin
modelo_vrms_2D=$indata"_vrms2D.bin"		
modelo_vint_2D=$indata"_vint2D.bin"	
modelo_vint_1D=$indata"_vint1D.txt"	

# Crear los nombres de los archivos de salida
out_su=$indata".su"

# Nombre del archivo de geometría proporcionado como argumento, extensión UTM
archivo_geometria=$indata"_utm.txt"

# Iniciamos la variable archivo_seleccionado como el .su original, luego se ira modificando
archivo_seleccionado=$out_su

# Indicamos que no se guarden carpetas de workflow
workflow=false
folder=""


# Comprobamos la creacion o existencia de varias carpetas

# Comprobar si la carpeta EPS ya existe
    if [ ! -d "FigEPS" ]; then
        # Si no existe, crear la carpeta
        mkdir -p "FigEPS"
        echo "Carpeta 'FigEPS' creada."
    else
        true
    fi

# Comprobar si la carpeta PNG ya existe

    if [ ! -d "FigPNG" ]; then
        # Si no existe, crear la carpeta
        mkdir -p "FigPNG"
        echo "Carpeta 'FigPNG' creada."
    else
        true
    fi

# Comprobar si la carpeta misc ya existe
    if [ ! -d "misc" ]; then
        # Si no existe, crear la carpeta
        mkdir -p "misc"
        echo "Carpeta 'misc' creada."
    else
        true
    fi

# Comprobar si la carpeta SEGY ya existe
    if [ ! -d "SEGY" ]; then
        # Si no existe, crear la carpeta
        mkdir -p "SEGY"
        echo "Carpeta 'SEGY' creada."
    else
        true
    fi
#
# Función para comprobar si se ha creado o no un archivo
archivo_creado(){
	local file="$1"
    if [ -s "$file" ]; then
        echo -e "\n\e[1;32mEXITO\e[m: El archivo \e[1m$file\e[m se ha creado correctamente.\n"
    else
        echo -e "\n\e[1;31mERROR\e[m: El archivo \e[1m$file\e[m está vacío.\n"
    fi
}

# Esta función permite listar los archivos disponibles en la carpeta y seleccionar el que se quiere usar.
listar_archivos(){	
	while true; do
    # Listar archivos con extensión .su en la carpeta actual
    archivos=$(ls -1 *.su 2>/dev/null)

    # Comprobar si se encontraron archivos
    if [ -n "$archivos" ]; then
        echo -e "\e[1;32mArchivos con extensión .su encontrados:\e[m\n"
        # Enumerar y mostrar los archivos
        contador=1
        for archivo in $archivos; do
            echo "$contador. $archivo"
            contador=$((contador + 1))
        done

        echo " "

        # Pedir al usuario que seleccione un archivo por su número
        read -p "Ingrese el número del archivo que desea seleccionar: " opcion

        # Verificar si la opción ingresada es válida
        if [ "$opcion" -gt 0 ] && [ "$opcion" -le "$contador" ]; then
            archivo_seleccionado=$(echo "$archivos" | sed -n "${opcion}p")
            echo -e "\nHa seleccionado el archivo: \e[1m$archivo_seleccionado\e[m \n"

            # Pedir confirmación al usuario
            read -p "Pulsa X para seleccionar otro archivo. Pulsa cualquier tecla para continuar." confirmacion
            case $confirmacion in
                [Xx]) 
                    echo -e "\nSelecciona un nuevo archivo.\n "
                    continue  ;; # Volver a solicitar la selección si el usuario no está seguro
                *) echo " " ;;
            esac
            # Si el usuario no ha seleccionado volver a solicitar el archivo (Nn), salimos del bucle
            break
            echo " "
        else
            echo -e "\e[31mOpción inválida.\e[m\n"
        fi
    else
        echo -e "\e[31mNo se encontraron archivos con extensión .su\e[m\n"
        break # Salir del bucle si no se encontraron archivos
    fi

	done
}

listar_carpeta(){	
	while true; do
    # Listar archivos con extensión .su en la carpeta actual
    selected_folder=$(ls -1 --color=never -d */)

    # Comprobar si se encontraron carpetas
    if [ -n "$selected_folder" ]; then
        echo -e "\e[1;32mCarpetas disponibles en el directorio actual:\e[m\n"
        contador=1
        for f in $selected_folder; do
            echo "$contador. $f"
            contador=$((contador + 1))
        done

        echo " "
        read -p "Ingrese el número de la carpeta que desea seleccionar: " opcion

        # Verificar si la opción ingresada es válida
        if [ "$opcion" -gt 0 ] && [ "$opcion" -le "$contador" ]; then
            folder=$(echo "$selected_folder" | sed -n "${opcion}p")
            echo -e "\nHa seleccionado la carpeta: \e[1m$folder\e[m \n"

            # Pedir confirmación al usuario
            read -p "Pulsa X para seleccionar otra carpeta. Pulsa cualquier tecla para continuar." confirmacion
            case $confirmacion in
                [Xx]) 
                    echo -e "\nSelecciona una nueva carpeta.\n "
                    continue  ;; # Volver a solicitar la selección si el usuario no está seguro
                *) echo " " ;;
            esac
            # Si el usuario no ha seleccionado volver a solicitar el archivo (Nn), salimos del bucle
            break
            echo " "
        else
            echo -e "\e[31mOpción inválida.\e[m\n"
        fi
    else
        echo -e "\e[31mNo se encontraron carpetas\e[m\n"
        break # Salir del bucle si no se encontraron archivos
    fi

	done
}

# Función para preguntar si se vuelve al menu de modulos o se sale del script
preguntar_continuar() {
    while true; do
        read -n 1 -p "Pulsa cualquier tecla para volver al menú o 'X' para salir del script: " continuar
        case $continuar in
            [xX])  # Salir del script
                echo " "
                echo -e "\n Saliendo del programa... \n"
                exit 0 ;;
			*) break ;; # Romper el bucle interno y volver al menú principal
        esac
    done
}

workflow_folder(){

    if [[ "$workflow" == true ]]; then
        fname=$(basename "$archivo_seleccionado" .su)
        folder="Job_"$fname"_$(date +"%d%m%Y-%H%M")/"
        mkdir -p "$folder"
        echo -e "Carpeta '$folder' creada.\n"
        cp "$out_su" "$folder"              # Copia el stack a la carpeta para trabajar en el mismo sitio
        wait
    else
        folder=""
    fi

}

# Esta función basada en WIGGLE2SEGY (Sopher, 2017) y calcula la distancia entre CDP ($CDP_dist)
distancia_CDP(){

    dos2unix "$archivo_geometria"           #Asegura la lectura correcta en formato unix
    echo ""

	readarray -t GFILE < "$archivo_geometria"		# Lee el archivo de geometría y almacena los datos en una matriz
	NGEOM="${#GFILE[@]}"					# Calcula el número de puntos de geometría
	declare -a GDIST						# Vector que contiene las distancias
	GDIST[0]=0								# Inicializa la primera distancia en cero

	# Calcula las distancias acumuladas
	for ((i = 1; i < NGEOM; i++)); do
   		 # Extrae las coordenadas de los puntos actuales y anteriores
   		 read -r ID_CURR X_CURR Y_CURR <<< "${GFILE[i]}"
   		 read -r ID_PREV X_PREV Y_PREV <<< "${GFILE[i-1]}"
    
   		 # Calcula la distancia euclidiana entre los puntos actuales y anteriores
   		 DIST=$(bc <<< "scale=2; sqrt((${X_CURR}-${X_PREV})^2 + (${Y_CURR}-${Y_PREV})^2)")
    
  		  # suma la distancia al acumulado
  		  GDIST[i]=$(bc <<< "scale=2; ${GDIST[i-1]} + ${DIST}")
	done

    echo "Longitud total de la linea: ${GDIST[-1]} m"

    cdpmin_cdpmax

    CDP_dist=$(bc <<< "scale=2; ${GDIST[-1]} / $cdpmax")

	echo -e "Distancia entre CDPs consecutivos: $CDP_dist m \n"    
}

# Función para extraer de las cabeceras el numero del primer y último cdp
cdpmin_cdpmax(){
    cdpmin=$(surange key=cdp < "$archivo_seleccionado" | awk 'NR==2 {print $2}')    #awk lee el output, NR coge solo la segunda linea y print $3 coge el tercer argumento
    echo -e "Primer CDP: $cdpmin"

    cdpmax=$(surange key=cdp < "$archivo_seleccionado" | awk 'NR==2 {print $3}')
    echo -e "Último CDP: $cdpmax \n"
}


## Funciones que ejecutan programas su

# Convertir todos los archivos .su a .SEGY
su2segy(){

    # Comprobar si la carpeta SEGY ya existe
    if [ ! -d "$folder""SEGY" ]; then
        # Si no existe, crear la carpeta
        mkdir -p "$folder""SEGY"
        echo "Carpeta '"$folder"SEGY' creada."
    else
        echo "La carpeta '"$folder"SEGY' ya existe."
    fi

    # Crear cabeceras con el .su original
    segyhdrs <$out_su

    # Listar archivos .su en el directorio actual y guardarlos en una variable
    archivos_su=$(ls -1 "$folder"*.su 2>/dev/null)

    # Comprobar si se encontraron archivos
    if [ -n "$archivos_su" ]; then
        echo "Archivos con extensión .su encontrados:"
        # Iterar sobre cada archivo
        contador=1
        for archivo in $archivos_su; do            
            echo -e "\n\e[0;36m$contador. Convirtiendo a SEGY el archivo $archivo\e[m"
            contador=$((contador + 1))
        
            # Cortar extensión .su del archivo
            archivo_segy=$(basename "$archivo" .su)

            # Ejecutar el comando segywrite para el archivo actual          
            segywrite tape="$folder"SEGY/"$archivo_segy".segy <$archivo            

            sleep 1
        done
    else
        echo "No se encontraron archivos con extensión .su en este directorio."
    fi

    echo -e "\n Se han convertido a .SEGY un total de $((contador - 1)) archivos .su \n"


}

# Amplitud maxima o minima de un archivo
AMPS(){
    archivo_entrada="$1"
    salida_amp_temp=$(mktemp)
    sumax   outpar=salida_amp_temp <"$folder$archivo_entrada" 
    wait
    minamp_raw=$(awk '{print  $2}' salida_amp_temp)
    maxamp_raw=$(awk '{print  $1}' salida_amp_temp)

    minamp=$(printf "%.4f" "$minamp_raw")
    maxamp=$(printf "%.4f" "$maxamp_raw")

}

# Interpolación de trazas x2 - antialias
INTERP(){
    echo -e "\n\e[1;34m» INTERPOLACIÓN DE TRAZAS (x2) \e[m \n"

    

    archivo_entrada="$1"

    cdpmax=$(surange key=cdp < "$folder$archivo_entrada" | awk 'NR==2 {print $3}')
    echo "$cdpmax"

    # Nombre del archivo de salida se añade _WHT
    out_INT=$(echo "$archivo_entrada" | sed "s/\.su/_INT.su/")

    suinterp <"$folder$out_INT" nxmax="$cdpmax" >$out_INT

    wait

    archivo_creado "$out_INT"

}

#WHITENING. Aplanar el espectro para sacar las altas frecuencias. Aumenta el ruido pero prepara el archivo para la deconvolución
WHT(){
    echo -e "\n\e[1;34m» WHITENING PARA APLANAR EL ESPECTRO \e[m \n"

    archivo_entrada="$1"

    # Nombre del archivo de salida se añade _WHT
    out_WHT=$(echo "$archivo_entrada" | sed "s/\.su/_WHT.su/")

    # Extraemos el numero de muestras, ns es necesario en el paso de suwfft
    ns=$(sugethw ns <$folder$archivo_entrada | sed 1q | sed 's/.*ns=//')
    echo -e "\nNumero de muestras por traza: $ns \n"                

	# Esta linea lee el archivo .frec, la cuarta linea debe contener el filtro de paso de banda mas amplio
	pasobanda_amplio=$(awk 'NR == 4 {print $2","$3","$4","$5}' "$archivo_frec")
	echo -e "Filtro de paso de banda: $pasobanda_amplio (Hz) \n"

    # Comienzan los algoritmos de seismic unix
	sufilter <$folder$archivo_entrada f=$pasobanda_amplio    |    # Filtrar antes de aplicar el aplanado de espectro
    suwfft w0=0.75 w1=1 w2=0.75                           |    # 0,1,0 da un espectro enteramente plano, otros parametro retienen la topografía del espectro
    suifft                                                |
    sufilter f=$pasobanda_amplio                          |    # Filtrar después de aplicar el aplanado de espectro
    suwind itmax=$((ns-1)) >"$folder$out_WHT"                   |    # Elimina las muestras extra que se crean en el proceso y lo ajusta al original    

    wait

	archivo_creado "$folder$out_WHT"			#Comprobamos si el archivo está o no vacio.
}

# DECONVOLUCIÓN F-X para reducir el ruido de alta frecuencia aleatorio y no correlativo entre trazas
FXDECON(){
    echo -e "\n\e[1;34m» DECONVOLUCIÓN F-X \e[m\n"

    archivo_entrada="$1"

    # Nombre del archivo de salida se añade _FXDECON
    out_FXDECON=$(echo "$archivo_entrada" | sed "s/\.su/_FXDECON.su/")

    fmin=18
    fmax=65
    twlen=0.3
    ntrw=40
    ntrf=4

    sufxdecon <$folder$archivo_entrada fmin=$fmin fmax=$fmax twlen=$twlen ntrw=$ntrw ntrf=$ntrf  >$folder$out_FXDECON

    echo -e "Parámetros: fmin=$fmin fmax=$fmax twlen=$twlen ntrw=$ntrw ntrf=$ntrf \n"    #Si se cambian asegurarse de modificar el echo

	wait

    archivo_creado "$folder$out_FXDECON"			#Comprobamos si el archivo está o no vacio.

}

# Deconvolución spiking o predictiva, se crea panel de correlación
DECON(){
    echo -e "\n\e[1;34m» DECONVOLUCIÓN  \e[m\n"

    archivo_entrada="$1"    

    

    echo -e "\e[0;34mPanel de autocorrelación del archivo de entrada\e[m\n"

    > /dev/tty 
    read -p "Tiempo mínimo (ej. 0.3): " auto_tmin
    echo " "

    > /dev/tty 
    read -p "Tiempo máximo (ej. 4): " auto_tmax
    echo " "

    suwind <$folder$archivo_entrada tmin=$auto_tmin tmax=$auto_tmax |
    suacor   ntout=200 sym=1 |
    suximage perc=90 cmap=hsv2 xbox=322 ybox=10 wbox=400 hbox=600 \
             label1=" Time (s)" \
             windowtitle="Autocorrelation before decon" \
             title="Autocorrelationpre decon" wclip=0 verbose=0 &

    echo -e "\e[0;34mSelección de parámetros de deconvolución:\e[m\n"

    > /dev/tty 
    read -p "Distancia predictiva (ej. 0.004): " lag
    echo " "

    > /dev/tty 
    read -p "Longitud del operador (ej. 0.040): " l_op
    echo " "

    > /dev/tty 
    read -p "Añadir ruido (ej. 0.001-0.010): " wnoise
    echo " "

    
    while true; do # Nombre del archivo de salida se añade _FXDECON y parametros segun se elija
        echo " "
        echo -e "\e[0;33m¿Escribir parámetros en el nombre de archivo? [y/n] \e[m" 
        read -p "" nombre_parametro
        echo " "

        case $nombre_parametro in

            [yY])
                out_DECON=$(echo "$archivo_entrada" | sed "s/\.su/_DECON-lag${lag}-xw${ntrw}-lop${l_op}-wn${wnoise}.su/")
                break
            ;;

            [nN])
                out_DECON=$(echo "$archivo_entrada" | sed "s/\.su/_DECON.su/")
                break
            ;;

            *)
                echo "Opción invalida"
            ;;
        esac
    done 

    # Nombre del archivo de salida se añade _FXDECON
    

    supef  <$folder$archivo_entrada minlag=$lag maxlag=$l_op \
           mincorr=$auto_tmin maxcorr=$auto_tmax pnoise=$wnoise \
           >"$folder$out_DECON"

    echo -e "\e[0;34mPanel de autocorrelación post-deconvolución\e[m\n"
    
    suwind <$folder$out_DECON tmin=$auto_tmin tmax=$auto_tmax |
    suacor   ntout=200 sym=1 |
    suximage perc=90 cmap=hsv2 xbox=322 ybox=10 wbox=400 hbox=600 \
             label1=" Time (s)" \
             windowtitle="Autocorrelation post decon" \
             title="Autocorrelation post decon" wclip=0 verbose=0 &

    archivo_creado "$folder$out_DECON"

    echo -e "\e[1;33mATENCION:\e[m Cerrar paneles de autocorrelacion. Pulsar ENTER para continuar.\n" 
    read -r
    echo ""


}

#Test de parametros de FXDECON
Test-FXDECON(){
    echo -e "\n\e[1;34m» DECONVOLUCIÓN F-X - Parameter testing \e[m\n"

    archivo_entrada="$1"

    echo -e "\e[0;34mSelección de parámetros:\e[m\n"

    > /dev/tty 
    read -p "Ventana de tiempo en segundos (ej. 0.3): " twlen
    echo " "

    > /dev/tty 
    read -p "Número de trazas en la ventana (ej. 50): " ntrw
    echo " "

    > /dev/tty 
    read -p "INúmero de trazas en el filtro (ej. 4): " ntrf
    echo " "

    > /dev/tty 
    read -p "Frecuencia minima (ej. 10): " fmin
    echo " "

    > /dev/tty 
    read -p "Frecuencia máxima (ej. 80): " fmax
    echo " "

    while true; do # Nombre del archivo de salida se añade _FXDECON y parametros segun se elija
        echo " "
        echo -e "\e[0;33m¿Escribir parámetros en el nombre de archivo? [y/n] \e[m" 
        read -p "" nombre_parametro
        echo " "

        case $nombre_parametro in

            [yY])
                out_testFXDECON=$(echo "$archivo_entrada" | sed "s/\.su/_FXDECON-tw${twlen}-xw${ntrw}-xf${ntrf}-fmin${fmin}-fmax${fmax}.su/")
                out_testRESIDUALFXDECON="RESIDUAL_$(echo "$archivo_entrada" | sed "s/\.su/_FXDECON-tw${twlen}-xw${ntrw}-xf${ntrf}.su/")"
                break
            ;;

            [nN])
                out_testFXDECON=$(echo "$archivo_entrada" | sed "s/\.su/_FXDECON.su/")
                out_testRESIDUALFXDECON="RESIDUAL_$(echo "$archivo_entrada" | sed "s/\.su/_FXDECON.su/")"
                break
            ;;

            *)
                echo "Opción invalida"
            ;;
        esac
    done    
    

    sufxdecon <$folder$archivo_entrada fmin=$fmin fmax=$fmax twlen=$twlen ntrw=$ntrw ntrf=$ntrf  >"$folder$out_testFXDECON"

    echo -e "Parametros: fmin=$fmin fmax=$fmax twlen="$twlen" ntrw="$ntrw" ntrf="$ntrf" \n"    #Si se cambian asegurarse de modificar el echo

    echo -e "$outDECON"

	wait

    archivo_creado "$folder$out_testFXDECON"			#Comprobamos si el archivo está o no vacio.

    # Creamos un panel con la diferencia entre el original y el fxdecon
    suop2 "$folder$archivo_entrada" "$folder$out_testFXDECON" op=diff >"$folder$out_testRESIDUALFXDECON"  
    wait  
    archivo_creado "$folder$out_testRESIDUALFXDECON"

    
}

# ** AGC ** Automatic Gain Control, iguala las trazas y previene ghosting
AGC(){
    echo -e "\n\e[1;34m» AUTOMATIC GAIN CONTROL \e[m\n"

    archivo_entrada="$1"

    # Hacemos llamada para introducir la ventana de ganancia
    > /dev/tty 
    read -p "Introducir la ventana de ganancia en segundos (ej. 0.5): " w_agc

    # Nombre del archivo de salida se añade _AGC-wagc (ventana de agc en ms)
    out_AGC=$(echo "$archivo_entrada" | sed "s/\.su/_AGC-${w_agc}.su/")

    sugain <$folder$archivo_entrada agc=1 wagc=$w_agc >"$folder$out_AGC"
    
    wait

    archivo_creado $folder$out_AGC			#Comprobamos si el archivo está o no vacio.
}
   
# ** FILTRO DE BANDA VARIABLE ** Aplicar filtro de banda según los tiempos y rangos originales
TVBP (){
    echo -e "\n\e[1;34m» FILTRO DE PASO DE BANDA VARIABLE \e[m\n"

    archivo_entrada="$1"

	# Extraer los tiempos de la primera columna y las frecuencias de cada fila
	tiempos_pasobanda=$(awk 'NR > 4 {print $1}' "$archivo_frec" | tr '\n' ',' | sed 's/,$//')
	f1=$(awk 'NR == 5 {print $2","$3","$4","$5}' "$archivo_frec")
	f2=$(awk 'NR == 6 {print $2","$3","$4","$5}' "$archivo_frec")
	f3=$(awk 'NR == 7 {print $2","$3","$4","$5}' "$archivo_frec")

	echo -e "Tiempos filtro paso de banda (s):"
	echo -e "$tiempos_pasobanda"
	echo " "
	echo -e "Frecuencias (Hz):"
	echo -e "$f1"
	echo -e "$f2"
	echo -e "$f3"

    out_TVBP=$(echo "$archivo_entrada" | sed "s/\.su/_TVBP.su/")

    sutvband <$folder$archivo_entrada \
                tf=$tiempos_pasobanda \
                f=$f1 f=$f2 f=$f3 \
                >"$folder$out_TVBP"

	wait

    archivo_creado "$folder$out_TVBP"			#Comprobamos si el archivo está o no vacio.
}

BP(){
    echo -e "\n\e[1;34m» FILTRO DE PASO DE BANDA CONTINUO \e[m\n"

    archivo_entrada="$1"

    # Nombre del archivo de salida se añade _WHT
    out_BP=$(echo "$archivo_entrada" | sed "s/\.su/_BP.su/")
          
	# Esta linea lee el archivo .frec, la cuarta linea debe contener el filtro de paso de banda mas amplio
	pasobanda_amplio=$(awk 'NR == 4 {print $2","$3","$4","$5}' "$archivo_frec")
	echo -e "Filtro de paso de banda: $pasobanda_amplio (Hz) \n"

    # Comienzan los algoritmos de seismic unix
	sufilter <$folder$archivo_entrada f=$pasobanda_amplio >"$folder$out_BP"

    archivo_creado "$folder$out_BP"
}


# ** MIGRACIÓN STOLT ** Migración con el método de Stolt para V=cte
STOLT(){
    echo -e "\n\e[1;34m» MIGRACIÓN POSTSTACK STOLT V-CTE (PostSTM) \e[m\n"

        archivo_entrada="$1"

        cdpmin_cdpmax # Valores del primer y último CDP

        distancia_CDP # Calcular la distancia entre CDPs consecutivos

        # Si el archivo ha sido interpolado entonces dividimos la distancia de CDPs entre 2
        if [[ $folder$archivo_entrada == *"INT"* ]]; then
            CDP_dist=$(echo "scale=2; $CDP_dist / 2" | bc)
            echo -e "El archivo de entrada ha sido interpolado. Nueva distancia entre CDPs: $CDP_dist m \n"
        fi

        # Hacemos llamada para introducir la velocidad de migración constante para Stolt
            > /dev/tty 
            read -p "Introducir la velocidad de migración en m/s (ej. 4500): " v_mig

        # Designamos el nombre del archivo de salida, desde el seleccionado antes y _STOLT-$vmig
            out_STOLT=$(echo "$archivo_entrada" | sed "s/\.su/_STOLT-${v_mig}.su/")
            
        #Ejecutamos sustolt a velocidad constante smig (stretch factor, W) es igual a 1. Se aplica taper para evitar efectos de borde.
            sustolt <$folder$archivo_entrada \
                cdpmin=$cdpmin cdpmax=$cdpmax dxcdp=$CDP_dist \
                tmig=0 vmig=$v_mig smig=1.0 lstaper=10 lbtaper=100 \
                verbose=1 >"$folder$out_STOLT"

        wait

        #Comprobamos si el archivo está o no vacio.
        archivo_creado "$folder$out_STOLT"
}

# ** MIGRACIÓN KIRCHHOFF TIEMPO Necesario un analisis de velocidad suavizado con estructura CDP|Tiempo|Vel
KIRCHHOFF(){
    echo -e "\n\e[1;34m» MIGRACIÓN POSTSTACK KIRCHHOFF (PostSTM) \e[m\n"

    archivo_entrada="$1"

	# Designamos el nombre del archivo de salida desde el seleccionado anteriormente
	out_KIR=$(echo "$archivo_entrada" | sed "s/\.su/_KIR.su/")

	echo -e "Modelo de velocidades: $modelo_vrms_2D \n"

	distancia_CDP # Calcular la distancia entre CDPs consecutivos

    # Si el archivo ha sido interpolado entonces dividimos la distancia de CDPs entre 2
    if [[ $folder$archivo_entrada == *"INT"* ]]; then
            CDP_dist=$((CDP_dist / 2))
            echo -e "El archivo de entrada ha sido interpolado. Nueva distancia entre CDPs: $CDP_dist m \n"
        fi
		
	cdpmin_cdpmax # Valores del primer y último CDP

	# Migración Kirchhoff, primero se aplica sufrac
	sufrac phasefac=0.25 <$folder$archivo_entrada |
	suktmig2d vfile=$modelo_vrms_2D dx=$CDP_dist \
	fcdpdata=$cdpmin firstcdp=$cdpmin lastcdp=$cdpmax dcdp=1 \
	verbose=1 \
	>"$folder$out_KIR" 

	wait

	#Comprobamos con si el archivo está o no vacio.
    archivo_creado "$folder$out_KIR"
}


#
#
## Mostrar imagenes
#

view_suximage(){

    echo -e "\n\e[1;34m» MOSTRAR IMAGEN \e[m\n"
    
    archivo_entrada="$1"
    sunormalize norm=balmed < "$folder$archivo_entrada"|
    sunormalize norm=rms|  
    suximage cmap=hsv4 legend=1 wbox=1000 hbox=500 perc=99 clip=10\
    title="$archivo_entrada" windowtitle="$archivo_entrada" \
    label1="TWT (s)" label2="CDP" \
    titlecolor=black labelcolor=black gridcolor=black &

    sleep 1
}


saveall_supsimage(){

    echo -e "\n\e[1;34m» ACTUALIZAR IMAGENES DE ARCHIVOS .su \e[m\n"

    if [ "$find_folder" == true ]; then
        listar_carpeta
    else
        continue
    fi
    
    # Listar archivos .su en el directorio actual y guardarlos en una variable
    archivos_su=$(ls -1 "$folder"*.su)



    if [ ! -d "$folder""FigEPS" ]; then
        # Si no existe, crear la carpeta
        mkdir -p "$folder""FigEPS"
        echo "Carpeta '"$folder"FigEPS' creada."
    else
        echo "La carpeta '"$folder"FigEPS' ya existe."
    fi

    # Comprobar si la carpeta PNG ya existe

    if [ ! -d ""$folder"FigPNG" ]; then
        # Si no existe, crear la carpeta
        mkdir -p "$folder""FigPNG"
        echo "Carpeta '"$folder"FigPNG' creada."
    else
        echo "La carpeta '"$folder"FigPNG' ya existe."
    fi


    

    echo -e "\nMapas de color disponibles:"
    echo -e "1. GRAY"
    echo -e "2. Blue-White-Red"
    echo -e "3. Black-White-Black"
    echo " "
    
    > /dev/tty 
    read -p "Indicar paleta de colores: " colormap
    echo " "

    case $colormap in

        1)
            brgb="0,0,0"
            grgb="0.5,0.5,0.5"
            wrgb="1,1,1"
        ;;

        2)
            brgb="0,0,1"
            grgb="1,1,1"
            wrgb="1,0,0"
        ;;

        3)
            brgb="0,0,0"
            grgb="1,1,1"
            wrgb="0,0,0"
        ;;
    esac


        > /dev/tty 
    read -p "Indicar clip (ej. 0.4): " clip
    echo " "

    read -p "AGC: Introducir la ventana de ganancia en segundos (ej. 0.5): " w_agc

    echo "$folder"

    cdpmax=$(surange key=cdp < "$folder$archivo_seleccionado" | awk 'NR==2 {print $3}')
    dt=$(surange key=dt < "$folder$archivo_seleccionado" | awk 'NR==2 {print $2}')
    ns=$(surange key=ns < "$folder$archivo_seleccionado" | awk 'NR==2 {print $2}')

    %width=$(echo "scale=2; $cdpmax * 0.01" | bc)
    %height=$(echo "scale=2; $dt * $ns / 1000000" | bc)

    width=2.08
    height=2.74


    echo "Ancho figura: $width in"
    echo "altura figura: $height in"
    
    # Mapa velocidad
    ns=$(sugethw ns <$folder$out_su | sed 1q | sed 's/.*ns=//')
             if [ -e "$modelo_vrms_2D" ]; then
                echo -e "\n\n\e[0;36mGuardando a EPS el archivo $modelo_vrms_2D \e[m"
                   psimage <"$modelo_vrms_2D" n1=$ns bps=24 wrgb="0.46,0.9,0.26" grgb="1,1,0.4" brgb="1,0.4,0.4  "  \
                            d1s=0.4 d2s=0.4  width=$width height=$height \
                            label1="Sample number" label2="Trace" title="Modelo de velocidad $indata" \
                            d1num=50 n1tic=5 d2num=50 n2tic=5 axeswidth=0.25  \
                            labelfont=Helvetica labelsize=6 titlefont=Helvetica titlesize=11 \
                            legend=1 units="m/s" lx=0.5 legendfont=Helvetica \
                            >"$folder"FigEPS/ModeloVelocidad"$indata".eps 

                    echo -e "\e[0;36mConvirtiendo a PNG el archivo $modelo_vrms_2D.eps \e[m"
                    convert  -background white -flatten -density 600 "$folder"FigEPS/"ModeloVelocidad"$indata".eps" \
                             -colorspace RGB "$folder"FigPNG/ModeloVelocidad"$indata".png 
             else
                    echo -e "\n\e[1;31mAVISO:\e[m El archivo del modelo de velocidad \e[1m$modelo_vrms_2D\e[m no existe."
            fi

 
    # Comprobar si se encontraron archivos
    if [ -n "$archivos_su" ]; then
        contador=1
        # Iterar sobre cada archivo
        for archivo in $archivos_su; do
            
            echo -e "\n\n\e[0;36m$contador. Guardando a EPS el archivo $archivo \e[m"
            contador=$((contador + 1))

            # Cortar extensión .su del archivo
            archivo_imagen=$(basename "$archivo" .su)

            tmp1=$(mktemp)
            salida_amp_temp=$(mktemp)

            # AGC y normalizar archivo de entrada y guardar a un archivo temporal
            sugain <"$archivo" agc=1 wagc=$w_agc |
            sunormalize norm=balmed |
            sunormalize norm=rms >"$tmp1"  

            
            # Sacamos las amplitudes max y min para poder 
            sumax   outpar=salida_amp_temp <"$tmp1" 
            wait
            minamp=$(awk '{printf "%.4f", $2}' salida_amp_temp)
            maxamp=$(awk '{printf "%.4f", $1}' salida_amp_temp)
            
            # Usar el archivo temporal y guardar a imagen
            supsimage <"$tmp1" bps=24 wrgb=$wrgb grgb=$grgb brgb=$brgb clip=$(echo "$minamp * $clip" | bc)  \
            d1s=0.4 d2s=0.4  width=$width height=$height \
            label1="Two-Way Travel Time (s)" label2="Trace" title="$archivo_imagen" \
            d1num=0.5 n1tic=5 d2num=50 n2tic=5 axeswidth=0.25  \
            labelfont=Helvetica labelsize=6 titlefont=Helvetica titlesize=11 \
            legend=0 lx=0.5 legendfont=Helvetica \
            >"$folder"FigEPS/"$archivo_imagen"-cmap"$colormap".eps  


            wait
            
            archivo_creado "$folder"FigEPS/"$archivo_imagen"-cmap"$colormap".eps

            #Conversion a .png con ghostscript
            echo -e "\e[0;36mConvirtiendo a PNG el archivo $archivo_imagen.eps \e[m"            
            convert  -background white -flatten -density 600 "$folder"FigEPS/"$archivo_imagen"-cmap"$colormap".eps \
            -colorspace gray "$folder"FigPNG/"$archivo_imagen"-cmap"$colormap".png
  
            wait

            archivo_creado "$folder"FigPNG/"$archivo_imagen"-cmap"$colormap".png

            

        done
    else
        echo "No se encontraron archivos con extensión .su en este directorio."
    fi

    echo -e "\n\e[1;32mSe han guardado a .EPS y .PNG un total de $((contador - 1)) archivos .su \e[m \n"


}



#
#
#
#
# 
# suBMENU DE PROCESOS
#

menu_procesos (){

    while true; do
    echo -e "\n\e[1;33m»» Seleccionar el proceso a ejecutar: \e[m\n"
    echo -e "\e[1m 1. \e[m Interpolación de trazas (x2)"  
    echo -e "\e[1m 2. \e[m FX Deconvolution"
    echo -e "\e[1m 3. \e[m Test FX Deconvolution"
    echo -e "\e[1m 4. \e[m Deconvolution"
    echo -e "\e[1m 5. \e[m Stolt PostStack Time Migration"
    echo -e "\e[1m 6. \e[m Kirchhoff PostStack Time Migration"
    echo -e "\e[1m 7. \e[m Spectral Whitening"
    echo -e "\e[1m 8. \e[m Time Variant Bandpass Filter"
    echo -e "\e[1m 9. \e[m Bandpass Filter"
    echo -e "\e[1m 10. \e[mAGC"
    echo -e "\e[1m R. \e[m Pulsa R para volver al menu de modulos"

    echo -e " "
    read -p "Elige un proceso: " proceso
    echo -e " "

    case    $proceso in

        1)  # Interpolacion de trazas
            listar_archivos
            INTERP "$archivo_seleccionado"
            
        ;;

        2)
            listar_archivos
            FXDECON "$archivo_seleccionado"
        ;;

        3)
            listar_archivos
            Test-FXDECON "$archivo_seleccionado"
        ;;

        4)
            listar_archivos
            DECON "$archivo_seleccionado"
        ;;

        5) # Stolt PostStack Time Migration
            listar_archivos
            STOLT "$archivo_seleccionado"
        ;;

        6) # Kirchhoff PostStack Time Migration
            listar_archivos
            KIRCHHOFF "$archivo_seleccionado"
        ;;

        7) #Whitening
            listar_archivos
            WHT "$archivo_seleccionado"
        ;;

        8)
            listar_archivos
            TVBP "$archivo_seleccionado"
        ;;

        9)
            listar_archivos
            BP "$archivo_seleccionado"
        ;;

        10)
            listar_archivos
            AGC "$archivo_seleccionado"
        ;;

        [rR])
            echo -e "Volviendo al menú de modulos... \n"
            break
        ;;

        *)
            echo -e "Opción no valida.\n"
        ;;

        esac
    done
}

#
#
#
# SELECCIONAR MODULO
#
# El programa permite seleccionar si ir directamente a mejorar un SEGY o saltar a migración etc.

while true; do
echo -e "**************************************"
echo -e "\n\e[1;32mSELECCIÓN DE MODULOS \e[m\n"
echo -e "\e[1m 0. \e[m Ayuda"
echo -e "\e[1m 1. \e[m Transformar SEGY->su"
echo -e "\e[1m 2. \e[m Ver valores de cabecera."
echo -e "\e[1m 3. \e[m Ejecutar procesos individuales."
echo -e "\e[1m 4. \e[m Workflow 01: PoSTM | Spike Decon | FX Decon | TV Bandpass Filter "
echo -e "\e[1m 5. \e[m Convertir todos los .su a .SEGY"
echo -e "\e[1m 6. \e[m Guardar todos los .su como imagen .EPS y .PNG."
echo -e "\e[1m X. \e[m Salir"
echo -e "\nNota: Los modulos son dependientes de los archivos creados en pasos anteriores. Asegurarse de transformar primero el archivo SEGY a SU (Modulo 2) antes de ejecutar los modulos 2, 3 o 4.\n"

#COMPROBACION ARCHIVOS
    # Comprobación de existencia de archivo .frec
        if [ -e "$archivo_frec" ]; then
            echo -e "\n\e[32m\u2713\e[0m El archivo .txt de filtro de frecuencias \e[1m$archivo_frec\e[m existe."
        else
            echo -e "\n\e[1;31mAVISO:\e[m El archivo .txt de filtro de frecuencias \e[1m$archivo_frec\e[m no existe."
        fi

    # Comprobación de existencia de archivo velocidad rms 2d .bin
        if [ -e "$modelo_vrms_2D" ]; then
            echo -e "\n\e[32m\u2713\e[0m El archivo .bin del modelo de velocidad 2D RMS \e[1m$modelo_vrms_2D\e[m existe."
        else
            echo -e "\n\e[1;31mAVISO:\e[m El archivo .bin del modelo de velocidad 2D RMS \e[1m$modelo_vrms_2D\e[m no existe."
        fi

    # Comprobación de existencia de archivo velocidad vint 2d .bin
        if [ -e "$modelo_vint_2D" ]; then
            echo -e "\n\e[32m\u2713\e[0m El archivo .bin del modelo de velocidad 2D INT \e[1m$modelo_vint_2D\e[m existe."
        else
            echo -e "\n\e[1;31mAVISO:\e[m El archivo .bin del modelo de velocidad 2D INT \e[1m$modelo_vint_2D\e[m no existe."
        fi

    # Comprobación de existencia de archivo velocidad vint 1d .txt
        if [ -e "$modelo_vint_1D" ]; then
            echo -e "\n\e[32m\u2713\e[0m El archivo .txt del modelo de velocidad 1D INT \e[1m$modelo_vint_1D\e[m existe."
        else
            echo -e "\n\e[1;31mAVISO:\e[m El archivo .txt del modelo de velocidad 1D INT \e[1m$modelo_vint_1D\e[m no existe."
        fi

    # Comprobación de existencia de archivo .txt
        if [ -e "$archivo_geometria" ]; then
            echo -e "\n\e[32m\u2713\e[0m El archivo .txt de geometria \e[1m$archivo_geometria\e[m existe."
        else
            echo -e "\n\e[1;31mAVISO:\e[m El archivo .txt de geometría \e[1m$archivo_geometria\e[m no existe."
        fi
#

#
# Aqui se selecciona el modulo al que entrar
> /dev/tty 
echo " "
read -p "Especifica el modulo que quieres ejecutar: " opcion

case $opcion in

0)  # Archivo ayuda
	echo -e "1. Convierte un archivo .SEGY en un archivo .su que es compatible con Seismic Unix. \n"

    echo -e "2. Muestra valores de cabecera del archivo .su original. \n"

    echo -e "3. Automatiza la mejora del stack original aplicando whitening, deconvolución F-X, control de ganancia automático y un filtro de paso variable en el tiempo. El orden del flujo de trabajo se basa en pruebas iterativas. \n"

    echo -e "4. Migración por STOLT en el dominio de tiempo. Velocidad constante. Se define al ejecutar el modulo. \n"

    echo -e "5. Migración poststack por Kirchhoff en el dominio de tiempo. Necesita de un modelo de velocidad .bin tal que X=nºCDP, Y=tiempo, z=velocidad \n"

    echo -e "Solución de errores:"

    echo -e "   'command bc not found' -> solución -> sudo apt install bc \n"
    
    
    
    preguntar_continuar

;;

1)
# ** CONVERSIÓN SEGY -> su ** Primero convertimos el SEGY de entrada en un archivo su - compatible con Seismic Unix
    echo -e "\n\e[1;34m» CONVERSIÓN .SEGY -> .su \e[m\n"

    segyread tape=$indata.segy | segyclean >$out_su

    wait

    #Comprobamos con -s si el archivo está o no vacio.
    archivo_creado "$out_su"

	preguntar_continuar
;;


2)
# ** VALORES DE LAS CABECERAS ** Revisar los valores de las cabeceras del archivo .su
    echo -e "\n\e[1;34m» REVISAR VALORES DE LAS CABECERAS \e[m\n"

    surange <$out_su

    ns=$(sugethw ns <$out_su | sed 1q | sed 's/.*ns=//')
    echo -e "\nNúmero de muestras por traza: \e[1m$ns\e[m \n"                #ns es necesario en el paso de whitening

    cdpmin_cdpmax

    distancia_CDP

	preguntar_continuar
    
;;

3)  # Menu de procesados individuales
    menu_procesos
    preguntar_continuar
;;

4)
# Automatiza la mejora del stack original aplicando whitening, deconvolución F-X, control de ganancia automático y un filtro de paso variable.   
    # La salida de cada función es la entrada de la siguiente

    echo -e "\n\e[1;34m» Workflow 01: PoSTM | Spike Decon | FX Decon | TV Bandpass Filter \e[m\n"

    
    listar_archivos

    workflow=true

    workflow_folder

    log_flow=$folder"workflow01_$(date +"%d%m-%H%M").txt"
    
    {
        echo "FLUJO DE TRABAJO" 
        echo "Linea: $archivo_seleccionado" 
        echo ""
    } >$log_flow
    

    echo -e "\n\e[0;34mSeleccionar método de migración: \e[m\n"
    echo -e "1. Stolt - Velocidad constante"
    echo -e "2. Kirchhoff - Modelo de velocidad"

    > /dev/tty 
    echo " "
    read -p "Método: " opcion_migracion

    case $opcion_migracion in
        1) 
            STOLT "$archivo_seleccionado"
            out_mig=$out_STOLT
            {
                echo "# Migración PoSTM por método de Stolt"
                echo "Velocidad de migración: $v_mig m/s"
                echo""
            } >>$log_flow
        ;;

        2)
            KIRCHHOFF "$archivo_seleccionado"
            out_mig=$out_KIR
            {
                echo "# Migración PoSTM por método de Kirchhoff"
                echo "Modelo de velocidad: $modelo_vrms_2D"
                echo ""
            } >>$log_flow
        ;;
    esac

    
       
    DECON "$out_mig"   
        {
            echo "# Deconvolucion de pico (Spike Deconvolution)"
            echo "Distancia predictiva: $lag s"
            echo "Longitud del operador: $l_op s"
            echo "Ruido añadido: $wnoise %"
            echo ""
        }  >>$log_flow   

        

    Test-FXDECON "$out_DECON"
        {
            echo "# Deconvolución F-X"
            echo "Ventana de tiempo: $twlen s"
            echo "Número de trazas en la ventana: $ntrw"
            echo "Número de trazas en el filtro: $ntrf"
            echo "Frecuencia mínima: $fmin Hz"
            echo "Frecuencia máxima: $fmax Hz"
            echo ""
        }  >>$log_flow  

        

    BP "$out_testFXDECON"
        {
            echo "# Filtro variable de paso de banda" 
            echo "Tiempos filtro paso de banda (s): $tiempos_pasobanda"
            echo "Frecuencias (Hz):"
            echo "$f1"
            echo "$f2"
            echo "$f3"
            echo ""
        }   >>$log_flow 

        
    while true; do
    > /dev/tty 
    echo " "
    
    echo -e "\e[0;34m¿Convertir archivos .su a .segy? [y/n] \e[m] " 
    read -p "" opcion_segy

    
    case $opcion_segy in
        [yY])  
            su2segy
            wait   
            {
            echo "# Archivos guardados como .segy" 
            }   >>$log_flow   
            break            
        ;;

        [nN])
            break
        ;;

        *)
            echo "Opción inválida. Por favor, responde 'y' o 'n'."
        ;;

    esac
    done
    
    while true; do
    > /dev/tty 
    echo " "
    echo -e "\e[0;34m¿Guardar archivos como imagen EPS y PNG? [y/n] \e[m" 
    read -p "" opcion_guardar

    case $opcion_guardar in
        [yY])  
            find_folder=false
            saveall_supsimage
            wait  
            {
            echo "# Archivos guardados como imagenes EPS y PNG" 
            }   >>$log_flow    
            break       
        ;;

        [nN])
            break
        ;;

        *)
            echo "Opción inválida. Por favor, responde 'y' o 'n'."
        ;;

    esac
    done

    workflow=false

    preguntar_continuar

;;


5)
# Conversion de todos los archivos .su del directorio a archivos .segy en un subdirectorio SEGY/
    su2segy
    preguntar_continuar
;;



6) # Guardar todos los su como imagenes eps y png en carpetas separadas
    find_folder=false
    saveall_supsimage
    preguntar_continuar
;;

7) #tests

minamp=0
sumax   outpar=misc/minamp  <RI85_01_WLP.su 
wait
minamp=$(awk '{print $2}' misc/minamp)
echo -e "heys $minamp aa"
;;


[xX])
    echo -e "\n Saliendo del programa... \n"
    exit 0
;;


*) 
    echo -e "\n Opcion no valida \n"
    continue
;;

esac

done
