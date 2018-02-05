COMO VER EL TAMAÑO DE LA TABLAS DE UN ESQUEMA.

select segment_name as table_name, sum(bytes)/(1024*1024) as table_size_meg 
from user_extents 
where (segment_type='TABLE') 
group by segment_name
order by sum(bytes)/(1024*1024) desc

COMO VER EL TAMAÑO DE LOS TABLESPACE Y EL ESPACIO UTILIZADO.

SELECT tablespace_name, round(BYTES/1024/1024,0) tamaño, round(user_BYTES/1024/1024,0) tamaño_Usado
FROM dba_data_files b
WHERE tablespace_name NOT LIKE 'TEMP%'

COMO VER EL ESPACIO LIBRE DE LOS TABLESPACES DE ORACLE              

Para ver el espacio libre que queda en un tablespace tenemos que mirar en la tabla dba_free_space

SELECT tablespace_name,
ROUND(sum(bytes)/1024/1024,0)
FROM dba_free_space
WHERE tablespace_name NOT LIKE ‘TEMP%’
GROUP BY tablespace_name;

Con esta consulta obentemos el nombre del tablespace y el espacio en Megas libre

Para ver el espacio total en un tablespace tenemos que mirar en la tabla dba_data_files

SELECT tablespace_name,
round(sum(BYTES/1024/1024),0)
FROM dba_data_files b
WHERE tablespace_name NOT LIKE ‘TEMP%’
GROUP BY b.tablespace_name;

Con esta consulta obentemos el nombre del tablespace y el espacio total en Megas que puede llegar a tener

COMO ENVIAR UN CORREO EN PL/SQL
Como hemos dicho en el objetivo de este articulo, cuando el tablespace se esté quedando sin espacio libre, se recibirá un correo.
Vamos a proporcionar un procedimiento para poder enviar un correo.

CREATE OR REPLACE PROCEDURE SEND_MAIL(SENDER IN VARCHAR2, RECIPIENT IN VARCHAR2, SUBJECT IN VARCHAR2, MESSAGE IN VARCHAR2) IS
– SENDER: direccion de correo de quien envia el mail
– RECIPIENT: dirreción de correo a la que va dirigida el mail
– SUBJECT: Es el asunto del correo
– ESSAGE: es el texto del mensaje
mailhost CONSTANT VARCHAR2(30) := ‘mail.server.es’; — servidor de correo , sustituir cadena por una valida
mesg VARCHAR2(1000); — texto del mensaje
mail_conn UTL_SMTP.CONNECTION; — conexion con el servidor smtp
BEGIN
mail_conn := utl_smtp.open_connection(mailhost, 25);
mesg := ‘Date: ‘ ||
TO_CHAR( SYSDATE, ‘dd Mon yy hh24:mi:ss’ ) || CHR(13) || CHR(10) ||
‘From: <’|| Sender ||’>’ || CHR(13) || CHR(10) ||
‘Subject: ‘|| Subject || CHR(13) || CHR(10)||
‘To: ‘||Recipient || CHR(13) || CHR(10) || ” || CHR(13) || CHR(10) || Message;
utl_smtp.helo(mail_conn, mailhost);
utl_smtp.mail(mail_conn, Sender);
utl_smtp.rcpt(mail_conn, Recipient);
utl_smtp.data(mail_conn, mesg);
utl_smtp.quit(mail_conn);
EXCEPTION
WHEN OTHERS THEN
RAISE_APPLICATION_ERROR(-20004,SQLERRM);
END send_mail;

Sustituir mail.server.es por un servidor smtp valido

PROCEDIMIENTO PARA CONTROLAR EL ESPACIO LIBRE DE LOS TABLESPACES
A través de este procedimiento comprobamos que queda más de un porcentaje establecido libre en el tablespace con respecto a su espacio total
Si el espacio libre es menor al limite establecido ( portentaje ) del total del tablespace se envia un correo utilizando el procedimiento que se ha explicado en el punto anterior.

CREATE OR REPLACE PROCEDURE ALERTA_ESPACIO (limite number) IS
– CREAMOS EL CURSOR CON EL NOMBRE DE LOS TABLESPACES
– Y ESPACIO LIBRE
CURSOR c_espacio_libre IS
SELECT tablespace_name,
ROUND(sum(bytes)/1024/1024,0)
FROM dba_free_space
WHERE tablespace_name NOT LIKE ‘TEMP%’
GROUP BY tablespace_name;
– CREAMOS EL CURSOR CON EL NOMBRE DE LOS TABLESPACES
– Y ESPACIO total
CURSOR c_espacio_total IS
select tablespace_name,
round(sum(BYTES/1024/1024),0)
FROM dba_data_files b
WHERE tablespace_name NOT LIKE ‘TEMP%’
GROUP BY b.tablespace_name;
– DEFINIMOS LAS VARIABLES PARA METER EL CONTENIDO DEL CURSOR
c_nombre VARCHAR2(20);
c_libre NUMBER(10);
c_total NUMBER(10);
v_bbdd VARCHAR(20);
BEGIN
– OBTENEMOS EL NOMBRE DE LA BASE DE DATOS
SELECT name into v_bbdd from v$database;
– ABRIMOS EL CURSOR Y NOS POSICIONAMOS EN LA PRIMERA LINEA
OPEN c_espacio_libre;
OPEN c_espacio_total;
FETCH c_espacio_libre INTO c_nombre,c_libre;
FETCH c_espacio_total INTO c_nombre,c_total;
– EN CASO DE QUE EXISTA RESULTADO REALIZAMOS LAS COMPROBACIONES DE ESPACIO
WHILE c_espacio_libre%found
LOOP
– comprobacion del tablespace ES MENOR DE limite MEGAS
IF (c_libre * 100) / c_total < limite THEN
send_mail(‘dedireccion@orasite.es’,'paradirecion@orasite.es’,
‘ALERTA DE ESPACIO EN BASE DE DATOS ‘ || v_bbdd,
‘El tablespace con nombre: ‘ || c_nombre || ‘ se esta quedando sin espacio’ ||chr(10)|
‘El tamaño restante es de: ‘ || c_libre || ‘ Megas’);
END IF;
FETCH c_espacio_libre INTO c_nombre, c_libre;
FETCH c_espacio_total INTO c_nombre,c_total;
END LOOP;
CLOSE c_espacio_libre;
CLOSE c_espacio_total;
END;
/
Este procedimiento recibe un parametro, que será el porcentaje que queramos comprobar. Un valor normal sería 10, de esta forma comprobará que el espacio libre sea mayor de un 10 por ciento del tamaño total del tablespace.
En caso de que no sea mayor que ese límite puesto, se enviará un mail. Modificar las direcciones de correo, por direcciones de correo validas.

AUTOMATIZAR LA TAREA DE COMPROBACION DE TABLESPACES
Esta tarea se puede automatizar poniendo un job ( tarea ) en la base de datos y que compruebe cada x tiempo si los tablespaces se han llenado.
Si no tenemos ningún job en la base de datos, antes de poner un job tenemos que asegurarnos que el valor job_queue_processes es mayor que 0.
