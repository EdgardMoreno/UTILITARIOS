#! /bin/sh
#########################################################################################################
# Creado por         :    Erick Gutierrez Talledo                                                       #
# Descripcion        :    Extracion de Trafico de Datos - Integrada 01                                  #
# Parametros         :    Fecha de Extraccion (AñoMesDia - YYYYMMDD)                                    #
# Fecha Creacion     :    05/07/2016                                                                    #
# Modificado por     :                                                                                  #
# Fecha Modificacion :                                                                                  #
# Observaciones      :    Ninguno.                                                                      #
#########################################################################################################

## PRIMERA PARTE SOLO ES DECLARATIVA

export ORACLE_HOME=/u01/app/oracle/product/12.1.0.2/dbhome_1
export PATH=$PATH:$ORACLE_HOME/bin
. /DBFS/DESA/REGULATORIO/config.ini
# Variables de trabajo
VERSION="osi_icc_dat_101_extrae_int1"
CURRENT_DATE=`date +%Y%m%d_%H%M%S`
LOG_NAME=${DIR_LOG}/${VERSION}"_"${CURRENT_DATE}.log
logproceso=${DIR_LOG}/${VERSION}"_"${CURRENT_DATE}.log
#*****     Usuario de UNIX     *****#
WHO_UNIX=`whoami`
# Parametros de Entrada
FECHA=$1
# Funciones
fn_ejecuta(){
RETVAL=`sqlplus -s ${BD_USER}/${BD_PASS}@${BD_INST} @${DIR_SQL}/${VERSION}.sql ${FECHA}  <<-EOF>> ${LOG_NAME}
        whenever sqlerror exit sql.sqlcode;
		EOF`
}
fEcho(){
  echo "["`date +%H:%M:%S`"] $1"
  echo "["`date +%H:%M:%S`"] $1" >> $logproceso
}


## A PARTIR DE ESTA SEGUNDA PARTE SE EJECUTA E INVOCA OBJETOS DE LA PRIMERA PARTE

fEcho " ================================================================== "
fEcho " Proceso : ${VERSION} "
fEcho " ================================================================== " 
fEcho " USR Unix    = ${WHO_UNIX}" 
fEcho " HORA DE INICIO = `date`"
fEcho " "
fEcho " Ingresado Parametro Periodo (AAAAMMDD) =  ${FECHA}"
fEcho " . Ejecutando ..."
fn_ejecuta 
VERIFICA=`cat ${LOG_NAME}`
error=`echo "${VERIFICA}" | grep -i "ORA-"  | wc -l`
if [ $error -gt 0 ]; then
  fEcho " . Error en la ejecucion, por favor revisar el log ==> '${LOG_NAME}'."
  exit 1
else
  fEcho " . La ejecucion Finalizo OK. ==> log '${LOG_NAME}'"
fi
fEcho " ================================================================== " 
fEcho " HORA DE FIN = `date`"
fEcho " ================================================================== " 