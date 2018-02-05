#!/usr/bin/sh

# ***********************************************************
# *                                                         *
# *  Proceso de ejecucion de los store procedure            *
# *  Del proceso DMART_CARGADIARIA                          *
# *                                                         *
# ***********************************************************
#----------VARIABLES MODIFICABLES EN CADA SP ---------------
SPN=CC01
SPNAME=CCAC_TIEMPORESOLUCION

#----------VARIABLES COMUNES A TODOS LOS SP's----------------
SPLOG="sp$SPN/sp_$SPN.log"
ARCHIVO_TMP=/tmp/spt_$SPN.tmp
PASSWD=operador/maximus
DBI=DMART_LM
DBESQUEMA=DMARTSYS
touch $ARCHIVO_TMP
WORKDIR=/scripts/CARGA_DIARIA_SP/
N=1

#--------- Inicio del Script que lanza SP_$SPN ---------------
>$WORKDIR$SPLOG
echo " "
echo "Inicio del proceso $SPNAME `date "+%c"` "
if sqlplus -s <<EOF >$ARCHIVO_TMP 2>&1
   $PASSWD@$DBI
   set serveroutput on
   set echo on
   whenever sqlerror exit failure
   whenever oserror exit failure
   exec $DBESQUEMA.$SPNAME;
   commit;
   exit
EOF
then
     cat $ARCHIVO_TMP >> $WORKDIR$SPLOG
     echo "El proceso termino correctamente"
     VARIABLE=OK
     rm $ARCHIVO_TMP
else
     cat $ARCHIVO_TMP >> $WORKDIR$SPLOG
     echo "El proceso tuvo errores... revisar"
     VARIABLE=ERROR
     $WORKDIR"sp$SPN/verifica_sp_$SPN.pl" $VARIABLE
     rm $ARCHIVO_TMP
fi


echo "------- Fin del proceso $SPN  `date "+%c"`   --------------------------"
echo " "
