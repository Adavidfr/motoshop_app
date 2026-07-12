<div align="center">

<img src="https://ute.edu.ec/wp-content/uploads/2021/08/LogoUteTrans.png" alt="UTE - Escuela de Tecnologías" width="250"/>

</div>

<hr>
<br>

<div style="border-left: 4px solid #1e88e5; padding-left: 15px; margin-top: 20px;">

<p><strong>Universidad Tecnológica Equinoccial</strong></p>

<p><strong>Escuela de Tecnologías</strong></p>

<p><strong>Carrera:</strong> Desarrollo de Software</p>

<p><strong>Asignatura:</strong> Programación IV - Seminario de Integración</p>

</div>

<br>

<p><strong>Tema:</strong> Proyecto Móvil en Flutter + Consumo de API Django</p>

<p><strong>Fecha:</strong> 12/07/2026</p>

<p><strong>Presentado por:</strong></p>

<ul>
  <li>Alquinga Carlos</li>
  <li>Zambrano Andrés</li>
  <li>Estévez Melanie</li>
  <li>Frías David</li>
</ul>

<p><strong>Docente:</strong> Francisco Javier Higuera González</p>

<br>

<h1 align="center">Venta de Motos - Aplicación Móvil</h1>
<br>
<div style="border-left: 4px solid #1d5c20; padding-left: 15px; margin-top: 20px;">


<h2>Descripción del Proyecto</h2>

<p>
Aplicación móvil desarrollada en Flutter para consumir la API REST del sistema de venta de motos, permitiendo el acceso público y la administración del sistema mediante autenticación y control de roles.
</p>

</div>

<br>

<div style="border-left: 4px solid #43a047; padding-left: 15px; margin-top: 20px;">

<h2>Objetivo General</h2>

<p>
Implementar una aplicación móvil en Flutter integrada con una API Django REST Framework para gestionar los módulos del sistema mediante operaciones CRUD y autenticación segura.
</p>

</div>

<br>

<div style="border-left: 4px solid #fb8c00; padding-left: 15px; margin-top: 20px;">

<h2>Tecnologías Utilizadas</h2>

<table>
  <tr>
    <th>Tecnología</th>
    <th>Uso dentro del proyecto</th>
  </tr>
  <tr>
    <td>Flutter</td>
    <td>Desarrollo de la aplicación móvil.</td>
  </tr>
  <tr>
    <td>Dart</td>
    <td>Lenguaje principal del frontend móvil.</td>
  </tr>
  <tr>
    <td>Dio</td>
    <td>Consumo de los endpoints de la API REST.</td>
  </tr>
  <tr>
    <td>Riverpod</td>
    <td>Gestión de estados y dependencias.</td>
  </tr>
  <tr>
    <td>GoRouter</td>
    <td>Navegación y protección de rutas.</td>
  </tr>
  <tr>
    <td>Flutter Secure Storage</td>
    <td>Almacenamiento seguro del token.</td>
  </tr>
  <tr>
    <td>Django REST Framework</td>
    <td>Backend y servicios REST.</td>
  </tr>
  <tr>
    <td>PostgreSQL</td>
    <td>Base de datos relacional del sistema.</td>
  </tr>
  <tr>
    <td>JWT</td>
    <td>Autenticación y autorización.</td>
  </tr>
</table>

</div>

<br>

<div style="border-left: 4px solid #7a39ab; padding-left: 15px; margin-top: 20px;">

<h2>Arquitectura del Proyecto</h2>

<p>
La aplicación utiliza una arquitectura limpia por capas, permitiendo separar la interfaz, la lógica de negocio, el acceso a datos y la comunicación con la API REST.
</p>

<h3>Estructura principal</h3>

<pre>
lib/
├── main.dart
├── core/
│   ├── config/
│   ├── error/
│   └── utils/
├── data/
│   ├── remote/
│   ├── local/
│   └── repository/
├── domain/
│   ├── model/
│   └── repository/
├── presentation/
│   ├── navigation/
│   ├── screens/
│   ├── providers/
│   └── widgets/
└── theme/
</pre>

