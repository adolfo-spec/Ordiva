# Ordiva Familia · prueba independiente

La página `ordiva-familia-test.html` conserva el diseño y no modifica index.html ni ordiva-sincronizacion.html. Trabaja exclusivamente con tablas ordiva_test_*; las tareas actuales no se sobrescriben. La versión 0.2 permite copiarlas manualmente desde ordiva_data a Mi espacio con Recuperar mis datos. IDs estables por cuenta evitan duplicados y no actualizan elementos importados anteriormente. Los datos que solo existen en el almacenamiento local de otro origen no están disponibles para esta copia.

Acceso con correo y contraseña de Supabase. Las cuentas nuevas deben confirmar su correo. El servicio de correo y sus límites dependen de la configuración de Supabase.

Mi espacio contiene datos privados. En Familia, crear un espacio, seleccionarlo y añadir tareas, planes o elementos de lista. Preparar una invitación con el correo del familiar y compartir manualmente el código. El destinatario debe tener el correo confirmado e introducir el código en Familia. No se envían invitaciones automáticamente. El código es de un solo uso, caduca en siete días y está vinculado al correo.

La app consulta cambios cada cinco segundos mientras está visible y al recuperar conexión/foco. Las escrituras son por elemento; versiones evitan sobrescribir actualizaciones concurrentes. No ofrece edición sin conexión. La prueba no incluye administración o expulsión de miembros.

Validación realizada: sintaxis JavaScript; pantalla de acceso en navegador; transacción SQL con tres usuarios simulados (rollback), propietario/miembro/externo, invitación restringida por correo, aislamiento privado y actualización compartida con incremento de versión. Quedan pendientes las pruebas de correo real y dos dispositivos físicos. No se ha probado inicio de sesión con credenciales del propietario ni envío de confirmación.

Los asesores de seguridad no señalan las nuevas tablas/funciones. Detectan avisos preexistentes en funciones public.ordiva_is_member, public.ordiva_owner_membership, public.rls_auto_enable y protección de contraseñas filtradas deshabilitada. Se mantienen sin cambios para preservar el entorno actual.

No fusionar la rama ni reemplazar la versión actual hasta verificar la prueba. Eliminar el despliegue de prueba no borra sus tablas; la reversión del frontend consiste en seguir usando la URL actual.

Prueba 0.2: node test-import.cjs valida identificadores estables, deduplicación, cuentas separadas, fechas y textos inválidos y que la fuente no se modifica. La actualización periódica se pausa mientras escribes en un campo.
