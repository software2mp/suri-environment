#!/bin/sh
#

source build-func.sh

init_wx() {
	STDCONFIGURE_FLAGS="--with-opengl --enable-html \
	--with-libpng=sys --with-libjpeg=sys --with-libtiff=sys \
	--with-zlib=sys --with-expat=sys"
}

init_debug() {
	init_wx
}

init_release() {
	init_wx
}

init_windows() {
	TOOLKIT=msw
	export LD_FLAGS="${LD_FLAGS} -L$PREFIX/lib"
	export CPP_FLAGS="${CPP_FLAGS} -I$PREFIX/include"
	EXTRAFLAGS="--enable-official-build --disable-threads"
}

init_linux() {
	export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
	export LDFLAGS="${LD_FLAGS} -L$PREFIX/lib -L/usr/lib"
	export CPP_FLAGS="${CPP_FLAGS} -I$PREFIX/include -Wno-narrowing"
	TOOLKIT="gtk=2"
	EXTRAFLAGS=""
}

# solo me interesan dinamicas, pero tengo la opcion para estaticas
WXDIRBUILDDIR=(	"dynamic-release"			\
					"dynamic-debug")
WXBUILDCOUNT=${#WXDIRBUILDDIR[*]}

INIT=("" "debug" "" "debug" "" "debug" "" "debug")


WXCONFIGUREFLAGS=("--enable-shared --disable-debug"	\
		"--enable-shared --enable-debug --enable-debug_gdb"	\
		"--enable-shared --enable-debug --enable-debug_gdb --enable-unicode"	\
		"--enable-shared --disable-debug --enable-unicode")


WXMINVERSION=2.8
WXVERSION="${WXMINVERSION}.12"

WXPATCHES=("wxWidgets-${WXMINVERSION}-no-mingw-warn.patch"				\
				"wxWidgets-${WXMINVERSION}-wxVListBox-GetItemRect.patch"\
				"wxWidgets-${WXMINVERSION}-install-prefix-script.patch" \
				"wxWidgets-${WXMINVERSION}-qtmingw-4.8-_mkdir.patch"    \
				"wxWidgets-${WXMINVERSION}-configure-GL-libraries-path.patch")
WXPATCHESCOUNT=${#WXPATCHES[*]}

initialize $* || die
PKGDIR="${PKGDIR}-wx"
extract "${SRCDIR}/wxWidgets-$WXVERSION.tar.bz2" WXDIR || die

for ((i=0;i<$WXPATCHESCOUNT;i+=1)); do
	apply_patch "${WXPATCHES[${i}]}" "-d $WXDIR"  || die
done

cd $WXDIR
postmessage "Creando directorio limpio de instalacion"
cp "$PREFIX" "$PREFIX-clean" -R

for ((loop=0;loop<$WXBUILDCOUNT;loop+=1)); do
	i=$loop
	postmessage "Compilando wx ${WXDIRBUILDDIR[${i}]}"
	BUILD_DIR="$WXDIR-${WXDIRBUILDDIR[${i}]}"
	if [ ! -d "$BUILD_DIR" ] ; then
		mkdir -p "$BUILD_DIR"
	fi
	init_wx "${INIT[${i}]}"
	if [ ! -d "$PKGDIR" ] ; then
		mkdir -p "$PKGDIR"
	fi
	PACKAGE_SUFFIX=""
	rm -f "$BUILD_DIR"/configure
	ln configure "$BUILD_DIR"/configure || die
	echo "${WXCONFIGUREFLAGS[${i}]}"
	echo "build" "$BUILD_DIR" "--with-$TOOLKIT $EXTRAFLAGS $COMMON_FLAGS $STDCONFIGURE_FLAGS ${WXCONFIGUREFLAGS[${i}]}"
	build "$BUILD_DIR" "--with-$TOOLKIT $EXTRAFLAGS $COMMON_FLAGS $STDCONFIGURE_FLAGS ${WXCONFIGUREFLAGS[${i}]}" || die
	
	# Se carga variable de entorno que indica la version con que generado la biblioteca
	# Se reemplace espacios, guiones y puntos por underscore para que las definiciones de variables sean validas
	SUFFIX=""
	if [ ! -z $PLATFORMID ] ; then
		SUFFIX="_${PLATFORMID}"
	fi
	
	echo "export $(echo "${BUILD_DIR}" | tr [:lower:] [:upper:] | sed -e 's/[ \.-]/_/g')_ENVIRONMENT_VERSION${SUFFIX}='${ENVIRONMENT_VERSION}'" >> $PREFIX/share/sur/build_environment.sh	
	echo "export $(echo "${BUILD_DIR}" | tr [:lower:] [:upper:] | sed -e 's/[ \.-]/_/g')_COSMETIC_ENVIRONMENT_VERSION${SUFFIX}='${COSMETIC_ENVIRONMENT_VERSION}'" >> $PREFIX/share/sur/build_environment.sh	
	echo "Version: $ENVIRONMENT_VERSION" >> "$BUILD_DIR/$BUILD_DIR.env"
	echo "--------------------------------------------------------------------------------------" >> "$BUILD_DIR/$BUILD_DIR.env"
	if [ -s $BUILD_DIR/config.log ]
	then
		cat "$BUILD_DIR/config.log" >> "$BUILD_DIR/$BUILD_DIR.env"
	else
		echo "make" >> "$BUILD_DIR/$BUILD_DIR.env"
	fi
	# Genera un script que permite cambiar el prefijo de instalacion del wx-config.
	# Se debe utilizar al instalar en el servidor de Integracion Continua para
	# modificar la ruta que reporta al sistema CMAKE.
	# Modo de uso: Al instalar en el server IC, ejecutar wx-config-change-prefix.sh desde el
	# directorio en el que se encuentra el script wx-config (usualmente $PREFIX/bin)
	# con parametro <directorio_de_instalacion> (escapando las barras / con \/).
	# Ejemplo:
	#    cd $HOME/opt/local && bash wx-config-change-prefix.sh "$HOME\/opt\/local"
	# Para mayor detalle consultar la documentacion en el trac: 
	# http://trac.suremptec.com.ar/trac/Suri/wiki/EntornoWxParaWindows
	echo -e '#!/bin/bash
# Cambia el prefijo de wx-config.sh para que busque en otro directorio (util para el server CI, ejecutar con parametro \$HOME/opt/local/local-mingw32msvc)
echo "No olvidar escapar las /s de directorios!"
echo "Ejemplo : wx-config-change-prefix.sh \"\/home\/builder\/opt\/local-mingw32msvc\""
WXHOME="$1"
mv wx-config wx-config_original_prefix
cat wx-config_original_prefix | sed s/prefix=\${input_option_prefix-\${this_prefix:-.*}}/prefix=\${input_option_prefix-\${this_prefix:-${WXHOME}}}/ > wx-config.tmp && mv wx-config.tmp wx-config || mv wx-config_original_prefix wx-config
chmod a+x wx-config' > "${BUILD_DIR}/wx-config-change-prefix.sh"
	install_makepackage "$BUILD_DIR" || die
	postmessage "Eliminando build-dir(ahorra espacio)"
	rm -Rf "$BUILD_DIR"
	postmessage "Eliminando directorio de instalacion sucio"
	rm $PREFIX -Rf
	postmessage "Copiando directorio limpio de instalacion"
	cp $PREFIX-clean $PREFIX -R
done

postmessage "Eliminando directorio limpio de instalacion"
rm $PREFIX-clean -Rf

cd ..

#El script deja los binarios generados en la carpeta bin
move_packages