<h3>Flujo de comunicación</h3>

<pre>
Interfaz Flutter
       │
       ▼
Providers con Riverpod
       │
       ▼
Repositorios
       │
       ▼
Datasources y Dio
       │
       ▼
API REST Django
       │
       ▼
Base de datos PostgreSQL
</pre>

<p>
Esta organización facilita el mantenimiento del proyecto, la reutilización de componentes y la incorporación de nuevos módulos sin afectar directamente otras capas de la aplicación.
</p>

</div>


<br>

<div style="border-left: 4px solid #00897b; padding-left: 15px; margin-top: 20px;">

<h2>Sección Pública</h2>

<ul>
  <li>Pantalla principal.</li>
  <li>Catálogo público de motos.</li>
  <li>Catálogo de repuestos.</li>
  <li>Detalle de productos.</li>
  <li>Información de servicios.</li>
  <li>Acceso a inicio de sesión.</li>
</ul>

</div>

<br>

<div style="border-left: 4px solid #4527a0; padding-left: 15px; margin-top: 20px;">

<h2>Autenticación y Gestión de Sesión</h2>

<p>
La aplicación implementa autenticación mediante <strong>JSON Web Token (JWT)</strong>. El usuario inicia sesión consumiendo la API de Django y el token recibido se almacena de forma segura utilizando <strong>Flutter Secure Storage</strong>, permitiendo acceder a los módulos protegidos.
</p>

<h3>Endpoint de autenticación</h3>

<pre>
POST /api/auth/login/
</pre>

<h3>Cabecera utilizada en las peticiones protegidas</h3>

<pre>
Authorization: Bearer TOKEN_DE_ACCESO
</pre>

<h3>Flujo de autenticación</h3>

<pre>
Usuario
    │
    ▼
Pantalla Login
    │
    ▼
API Django REST
    │
    ▼
Respuesta JWT
    │
    ▼
Flutter Secure Storage
    │
    ▼
Peticiones autenticadas mediante Dio
</pre>

<h3>Características implementadas</h3>

<ul>
  <li>Inicio de sesión mediante credenciales.</li>
  <li>Almacenamiento seguro del token JWT.</li>
  <li>Persistencia de la sesión del usuario.</li>
  <li>Adjunta automáticamente el token en cada petición HTTP.</li>
  <li>Manejo de respuestas 401 (Unauthorized).</li>
  <li>Cierre de sesión y eliminación del token almacenado.</li>
  <li>Protección de pantallas privadas mediante GoRouter.</li>
</ul>

</div>


<br>

<div style="border-left: 4px solid #ad1457; padding-left: 15px; margin-top: 20px;">

<h2>Roles y Permisos</h2>

<table>
  <tr>
    <th>Rol</th>
    <th>Permisos principales</th>
  </tr>
  <tr>
    <td>Administrador</td>
    <td>Puede listar, crear, editar y eliminar registros.</td>
  </tr>
  <tr>
    <td>Editor</td>
    <td>Puede crear y editar información.</td>
  </tr>
  <tr>
    <td>Operador</td>
    <td>Puede consultar registros y cambiar estados.</td>
  </tr>
  <tr>
    <td>Cliente</td>
    <td>Puede consultar el catálogo y sus operaciones personales.</td>
  </tr>
</table>

<p>
Las opciones del menú, botones y acciones se muestran u ocultan según el rol recibido desde la API.
</p>

</div>

<br>

<div style="border-left: 4px solid #1565c0; padding-left: 15px; margin-top: 20px;">

<h2>Módulos del Sistema</h2>

<h3>Catálogo e Inventario</h3>

<ul>
  <li>Marcas.</li>
  <li>Categorías de motos.</li>
  <li>Motos.</li>
  <li>Repuestos.</li>
  <li>Movimientos de inventario.</li>
</ul>

<h3>Abastecimiento y Taller</h3>

