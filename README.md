# Manual de Generación de Entorno de Desarrollo !SuriLib

## Objetivo
Mantener actualizado el entorno de desarrollo !SuriLib

## Alcance
El mantenimiento del entorno de desarrollo de !SuriLib está orientado para máquinas pertenecientes al grupo de trabajo de desarrolladores !SuriLib. Los encargados de este mantenimiento son el mismo grupo de desarrolladores o bien, el grupo de trabajo de IT.

## Requisitos
### Instalación paquetes
Para la correcta generación del entorno es necesario tener instalados los siguietnes paquetes a nivel sistema:

 * svn+ssh >=1.4.0
 * gcc versión >= 4.8.2
 * CMake
 * MakeNSIS >=2.45
 * glib >=2.0
 * libgif
 * libjpeg
 * libpng12
 * zlib
 * libtiff-dev
 * libGL
 * libGLU
 * GTK+-2.4
 * bc
 * autotools
 * make
 * patchutils
 * libcurl
 * geotiff
 * hdf5
 * geos
 * cppcheck
 * todos (tofrodos)
 * doxygen
   * flex
   * bison
   * descomprimir y compilar doxygen 1.8.x
```shell
#!sh
./configure --prefix $HOME/.local/
make
make install
```
 * graphviz
 * cccc
 * mingw32-gcc versión >= 4.9.0
 * sun-jre 1.6
 * MakeNSIS >=2.45
 * iconv >= 2.9
 * xauth
 * unix2dos
 * unzip


Actualizo el repositorio
```shell
#!sh
sudo aptitude update
```

Actualizo la version de cmake

 * Cmake >= 2.8.1 (sudo aptitude install cmake)

NOTA: Luego de realizar la actualización de CMake, se preguntará si se desea actualizar el resto de los paquetes. Responder que "NO" ante dicha situación.

## Procedimiento

Pasos al actualizar el entorno de desarrollo:
 1. Apagar la compilación en el servidor de integración continua.
 1. Construccion paquetes binarios WIN.
 1. Construccion paquetes binarios Linux.
 1. Instalacion del nuevo entorno.
 1. Reactivar el entorno de integración continua.
 1. Probar el nuevo entorno
 1. Realizar un commit de los paquetes generados.
 1. Notificar al resto de los desarrolladores.

### Instalación variables de entorno (Opcional)

Paso obligatorio para entornos nuevos.

Configurar las variables de búsqueda en el entorno :
```shell
#!sh
echo export LD_LIBRARY_PATH=$!LD_LIBRARY_PATH:/usr/lib:$HOME/opt/local/lib >> $HOME/.build_environment
echo export PATH=$HOME/opt/local/bin:$HOME/opt/local-i686-w64-mingw32/bin:$PATH >> $HOME/.build_environment
echo export LD_LIBRARY_PATH=$HOME/opt/local-i686-w64-mingw32/lib >> $HOME/.build_environment
#echo export PATH=/bin:$HOME/opt/local-i686-w64-mingw32/bin:$HOME/opt/local-i686-w64-mingw32/bin:$HOME/opt/local-i686-w64-mingw32/include:$HOME/opt/local-i686-w64-mingw32/!lib:/usr/games:/usr/bin:/bin:$HOME/.local/bin >> $HOME/.build_environment
```

### Construcción de paquetes binarios
#### Construccion paquetes binarios WIN

 a. Entrar por escritorio remoto a la Maquina para construir binarios de entorno de Windows 
 a. Eliminar el entorno viejo `(C:/msys/1.0/local)`.
 a. Bajar los scripts y los fuentes en el nuevo entorno.
 a. Abrir consola Msys.
 a. Ir al directorio `scripts/` del nuevo entorno.
 a. Ejecutar el script de contrucción.
```shell
#!sh
bash ./build-all.sh
```
 a. Al finalizar el proceso de compilación, anotar los tiempos empleados, para luego agregarlo al reporte de cambios del entorno.

Nota: Por norma general, antes de compilar el nuevo entorno la carpeta scripts sólo debe contener archivos que estén en el repositorio. Se deben eliminar los archivos generados por compilaciones anteriores y otros archivos no pertenecientes al repositorio ya que estos pueden mezclarse con los nuevos archivos generados.

