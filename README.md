# 💪 GymManager App - Administración de Gimnasios

> 📱 Proyecto desarrollado para el curso **Diseño y Programación de Plataformas Móviles** de la Universidad Nacional, Sede Regional Chorotega.

---

## 🎯 Propósito del Proyecto

**GymManager** es una aplicación móvil creada para facilitar la gestión interna de un gimnasio, mejorando tanto la experiencia de los administradores como la de los usuarios. Permite controlar usuarios, suscripciones, asistencia, entrenamientos, pagos y mucho más a través de una plataforma intuitiva y eficiente.

---

## 🧩 Funcionalidades Principales

### 👤 Gestión de Usuarios

- Registro e inicio de sesión con autenticación segura.
- Perfiles personalizados con datos como edad, peso, altura, plan activo.
- Consulta de historial de asistencia y pagos.

### 📅 Planes y Suscripciones

- Creación y asignación de planes (mensual, trimestral, anual).
- Notificaciones por vencimiento.
- Control detallado de pagos y fechas de renovación.

### 📍 Control de Asistencia

- Registro de entradas/salidas con QR o PIN.
- Historial de visitas disponible para cada usuario.

### 🏋️ Gestión de Entrenamientos

- Rutinas personalizadas según objetivos del usuario.
- Seguimiento del progreso (peso levantado, repeticiones, etc.).
- Instrucciones visuales (imágenes/videos) para cada ejercicio.

### 🧑‍🏫 Administración del Gimnasio

- Gestión de instructores y horarios.
- Reportes generales: asistencia, ingresos, desempeño de usuarios.

---

## 📌 Prioridad de Requerimientos

| Prioridad | Funcionalidades                                             |
| --------- | ----------------------------------------------------------- |
| 🔴 Alta   | Autenticación, gestión de usuarios, planes, rutinas.        |
| 🟡 Media  | Reportes, notificaciones, seguimiento detallado.            |
| 🟢 Baja   | Funciones complementarias futuras como valoraciones y chat. |

---

## ⚙️ Requerimientos No Funcionales

- ✅ **Usabilidad**: Interfaz clara, botones intuitivos y validación amigable.
- 🚀 **Rendimiento**: Tiempos de respuesta < 250ms en operaciones comunes.
- 🔐 **Seguridad**: Cifrado de datos, tokens seguros, sin almacenamiento local.
- 🌱 **Escalabilidad**: Pensado para crecer sin reestructuración.

---

## 🖥️ Interfaz de Usuario

- Pantalla de inicio con logo y opciones de autenticación.
- Formularios con validaciones visuales.
- Perfil con historial de rutinas, asistencia y edición de datos.
- Panel de administración completo con gestión de usuarios y clases.

---

## 🔥 Integración con Firebase

La aplicación utiliza **Firebase** como backend para las siguientes funcionalidades clave:

- 🔐 **Autenticación** de usuarios con correo y contraseña.
- ☁️ **Firestore** como base de datos en tiempo real para almacenar información de usuarios, rutinas y asistencia.
- 📩 **Cloud Messaging** para el envío de notificaciones sobre vencimientos y renovaciones.

> ✅ Firebase permite escalar la aplicación fácilmente, mantener la seguridad de los datos y reducir tiempos de desarrollo gracias a su integración fluida con Flutter.

---

---

## 🏫 Universidad Nacional

**Carrera**: Ingeniería en Sistemas de Información y Comunicación  
**Curso**: Diseño y Programación de Plataformas Móviles