<ul>
  <li>Proveedores.</li>
  <li>Compras.</li>
  <li>Servicios.</li>
  <li>Mantenimientos.</li>
  <li>Repuestos utilizados en mantenimientos.</li>
</ul>

<h3>Ventas</h3>

<ul>
  <li>Perfiles de clientes.</li>
  <li>Carrito de compras.</li>
  <li>Ítems del carrito.</li>
  <li>Pedidos.</li>
  <li>Ventas.</li>
  <li>Financiamientos.</li>
</ul>

<h3>Financiero, Legal y Sistema</h3>

<ul>
  <li>Pagos.</li>
  <li>Facturas.</li>
  <li>Garantías.</li>
  <li>Seguros.</li>
  <li>Notificaciones.</li>
  <li>Documentos de venta.</li>
  <li>Historial de estados.</li>
  <li>Devoluciones.</li>
</ul>

</div>

<br>

<div style="border-left: 4px solid #c62828; padding-left: 15px; margin-top: 20px;">

<h2>Consumo de la API REST</h2>

<p>
La aplicación móvil consume los servicios REST desarrollados con Django REST Framework mediante la librería <strong>Dio</strong>. Las operaciones CRUD se realizan sobre los diferentes módulos del sistema utilizando peticiones HTTP autenticadas con JWT.
</p>

<h3>Operaciones HTTP soportadas</h3>

<pre>
GET     Obtener información
POST    Crear registros
PUT     Actualizar registros
PATCH   Actualización parcial
DELETE  Eliminar registros
</pre>

<h3>Principales endpoints consumidos</h3>

<table>
  <tr>
    <th>Módulo</th>
    <th>Endpoint</th>
  </tr>
  <tr>
    <td>Autenticación</td>
    <td>/api/auth/login/</td>
  </tr>
  <tr>
    <td>Marcas</td>
    <td>/api/marcas/</td>
  </tr>
  <tr>
    <td>Categorías</td>
    <td>/api/categorias/</td>
  </tr>
  <tr>
    <td>Motos</td>
    <td>/api/motos/</td>
  </tr>
  <tr>
    <td>Repuestos</td>
    <td>/api/repuestos/</td>
  </tr>
  <tr>
    <td>Proveedores</td>
    <td>/api/proveedores/</td>
  </tr>
  <tr>
    <td>Compras</td>
    <td>/api/compras/</td>
  </tr>
  <tr>
    <td>Servicios</td>
    <td>/api/servicios/</td>
  </tr>
  <tr>
    <td>Mantenimientos</td>
    <td>/api/mantenimientos/</td>
  </tr>
</table>

<p>
Cada módulo implementa funcionalidades de consulta, registro, edición y eliminación según los permisos asociados al rol del usuario autenticado.
</p>

</div>


<br>

<div style="border-left: 4px solid #2e7d32; padding-left: 15px; margin-top: 20px;">

<h2>Filtros, Paginación y Búsqueda</h2>

<pre>
GET /api/motos/?search=yamaha
GET /api/repuestos/?page=2
GET /api/proveedores/?ordering=nombre
GET /api/compras/?estado=RECIBIDA
</pre>

<p>
La aplicación permite realizar búsquedas, cambiar de página y aplicar filtros según las opciones disponibles en cada endpoint.
</p>

</div>

<br>

<div style="border-left: 4px solid #ef6c00; padding-left: 15px; margin-top: 20px;">

<h2>Manejo de Estados y Experiencia de Usuario</h2>

<ul>
  <li>Indicadores de carga.</li>
  <li>Mensajes de éxito mediante SnackBar.</li>
  <li>Mensajes de error.</li>
  <li>Diálogos de confirmación.</li>
  <li>Validación de formularios.</li>
  <li>Manejo de errores HTTP.</li>
  <li>Actualización de listados después de operaciones CRUD.</li>
</ul>
</div>
<br>
<div style="border-left: 4px solid #00897b; padding-left: 15px; margin-top: 20px;">

<h2>Instalación y Ejecución</h2>

<h3>1. Clonar el repositorio</h3>

