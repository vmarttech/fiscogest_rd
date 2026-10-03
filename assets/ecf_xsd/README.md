# Esquemas XSD e-CF (DGII)

Coloca aquí los XSD oficiales del paquete de especificación e-CF de la DGII.

Archivo principal esperado (ajusta el nombre si tu paquete difiere):
  - ECF_v1.0.xsd  (o el root schema que indique la circular vigente)

También puedes apuntar en Configuración e-CF a una ruta absoluta
fuera del proyecto (recomendado en producción).

Sin XSD configurado:
  - Se aplica validación estructural interna (reglas FiscoGest).
Con XSD + xmllint (libxml2-utils):
  - Validación formal contra el esquema antes de firmar.
