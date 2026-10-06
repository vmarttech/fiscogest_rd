/// Textos legales - alineados con https://vmarttech.github.io/fiscogest-legal/
library;

const kUrlPrivacidad = 'https://vmarttech.github.io/fiscogest-legal/privacidad.html';
const kUrlTerminos = 'https://vmarttech.github.io/fiscogest-legal/terminos.html';

const kPrivacidadResumen = '''
Politica de privacidad - FiscoGest RD
Actualizado: 5 de octubre de 2026

1. Quien es el responsable
MartTech (distribuidor de FiscoGest RD). Esta politica describe el tratamiento de datos
relacionado con el uso del software, no las politicas internas de cada comercio frente a sus clientes finales.

2. Que es FiscoGest RD
Es una aplicacion de punto de venta y gestion comercial instalada en el dispositivo o equipo
del usuario (telefono, tablet o computadora). Cada instalacion tiene sus propios usuarios locales
(por ejemplo administrador o cajero).

3. Que datos se registran
- Datos del negocio que usted introduce: productos, precios, clientes del comercio, ventas,
  deudas (fiao), gastos, configuracion de empresa, etc.
- Cuentas de acceso locales: nombre de usuario, rol, hash de contraseña (no guardamos la
  contraseña en texto legible), pregunta de recuperacion si la configura.
- Datos tecnicos de licencia: plan activo, vigencia, limites de uso e informacion necesaria
  para validar la instalacion.
- Preferencias del dispositivo: por ejemplo recordatorio de usuario o uso de biometria, si usted lo activa.

Los datos de clientes del comercio (nombre, telefono, deudas, etc.) los introduce y controla
el propio comercio. FiscoGest solo los almacena en la instalacion para que el comercio pueda operar.
El comercio es responsable frente a esos clientes.

4. Donde se guardan
Por defecto, los datos operativos se almacenan de forma local en el dispositivo (base de datos
en el equipo). MartTech no opera, en la version actual descrita aqui, una nube obligatoria que
copie automaticamente todo el historial de ventas a servidores propios.

Si en el futuro se ofrece sincronizacion en la nube, se informara y se actualizara esta politica
antes o al activar esa funcion.

5. Para que se usan
- Prestar el servicio de software de gestion y punto de venta.
- Controlar la licencia de uso del programa (plan, limites, activacion).
- Permitir recuperacion de acceso cuando el usuario configuro pregunta de seguridad.

No vendemos bases de datos de comercios a terceros con fines publicitarios.

6. Pagos (dos cosas distintas)
- Cobros del comercio a sus clientes: efectivo, transferencia, fiao u otros metodos que el
  comercio registre. FiscoGest no procesa esas tarjetas ni esas transferencias; solo registra
  la operacion si el usuario la anota.
- Pago de la licencia del software: puede hacerse segun el canal de distribucion: activacion
  con codigo, medios indicados fuera de tiendas de aplicaciones, o el sistema de facturacion
  de Google Play / Galaxy Store cuando esa funcion este habilitada en el build de tienda.

7. Con quien se comparten
No se venden datos personales de la instalacion a anunciantes. Puede haber encargados tecnicos
estrictamente necesarios (por ejemplo, infraestructura de actualizacion de la app o de la tienda
de aplicaciones). Las tiendas (Google / Samsung) tratan datos segun sus propias politicas cuando
descarga o compra desde ellas.

8. Conservacion y borrado
- Los datos locales permanecen mientras la app este instalada y el usuario no los borre.
- Desinstalar la aplicacion elimina en la practica los datos locales de ese dispositivo.
- Puede solicitar orientacion de soporte MartTech para ejercer derechos aplicables.

9. Seguridad
Las contraseñas se almacenan mediante hash. El acceso queda bajo control de quienes tengan
usuario en esa instalacion. Usted debe proteger el dispositivo y no compartir claves de administrador.

10. Menores
El producto esta pensado para uso empresarial / comercial. No esta dirigido a menores de edad
como usuarios finales del software.

11. Contacto
Canal de soporte publicado con el producto (MartTech).

12. Cambios
Si cambia de forma relevante el tratamiento de datos, actualizaremos este documento y la
fecha de actualizacion.
''';

const kTerminosResumen = '''
Terminos de uso - FiscoGest RD
Licencia de software FiscoGest RD · Actualizado: 5 de octubre de 2026

1. Objeto
Estos terminos regulan el uso de FiscoGest RD como software de punto de venta y gestion
comercial, y la licencia de uso del programa.

No regulan el contrato de venta entre el comercio y sus clientes, ni convierten a MartTech
en parte de esas operaciones.

2. Licencia
Se otorga una licencia de uso no exclusiva y limitada, segun el plan activo (por ejemplo
demo, gratuito con limites, simplificado, basico, profesional, empresa u otros que se ofrezcan).
Los limites de productos, ventas, fiao, dispositivos o modulos se aplican segun ese plan.

3. Cuentas y acceso
Los usuarios (administrador, cajero, vendedor, etc.) son locales a cada instalacion.
Quien administra el sistema es responsable de crear usuarios, asignar roles y custodiar las credenciales.

4. Obligaciones del usuario
- Usar el software conforme a la ley aplicable en su jurisdiccion.
- Responder por la veracidad de la informacion comercial y fiscal que registre.
- No intentar eludir limites de licencia de forma ilegitima.
- Mantener copias de seguridad si necesita conservar historicos fuera del dispositivo.

5. Propiedad intelectual
El software, marca y documentacion de FiscoGest RD pertenecen a sus titulares. La licencia
no transfiere la propiedad del codigo ni autoriza su redistribucion no permitida.

6. Pagos de la licencia del software
- Distribucion directa / fuera de tiendas: medios indicados por el proveedor y activacion
  por codigo o confirmacion.
- Google Play / Galaxy Store: si el build de tienda ofrece compras o suscripciones in-app,
  se rigen por las reglas de esa tienda.

El registro de ventas y cobros del comercio a sus clientes es independiente del pago de la licencia.

7. Disponibilidad y limitacion de responsabilidad
El software se ofrece "tal cual", con actualizaciones razonables. No se garantiza un resultado
de negocio concreto ni el funcionamiento en equipos no soportados o modificados.

En la medida permitida por la ley, MartTech no responde por lucros cesantes, perdida de datos
por fallo del dispositivo del usuario, o decisiones comerciales tomadas con base en la informacion
registrada en el sistema.

8. Plan vencido o limites
Al vencer un plan de pago o al alcanzar limites del plan gratuito, la aplicacion puede
continuar en modo restringido o solicitar activacion / renovacion, segun las reglas del producto.

9. Terminacion
Puede dejar de usar el software desinstalando la aplicacion. El proveedor puede restringir
el uso ante incumplimiento grave de estos terminos o de la licencia.

10. Contacto
Soporte: canal publicado con el producto (MartTech).
''';
