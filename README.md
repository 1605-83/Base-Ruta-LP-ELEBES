# Base ruta LP - ELEBES OCTUBRE 2026

Mapa de clientes de los 24 vendedores de LP-ELEBES, agrupados por día de visita (lunes a viernes), con un color por vendedor.

**Ver el mapa:** https://1605-83.github.io/Base-Ruta-LP-ELEBES/

- Pestañas de lunes a viernes con todos los vendedores de cada día.
- Clic en un vendedor para ver solo sus clientes; casillas para mostrar u ocultar.
- Ubicaciones revisadas y corregidas según la dirección de cada cliente. Los puntos con borde rojo tienen la dirección incompleta y hay que confirmarla.

Fondo de calles: datos © colaboradores de OpenStreetMap (ODbL).

## Actualización automática

Todos los días a las 13:30 (hora argentina) el robot (`robot/actualizar.pl`) lee los clientes activos de la base de Gescom:

- **Altas:** el cliente nuevo aparece en el mapa. Si su coordenada es dudosa (genérica, fuera del área o lejos de su ruta) se ubica según la dirección.
- **Bajas:** el cliente inactivo desaparece del mapa.
- **Cambios** de vendedor, día, dirección o coordenada se aplican; las correcciones de ubicación ya hechas se conservan mientras la dirección no cambie.

Para correrlo a mano: pestaña **Actions → Actualizar mapa desde Gescom → Run workflow**.
