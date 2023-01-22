#!/bin/sh
#
# gdal and friends windows builder.
# Autor: Javier Urien
# version: 0.9.4
# email: javierurien@suremptec.com.ar
#
# (c) 2007 SUR Emprendimientos Tecnologicos
#
# Este shell script compila (con gcc) y empaqueta (en rar o tar.bz2) el gdal
# con las diversas bibliotecas de soporte de formatos en windows para generar
# los archivos de instalacion que permitan desarrollar aplicaciones
#
# Modo de uso :
# * copiar a un directorio sin espacios y poca profundidad junto con:
#  * archivo .tar.gz del gdal
#  * archivo .tar.gz del hdf4
#  * archivo .tar.gz del hdf5
#  * archivo .tar.gz del proj.4
# * entrar al shell de MSYS (en dicho dir): sh [ ENTER ]
# * ejecutar el script: sh build-gdal.sh [ ENTER ]
#
# El programa crea los archivos de salida en el directorio de ejecucion.
#
# Changelog :
# v0.0.1 Inicial

# Imprime un mensaje
postmessage() {
	echo " * $*"
}

die () {
	postmessage "Error en ejecucion de comando, saliendo con gracia"
	exit -1
}

download_package() {
	wget "$1"
}

# recibe en $1 el directorio
# $2 recibe los parametros del configure
# $3 recibe los parametros del make
build() {
	SRC_DIR=$1
	CONFIGURE_PARAMS=$2
	MAKE_PARAMS="${MAKEFLAGS} $3"

	LASTDIR="$(pwd)"
	cd "$SRC_DIR"

	postmessage "Compilando paquete en $(pwd) con:"
	postmessage "  ./configure $CONFIGURE_PARAMS"
	postmessage "  make $MAKE_PARAMS"
	if [[ "$CONFIGURE_PARAMS" != "no-configure" ]] ; then
		if [[ "$REDIRECTION" == "" ]] ; then
			./configure $CONFIGURE_PARAMS || return 1
		else
			./configure $CONFIGURE_PARAMS 2>&1 | $REDIRECTION >/dev/null || return 1
		fi
	fi
	postmessage "make $MAKE_PARAMS"
	if [[ "$REDIRECTION" == "" ]] ; then
		make $MAKE_PARAMS || return 1
	else
		make $MAKE_PARAMS 2>&1 | $REDIRECTION >/dev/null || return 1
	fi
	cd "$LASTDIR"
}

# recibe en $1 el directorio
# $2 recibe los parametros del configure
# $3 recibe los parametros del make
build_cmake() {
	SRC_DIR=$1
	CONFIGURE_PARAMS=$2
	MAKE_PARAMS="${MAKEFLAGS} $3"

	LASTDIR="$(pwd)"
	cd "$SRC_DIR"

   postmessage "Preparando paquete con CMake"
   cmake -G "MSYS Makefiles"
   
   postmessage "Configurando paquete con CMake"
   cmake $CONFIGURE_PARAMS .

	postmessage "make $MAKE_PARAMS"
	if [[ "$REDIRECTION" == "" ]] ; then
		make $MAKE_PARAMS || return 1
	else
		make $MAKE_PARAMS 2>&1 | $REDIRECTION >/dev/null || return 1
	fi
	cd "$LASTDIR"
}