Nota: El script de build-all tarda bastante tiempo (aprox 3-4 horas). Para mantener consistencia con los tiempos guardados, se debe:
 * Desactivar el Resident Shield del AVG.
 * Ocultar la ventana del Msys (la salida por stdout lentifica significativamente el proceso).

Nota: No realizar commit de los binarios generados. Esto se hace al final, luego de probar el nuevo entorno.

#### Construcción paquetes binarios Linux

 a. Conectarse por ssh al servidor de Jenkins (`jenkins.suremptec.com.ar:22` NOTA: Solicitar `<username>` y `<password>` a un Administrador)
 a. Ir al directorio de entornos del Jenkins `(/home/builder/opt)`.
 a. Hacer backup de los entornos anteriores. Renombrar los directorios `local` y `local-i686-w64-mingw32` como `local.AAAAMMDD` y `local-i686-w64-mingw32.AAAAMMDD` respectivamente.
```shell
#!sh
mv local local.$(date +%Y%m%d)
mv local-i686-w64-mingw32 local-i686-w64-mingw32.$(date +%Y%m%d)
```
 a. Entrar al directorio que contiene el entorno `(/home/builder/environment)`
 a. Actualizar los archivos del entorno.
```shell
#!sh
svn up
```
 a. Verificar que el directorio `bin` `(/home/builder/environment/bin)` no contiene paquetes de procedimientos ejecutados anteriormente. De ser así eliminar aquellos que no estén bajo control de versiones.
 a. Entrar al directorio `scripts` `(/home/builder/environment/scripts)`
 a. Eliminar los directorios existentes de procedimientos ejecutados anteriormente (que no estén bajo control de versiones)
```
Ejemplo:
rm -r -f gdal-1.11.0
rm -r -f gmock-1.6.0
rm -r -f gtest-1.6.0
rm -r -f libkml-trunk
rm -r -f muparser_v2_2_2
rm -r -f packages
rm -r -f packages-wx
rm -r -f wxWidgets-2.8.12
```
 a. Ejecutar el script de contrucción.
```shell
#!sh
bash ./build-all.sh
```
 a. Copiar los paquetes generados en Windows:
    i. Entrar en la máquina de Windows:
    i. Abrir una consola de MS-DOS (No funciona en la consola de MSyS)

Nota: Por norma general, antes de compilar el nuevo entorno la carpeta scripts sólo debe contener archivos que estén en el repositorio. Se deben eliminar los archivos generados por compilaciones anteriores y otros archivos no pertenecientes al repositorio ya que estos pueden mezclarse con los nuevos archivos generados.


### Instalacion del nuevo entorno

 a. Entrar en la máquina de Linux.
 a. Ir al directorio de entornos del jenkins `(/home/builder/opt)`.
 a. Borrar directorios `local` y `local-i686-w64-mingw32`

#### Instalar entorno Windows

 a. Extraer todos los paquetes binarios del entorno de windows:
```shell
#!sh
for i in $(ls -1 <environment_dir>/bin/*.tar.bz2 | grep -i MinGW | grep -vi debug) ; do tar -jxvf $i ;done
```
 a. Renombrar el `local` creado a `local-i686-w64-mingw32`
 a. Ejecutar desde el directorio `local-i686-w64-mingw32/bin/` el script `wx-config-change-prefix.sh` con parámetro `<directorio/donde/se/encuentra/wx-config>`. Se deben escapar las barras de separación de directorio con `\`.
```shell
#!sh
./wx-config-change-prefix.sh "\/home\/builder\/opt\/local-i686-w64-mingw32"
```
 a. Verificar que ejecutó con éxito abriendo el archivo `wx-config` y comprobando que tenga la ruta deseada
```shell
#!sh
cat wx-config | grep builder
```
#### Instalar entorno Linux

Extraer todos los paquetes binarios del entorno de Linux:
```shell
#!sh
cd /home/builder/opt
for i in $(ls -1 <environment_dir>/bin/*.tar.bz2 | grep -vi MinGW | grep -vi debug) ; do tar -jxvf $i ;done
```