<pre>
git clone URL_DEL_REPOSITORIO
cd motoshop-flutter
</pre>

<h3>2. Instalar dependencias</h3>

<pre>
flutter pub get
</pre>

<h3>3. Verificar Flutter</h3>

<pre>
flutter doctor
</pre>

<h3>4. Configurar la URL de la API</h3>

<pre>
lib/core/config/app_config.dart
</pre>

<h3>5. Ejecutar la aplicación</h3>

<pre>
flutter run
</pre>

</div>
<br>

<div style="border-left: 4px solid #6d4c41; padding-left: 15px; margin-top: 20px;">

<h2>Configuración de la API</h2>

<p>
La aplicación utiliza <strong>flutter_dotenv</strong> para gestionar la configuración del entorno. La URL base de la API se define mediante variables de entorno, lo que permite cambiar fácilmente entre ambientes de desarrollo, pruebas y producción sin modificar el código fuente.
</p>

<h3>Archivo de configuración</h3>

<pre>
.env
</pre>

<h3>Variable utilizada</h3>

<pre>
API_BASE_URL=https://motoshop-api.uaeftt-ute.site/api
</pre>

<h3>Implementación</h3>

<pre>
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  static const String appName = 'Flutter Shop App';
  static const double taxRate = 0.15;
}
</pre>

<p>
En caso de que la variable <code>API_BASE_URL</code> no esté definida, la aplicación utiliza como respaldo la dirección <code>http://10.0.2.2:8000/api</code>, la cual corresponde al acceso al servidor local desde el emulador de Android.
</p>

</div>



<br>

<div style="border-left: 4px solid #8e24aa; padding-left: 15px; margin-top: 20px;">

<h2>Credenciales de Prueba</h2>

<pre>
Administrador
Usuario: admin
Contraseña: Motoshop1234!
</pre>

<pre>
Cliente
Usuario: cliente
Contraseña: CONFIGURAR_CREDENCIAL
</pre>

<p>
Las credenciales deben reemplazarse por usuarios válidos registrados en la API.
</p>

</div>
<br>

<div style="border-left: 4px solid #607d8b; padding-left: 15px; margin-top: 20px;">

<h2>Organización del Equipo</h2>

<table>
  <tr>
    <th>Integrante</th>
    <th>Módulo asignado</th>
  </tr>
  <tr>
    <td>Andrés</td>
    <td>Marcas, Categorías, Motos, Repuestos e Inventario</td>
</tr>

<tr>
    <td>Melanie</td>
    <td>Proveedores, Compras, Servicios y Mantenimientos</td>
</tr>

<tr>
    <td>David</td>
    <td>Carrito de Compras, Pedidos, Ventas y Financiamiento</td>
</tr>

<tr>
    <td>Carlos</td>
    <td>Pagos, Facturación, Garantías, Seguros y Administración del Sistema</td>
</tr>
</table>

</div>

<br>

<div style="border-left: 4px solid #1e88e5; padding-left: 15px; margin-top: 20px;">

<h2>Estado del Proyecto</h2>

<ul>
  <li>Proyecto Flutter configurado.</li>
  <li>Arquitectura limpia implementada.</li>
  <li>Navegación pública y privada disponible.</li>
  <li>Autenticación JWT implementada.</li>
  <li>Persistencia de sesión configurada.</li>
  <li>Protección de rutas mediante GoRouter.</li>
  <li>Control de acceso por roles.</li>
  <li>Consumo de API mediante Dio.</li>
  <li>Gestión de estados mediante Riverpod.</li>
  <li>CRUD implementado en los módulos asignados.</li>
  <li>Validaciones y manejo de errores implementados.</li>
  <li>Integración funcional con la API Django.</li>
</ul>

</div>

<br>

<hr>

<div align="center">

<h3>Venta de Motos - Aplicación Móvil</h3>

<p>Frontend desarrollado con Flutter y Dart</p>

<p>Backend desarrollado con Django REST Framework</p>

<p>Universidad Tecnológica Equinoccial</p>

</div>