# recible el archivo en $1 y escribe en $2 el directorio de salida
# retorna valor de estado
extract() {
	extensiones=( ".tar.gz;tar;xkzf"
			".tar.bz2;tar;xkjf"
			".zip;unzip;" )
	for ((i=0;i<${#extensiones[*]};i+=1)) ; do
		extension="$(echo ${extensiones[$i]} | cut -d ';' -f 1)"
		dir_name=$(basename "$1" "$extension")
		len=${#dir_name}
		base_name="`basename "$1"`"
		base_extension=${base_name:$len}
		if [ "$base_extension" == "$extension" ] ; then
			uncompressor="$(echo ${extensiones[$i]} | cut -d ';' -f 2)"
			parameters="$(echo ${extensiones[$i]} | cut -d ';' -f 3)"
			break
		fi
	done
	DIRNAME="$dir_name"
	eval "$2=$DIRNAME"
	if [ -d $DIRNAME ] ; then
		postmessage "Directorio $DIRNAME existente, asumiendo que $1 se ha descomprimido con exito"
		return 0
	fi
	postmessage "Descomprimiendo $1 en $DIRNAME con $uncompressor"
	${uncompressor} ${parameters} "$1"
	return $?
}

# $1 el nombre de archivo
# Retorna en $2 la extension tipo del archivo comprimido
ARCHIVE_EXT=("tar.bz2" "tar.gz" "rar")
find_type(){
	FILENAM=$(basename "$1")
	BASENAME=$FILENAM
	CONTINUE=0
	index=0
	while [ $CONTINUE -eq 0 ] ; do
		BASENAME=$(basename "$FILENAM" ${ARCHIVE_EXT[${index}]})
		if [[ "$FILENAM" == "$BASENAME" ]] ; then
			index=$((index+1))
		else
			CONTINUE=1
		fi
	done
	eval "$2=${ARCHIVE_EXT[${index}]}"
}

# Borra los directorios vacios en forma recursiva
# lo hace en el directorio actual
clean_empty_dirs() {
	# iteracion para borrar los directorios vacios
	DELETED=0
	while [ $DELETED -eq 0 ] ; do
		DELETED=1
		for emptydir in $(find . -empty) ; do
			rmdir $emptydir  >/dev/null 2>/dev/null || return 1
			DELETED=0
		done
	done
}

# Comprime/Descomprime
# $1 el nombre del archivo sin extension
# $2 tipo : c comprimir, x descomprimir (compatible con tar)
# resto : parametros extra del compresor
compact() {
	FILENAME="$1"
	shift
	find_type "$FILENAME" EXTENSION
	OPERATION="$1"
	shift
	case $EXTENSION in
		tar.bz2)
			COMMAND=tar
			PARAMETERS="${OPERATION}jf"
			;;
		tar.gz)
			COMMAND=tar
			PARAMETERS="${OPERATION}zf"
			;;
		rar)
			if [ -f "$(which rar)" ] ; then
				COMMAND=rar
				if [[ $OPERATION == c ]] ; then
					PARAMETERS=a
				else
					PARAMETERS=x
				fi
			else
				COMMAND=tar
				PARAMETERS="${OPERATION}jf"
				EXTENSION=.tar.bz2
			fi
			;;
		*)
			COMMAND=tar
			PARAMETERS="${OPERATION}jf"
			EXTENSION=.tar.bz2
			;;
	esac
	$COMMAND $PARAMETERS $(dirname "$FILENAME")/$(basename "$FILENAME" "$EXTENSION")"$EXTENSION" $* >/dev/null 2>/dev/null
	return $?
}

clean_empty_dirs_from_archive() {
	postmessage "Limpiando directorios vacios de $1"
	mkdir temp
	cd temp
	compact ../"$1" x
	clean_empty_dirs
	postmessage "Creando archivo $2"
	if [[ "$(dirname $2)" == "" ]] ; then
		compact ../"$2" c "*"
	else
		compact "$2" c "*"
	fi
	cd ..
	rm -Rf temp >/dev/null 2>/dev/null
}

# $1 : directorio con todos los archivos (usualmente $PREFIX)
# $2 : directorio con lo viejo (usualmente una copia de $PREFIX
#       antes del install)
# $3 : nombre de salida del archivo
make_package() {
	LASTDIR="$(pwd)"
	cd "$1"
	COMPRESSDIR=$(basename "$1")
	cd ..
	postmessage "Buscando archivos iguales entre $1 y $2"
	echo -n "" > same_files.lst
	for reference in $(find $COMPRESSDIR/.) ; do
		if [ -f $reference ] ; then
			comparison=$2/$(echo $reference | sed "s/$COMPRESSDIR\/\.\///g")
			reference=$(echo $reference | sed 's/\.\///g')
			# si tienen el mismo tiempo de ultima modificacion
#			if [ "$(stat -c %y $reference)" == "$(stat -c %y $comparison)" ] ; then
				cmp -s "$reference" "$comparison"
				# si son iguales byte a byte
				if [ "$?" == "0" ] ; then
						echo "$reference" >> same_files.lst
				fi
#			fi
		fi
	done
	postmessage "Creando archivo temporal con los archivos diferentes"
	compact "temp-archive".tar.bz2 c "$COMPRESSDIR" -X same_files.lst
	rm same_files.lst >/dev/null 2>/dev/null
	clean_empty_dirs_from_archive "temp-archive".tar.bz2 "$LASTDIR"/"$3"
	rm "temp-archive".tar.bz2 >/dev/null 2>/dev/null
	cd "$LASTDIR"
	return 0
}

apply_patch() {
		patchlevel=0
		if [ $# -ge 3 ] ; then
			if [ $3 -ge 0 ] ; then
				patchlevel=$3
			fi
		fi
		postmessage "Aplicando Patch -Np${patchlevel} $2 < $1"
		patch -Np${patchlevel} $2 < "$1" >patch.out 2>&1
		RET=$?
		PATCH_OUTPUT=$(cat patch.out|sed s/\\*/\\\\*/g)
		rm -Rf patch.out

		if [ $RET != 0 ] ; then
			LINES_PATCH=`echo $PATCH_OUTPUT | grep -v "Reversed (or previously applied) patch detected"`
			FAILED_PATCH=`echo $PATCH_OUTPUT | grep -E "(Hunk .* FAILED|Permission denied)"`
			if [ -z "${LINES_PATCH}" ] ; then
				postmessage "Advertencia! Hubo mensajes al aplicar el patch $1."
			fi
			postmessage $PATCH_OUTPUT
			if [ -n "${FAILED_PATCH}" ] ; then
				postmessage "Error al aplicar $1"
				return 1
			fi
		fi
		return 0
}

# $1 el nombre del archivo
# $2 los flags de configure
# $3 los parametros del make
# $4 para que instale y genere el paquete
# $5 -p aplica el patch si $6 antes de build,
# $6 archivo del patch
# $7 archivo del patch
# $8 archivos a pasar a install_makepackage para que los agregue al paquete
build_library() {
	extract "$1" OUTDIR

	# Aplico patch antes de construir
	if [[ "$5" == "-p" ]] ; then
		if [ ! -z "$6" ] ; then
			apply_patch "$6" "-d $OUTDIR" || return 1
		fi
		if [ ! -z "$7" ] ; then
			apply_patch "$7" "-d $OUTDIR" || return 1
		fi
	fi

	build "$OUTDIR" "$2" "$3" || return 1
	# Se carga variable de entorno que indica la version con que generado la biblioteca
	# Se reemplace espacios, guiones y puntos por underscore para que las definiciones de variables sean validas
	SUFFIX=""
	if [ ! -z $PLATFORMID ] ; then
		SUFFIX="_${PLATFORMID}"
	fi
	echo "export $(echo "${OUTDIR}" | tr [:lower:] [:upper:] | sed -e 's/[ \.-]/_/g')_ENVIRONMENT_VERSION${SUFFIX}='${ENVIRONMENT_VERSION}'" >> $PREFIX/share/sur/build_environment.sh	
	
	echo "export $(echo "${OUTDIR}" | tr [:lower:] [:upper:] | sed -e 's/[ \.-]/_/g')_COSMETIC_ENVIRONMENT_VERSION${SUFFIX}='${COSMETIC_ENVIRONMENT_VERSION}'" >> $PREFIX/share/sur/build_environment.sh	
	
	echo "Version: $ENVIRONMENT_VERSION" >> "$OUTDIR/$OUTDIR.env"
	echo "--------------------------------------------------------------------------------------" >> "$OUTDIR/$OUTDIR.env"
	if [ -s $OUTDIR/config.log ]
	then
		cat "$OUTDIR/config.log" >> "$OUTDIR/$OUTDIR.env"
	else
		echo "make $3" >> "$OUTDIR/$OUTDIR.env"
	fi


	# Solo instala si se le pasa un cuarto parametro
	if [[ "$4" != "no-install" ]] ; then
		install_makepackage "$OUTDIR" "$4" "$8" || return 1
	fi
	return 0
}

# $1 el nombre del directorio
# $2 los parametros del make install
# $3 archivos que se deben agregar al paquete aunque existieran anteriormente, relativos a PREFIX (y sin espacios)
install_makepackage() {
	postmessage "Backupeando $PREFIX -> $PREFIX-pre-$1"
	cp $PREFIX "$PREFIX-pre-$1" -R
	FORCED_FILES="$3 share/sur/build_environment.sh"

	# agrego libwinpthread-1.dll porque al compilar con el GCC 4.8 que viene con QT 5.2.1 me obliga y no supe sacarlo
	if [ $WINDOWS ] ; then
		FORCED_FILES="${FORCED_FILES} bin/libwinpthread-1.dll bin/libgcc_s_sjlj-1.dll bin/libstdc++-6.dll"
	fi
	FORCED_FILES=`echo "$FORCED_FILES" | sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*\$//g'`
	postmessage "Bibliotecas a copiar ${FORCED_FILES}"
	declare -a copied_files
	# archivos que debo remover de prefix-pre que exist�an y que se consideren instalados
	# por este paquete
	declare -a files_to_remove_from_prefix_pre_after_install
	# Archivos que debo copiar a prefix luego de instalar para que se consideren instalados
	# por este paquete.
	declare -a files_to_copy_to_prefix_after_install
	# Archivos que se deben remover de prefix luego de generado el paquete, en ppio
	# deben ser los mismos que figuran en $files_to_copy_to_prefix_after_install
	declare -a files_to_remove_from_prefix_after_package
	if [ ! -z "${FORCED_FILES}" ] ; then
		for file in ${FORCED_FILES} ; do

			# elimino posibles whitespaces al inicio y fin del nombre del archivo.
			file=`echo $file | sed -e 's/^[[:space:]]*//g' -e 's/[[:space:]]*\$//g'`
			copied_files+=("${file}")
		
			postmessage "Forzando el agregado de $file"
			# saco which porque solo encuentra ejecutables en el path, pero find puede ser lento.
         if [ $WINDOWS ] ; then
            SOURCE_FILE="$(find "/" -name `basename $file` 2>/dev/null | head -n 1)"
         else
            SOURCE_FILE="$(find $HOME -name `basename $file` 2>/dev/null | head -n 1)"
         fi
         
			if [ ! -f "$SOURCE_FILE" -a ! -d "$SOURCE_FILE" ] ; then
				die "Archivo $SOURCE_FILE no existe"
			fi
		
			TARGET_FILE="$PREFIX/$file"
			TARGET_FILE_DIR="$PREFIX/`dirname $file`"
			PRE_FILE="$PREFIX-pre-$1/$file"

			# Si el origen y el destino son los mismos, debo eliminar el archivo de prefix_pre
			# despu�s de crear prefix pre (o despues de instalar)
			if [[ `echo "$TARGET_FILE"` == `echo "$SOURCE_FILE"` ]] ; then
				postmessage "Archivos origen y destino iguales"
				files_to_remove_from_prefix_pre_after_install+=("$PRE_FILE")
				postmessage `rm -vRf "$PRE_FILE"`
				continue
			fi
		
			# si el origen esta fuera del prefix, hay que copiarlo desde origen antes de crear 
			# el paquete, instalar o despu�s de copiar pre y luego borrar el archivo destino
			# despu�s de generado el paquete
			if [ $(find "$PREFIX" -name `basename $file` 2>/dev/null | wc -c) == 0 ] ; then
				files_to_remove_from_prefix_after_package+=("$TARGET_FILE")
				postmessage "Archivo $file no existe en $PREFIX. Se copiara."
				if [ ! -d "$TARGET_FILE_DIR" ] ; then
					mkdir -p "$TARGET_FILE_DIR"
				fi
				postmessage `cp -vR "$SOURCE_FILE" "$TARGET_FILE_DIR"`
			else
				postmessage "Archivo $file preexistente en $PREFIX. Se renovar�."
				files_to_remove_from_prefix_pre_after_install+=("$PRE_FILE")
				rm -Rf "$PRE_FILE"
			fi
		done
	fi

	LASTDIR="$(pwd)"
	cd "$1"
	postmessage "Instalando paquete con:"
	postmessage "  make install $2"
	make install $2 || return 1

	#copio archivo con version de entorno y datos de configuracion
	if [ ! -d "$PREFIX/share/sur" ]; then
		mkdir -p "$PREFIX/share/sur"
	fi
	cp "$1.env" "$PREFIX/share/sur" || return 1

	cd "$LASTDIR"

	#Armo nombre y genero el paquete
	PCKNAME="$1$PACKAGE_SUFFIX"
	if [ ! $PLATFORMID = "" ]; then
		PCKNAME="$PCKNAME-$PLATFORMID"
	fi
	PCKNAME="${PCKNAME}-gcc-${GCCVER}${PACKAGESUFFIX}.$PACKAGE_TYPE"
	make_package $PREFIX "$PREFIX-pre-$1" "$PCKNAME" || return $?
	postmessage "Paquete $PCKNAME generado con exito!"
	
	for ((i=0;i<${#files_to_remove_from_prefix_after_package[*]};i+=1)) ; do
		postmessage "Eliminando ${files_to_remove_from_prefix_after_package[$i]}"
		logmessage `rm -vRf "${files_to_remove_from_prefix_after_package[$i]}"`
	done
	
	postmessage "Borrando backup en $PREFIX-pre-$1"
	rm -Rf "$PREFIX-pre-$1"
	if [ ! -d "$PKGDIR" ] ; then
		postmessage "Creando directorio de paquetes."
		mkdir -p "$PKGDIR"
	fi
	mv "$PCKNAME" "$PKGDIR" || return 1
	return 0
}

# $1 el directorio base (debajo del cual deben estar los scrips y los archivos
#  de fuentes de las bibliotecas).
# $2 Variable de salida con el nro de version del repositorio
# $3 Variable de salida con el sufijo para los paquetes
getenvversion(){
	DIR="$1"
	if [ $WINDOWS -a ! $CROSS ] ; then
		ENVVERSION_SRC="$(subwcrev "${DIR}"/src -f | grep -E '(committed)' | cut -d ' ' -f 5)"
		ENVVERSION_SCRIPT="$(subwcrev "${DIR}"/scripts -f | grep -E '(committed)' | cut -d ' ' -f 5)"
		subwcrev "${DIR}"/src -nm > NUL
		REVSRC=$?
		subwcrev "${DIR}"/scripts -nm > NUL
		REVSCRIPT=$?
		if [ ${ENVVERSION_SRC} -gt ${ENVVERSION_SCRIPT} ] ; then
			ENVVERSION=${ENVVERSION_SRC}
		else
			ENVVERSION=${ENVVERSION_SCRIPT}
		fi
		if [ ${REVSRC} -ne 0 -o ${REVSCRIPT} -ne 0 ] ; then
			PACKAGEVALIDSUFFIX="-NoAptoParaCommit"
			postmessage "Los scripts cuentan con cambios locales, los paquetes generados no son aptos para realizar commit."
			postmessage "La compilacion de los paquetes del entorno debe realizarse sobre fuentes del repositorio."
		fi
	else
		ENVVERSION_SRC="$(svnversion -nc ${DIR}/src 2>/dev/null|cut -d : -f 2)"
		if [ "${ENVVERSION_SRC}" == "" ] ; then
			ENVVERSION_SRC="$(svnversion -nc ${DIR}/src 2>/dev/null)"
		fi
		ENVVERSION_SCRIPT="$(svnversion -nc ${DIR}/scripts 2>/dev/null|cut -d : -f 2)"
		if [ "${ENVVERSION_SCRIPT}" == "" ] ; then
			ENVVERSION_SCRIPT="$(svnversion -nc ${DIR}/scripts 2>/dev/null)"
		fi
		if [ "$(echo ${ENVVERSION_SRC} ${ENVVERSION_SCRIPT} | sed /.*[A-Z].*/s/.*/1/g)" == "1" ] ; then
			PACKAGEVALIDSUFFIX="-NoAptoParaCommit"
			postmessage "Los scripts cuentan con cambios locales, los paquetes generados no son aptos para realizar commit."
			postmessage "La compilacion de los paquetes del entorno debe realizarse sobre fuentes del repositorio."
			ENVVERSION="${ENVVERSION_SRC}:${ENVVERSION_SCRIPT}"
		else
			if [ "${ENVVERSION_SRC}" -gt "${ENVVERSION_SCRIPT}" ] ; then
				ENVVERSION=${ENVVERSION_SRC}
			else
				ENVVERSION=${ENVVERSION_SCRIPT}
			fi
		fi
	fi
	eval "$2=\"$ENVVERSION\""
	eval "$3=\"$PACKAGEVALIDSUFFIX\""
}

# Reinicializa los FLAGs del compilador
reset_flags() {
	export CFLAGS="${C_FLAGS}"
	export CXXFLAGS="${CXX_FLAGS}"
	export CPPFLAGS="${CPP_FLAGS}"
	export LDFLAGS="${LD_FLAGS}"
	export LIBS="${_LIBS}"
	if [ -z "${MAKE_PROCESSES}" ] ; then
		MAKE_PROCESSES=2
	fi
	export MAKEFLAGS="-j ${MAKE_PROCESSES}"
}

# Mueve los paquetes generados al directorio de binarios (del repositorio)
move_packages(){
	postmessage "Moviendo los paquetes binarios al directorio de repositorio."
	if [ -d ${PKGDIR} -a -d ${BINDIR} ] ; then
		for pkgfile in "${PKGDIR}/*.${PACKAGE_TYPE}" ; do
			mv ${pkgfile} ${BINDIR}
		done
	else
		postmessage "No existe alguno de los directorios de paquetes."
		return 1
	fi
}

initialize() {
	if [ "$1" == "--help" ] ; then
		echo "cross :     Usar compilacion cruzada"
		echo "debug :     Generar paquetes de debug"
		echo
		return 1;
	fi
	PKGDIR="$(pwd)/packages"
	SRCDIR="$(pwd)/../src"
	BINDIR="$(pwd)/../bin"
	if [ "$1" = "cross" ] ; then
		shift
		GCC_TARGET="i586-mingw32msvc"
		export AS=${GCC_TARGET}-as
		export NM=${GCC_TARGET}-nm
		export RANLIB=${GCC_TARGET}-ranlib
		export DLLTOOL=${GCC_TARGET}-dlltool
		export OBJDUMP=${GCC_TARGET}-objdump
		export GCC=${GCC_TARGET}-gcc
		export CC=${GCC_TARGET}-cc
		export CPP=${GCC_TARGET}-cpp
		export AR=${GCC_TARGET}-ar
		export CXX=${GCC_TARGET}-g++
		export LD=${GCC_TARGET}-ld
		export STRIP=${GCC_TARGET}-strip
		export RC=${GCC_TARGET}-windres
		export DLLWRAP=${GCC_TARGET}-dllwrap
		export WINDOWS=1
		export CROSS=1
		export PLATFORMID=Cross
		CROSS_COMMON_FLAGS="--build=i686-linux --host=${GCC_TARGET} --target=${GCC_TARGET}"
		HOST_LIBRARY_PATH="/usr/$HOST_PREFIX/lib"
		PKGDIR="${PKGDIR}-cross"
	else	# si no estoy compilando en forma cruzada, pregunto por windows y paso default a linux
		if [ "$OS" = "Windows_NT" ] ; then
			export AS=as
			export NM=nm
			export RANLIB=ranlib
			export DLLTOOL=dlltool
			export OBJDUMP=objdump
			export GCC=gcc
			export CC=${GCC}
			export CPP=cpp
			export AR=ar
			export CXX=g++
			export LD=ld
			export STRIP=strip
			export RC=windres
			export DLLWRAP=dllwrap
			export WINDOWS=1
		fi
	fi
	# Valor por defecto de GCC
	GCC=${GCC-gcc}
	GCCVER="$(${GCC}  --version|head -n1|sed 's/^.* //g')"
	GCC_TARGET="$(${GCC} -dumpmachine)"

	getenvversion "$(pwd)/.." SVNREVISION PACKAGESUFFIX
	# Mayor Number: Significa un cambio importante en los scripts (ie. nuevas funciones, refactorizacion grande)
	# Minor Number: Significa un cambio importante en las versiones de fuentes.
	# Patchlevel: Significa modificaciones menores a los scripts, nuevos patches para las fuentes.
	ENVIRONMENT_MAJOR="2"
	ENVIRONMENT_MINOR="0"
	ENVIRONMENT_PATCH_LEVEL="0"
	# Se calcula el numero de version como 10000*major + 1000*minor + patch
	ENVIRONMENT_VERSION=` echo "$(( 10000*${ENVIRONMENT_MAJOR}+1000*${ENVIRONMENT_MINOR}+${ENVIRONMENT_PATCH_LEVEL} ))" `
	COSMETIC_ENVIRONMENT_VERSION="${ENVIRONMENT_MAJOR}.${ENVIRONMENT_MINOR}.${ENVIRONMENT_PATCH_LEVEL}"
	postmessage "Version del entorno ${ENVIRONMENT_VERSION}"

	export PLATFORMID=
	export PREFIX="$HOME/opt/local"
	if [ $WINDOWS ] ; then
		export PLATFORMID=MinGW
		if [ $CROSS ] ; then
			export PLATFORMID=$PLATFORMID-cross
			apply_patch mingw-libstdcpp.patch "-d /usr/lib/gcc/${GCC_TARGET}/${GCCVER}/"
			apply_patch mingw-geos-ansi.patch "-d /usr/lib/gcc/${GCC_TARGET}/${GCCVER}/include/c++/"
			export PREFIX="${PREFIX}-${GCC_TARGET}"
		else
			apply_patch mingw-libstdcpp.patch "-d /mingw/${GCC_TARGET}/"
			apply_patch mingw-geos-ansi.patch "-d /mingw/${GCC_TARGET}/include/c++/"
			export PREFIX="/local"
		fi
	fi

	# Se genera archivo build_environment.sh que guarda las variables
	# para trazabilidad de entorno
	mkdir -p $PREFIX/share/sur/
	if [ ! -f $PREFIX/share/sur/build_environment.sh ] ; then
		echo "#!/bin/sh" > $PREFIX/share/sur/build_environment.sh
	fi
	SUFFIX=""
	if [ ! -z $PLATFORMID ] ; then
		SUFFIX="`echo _${PLATFORMID} | tr [:lower:] [:upper:]`"
	fi
	echo "export BUILD_ENVIRONMENT${SUFFIX}=${ENVIRONMENT_VERSION}" >> $PREFIX/share/sur/build_environment.sh
	echo "export BUILD_ENVIRONMENT_REVISION${SUFFIX}='${SVN_REVISION}'" >> $PREFIX/share/sur/build_environment.sh

	COMMON_FLAGS="--prefix=$PREFIX --disable-dependency-tracking $CROSS_COMMON_FLAGS"
	SHARED="--enable-shared"
	STATIC="--disable-static"
	PACKAGE_TYPE="tar.bz2"

	C_FLAGS="-pipe"
	CXX_FLAGS="-pipe"

	if [ "$1" = "debug" ] ; then
		C_FLAGS="-ggdb3 -g3 ${C_FLAGS}"
		CXX_FLAGS="-ggdb3 -g3 ${CXX_FLAGS}"
		PACKAGE_SUFFIX=d
		postmessage "Inicializando Debug"
		init_debug || die
	else
		init_release || die
	fi

	if [ $WINDOWS ] ; then
		CPP_FLAGS="-D__MINGW32__"
		# previene el linkeo dinamico contra libgcc_s_dw2-1.dll del software
		C_FLAGS="-static-libgcc ${C_FLAGS}"
		CXX_FLAGS="-static-libgcc ${CXX_FLAGS}"
		postmessage "Inicializando para Windows"
		if [ $CROSS ] ; then
			postmessage "Inicializado para compilacion cruzada"
		fi
		init_windows || die
	else
		postmessage "Inicializando para GNU/Linux"
		init_linux || die
	fi
	postmessage "Version de GCC = ${GCCVER}"
	if [ ! -d $PREFIX ] ; then
		mkdir -p $PREFIX
	fi

	export REDIRECTION=""
	if [ ! -f $PREFIX/bin/bar ] ; then
		if [ -f "bar_1.10.9.tar.gz" ] ; then
			postmessage "Creando progressbar"
			mv bar_1.10.9.tar.gz bar-1.10.9.tar.gz
			build_library "bar-1.10.9.tar.gz" "--prefix=$PREFIX"|| die
			mv bar-1.10.9.tar.gz bar_1.10.9.tar.gz
		fi
	fi
	if [ -f $PREFIX/bin/bar ] ; then
		export REDIRECTION="$PREFIX/bin/bar"
	fi
	reset_flags
}


