[English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [हिन्दी](README.hi.md) | [العربية](README.ar.md)

# FlowKey — Método de Entrada Inteligente para macOS

Una aplicación de método de entrada para macOS de última generación que integra servicios de IA local, ofreciendo traducción en tiempo real, reconocimiento de voz y procesamiento de texto inteligente en 5 idiomas principales.

## 🌍 Soporte Multilingüe

FlowKey admite los 5 idiomas más utilizados del mundo:

- 🇺🇸 **English** (Predeterminado)
- 🇨🇳 **中文** (Chino)
- 🇪🇸 **Español** (Español)
- 🇮🇳 **हिन्दी** (Hindi)
- 🇸🇦 **العربية** (Árabe)

## ✨ Características Principales

### Traducción Principal
- ✅ **Traducción de Selección**: Traducción instantánea de cualquier texto seleccionado
- ✅ **Traducción Rápida**: Triple pulsación de Espacio para traducción inmediata
- ✅ **Local-First**: Modelos de IA en dispositivo garantizan privacidad completa
- ✅ **5 Idiomas**: Cambio fluido entre los principales idiomas del mundo

### Capacidades de IA
- 🚧 **Traducción Sin Conexión**: Inferencia de IA local con MLX
- 🚧 **Reconocimiento de Voz**: Dictado de voz basado en Whisper
- 🚧 **Reescritura Inteligente**: Optimización de texto con IA
- 🚧 **Base de Conocimiento**: Búsqueda semántica con documentos personales

### Experiencia de Usuario
- ✅ **Interfaz Nativa**: Interfaz SwiftUI limpia con localización completa
- ✅ **Integración Profunda**: Integración nativa del sistema macOS
- ✅ **Cambio en Tiempo Real**: Cambio de idioma instantáneo
- ✅ **Privacidad Primero**: Todo el procesamiento ocurre en su dispositivo

## 🏗️ Arquitectura

### Pila Tecnológica
- **Swift + SwiftUI**: Desarrollo nativo para macOS
- **MLX Swift**: Inferencia de IA local optimizada para Apple Silicon
- **IMKInputMethod**: Marco oficial de método de entrada de macOS
- **Core Data**: Persistencia de datos local robusta
- **Sincronización iCloud**: Sincronización fluida entre dispositivos

### Estructura del Proyecto
```
FlowKey/
├── Sources/FlowKey/
│   ├── App/                    # Punto de entrada de la aplicación
│   ├── InputMethod/           # Funcionalidad principal del IME
│   ├── Models/                # Modelos de datos y servicios
│   ├── Services/              # Capa de lógica de negocio
│   ├── Views/                 # Interfaz de usuario
│   └── Resources/             # Recursos y assets
├── Sources/FlowKeyTests/      # Suite de pruebas
└── Documentation/             # Documentación del proyecto
```

## 🚀 Para Empezar

### Requisitos
- macOS 14.0 o posterior
- Xcode 15.0 o posterior
- Swift 5.9 o posterior
- Mac con Apple Silicon recomendado para funciones de IA

### Inicio Rápido

1. **Clonar el repositorio**
```bash
git clone <repository-url>
cd flow-key
```

2. **Construir la aplicación**
```bash
# Construcción de desarrollo
swift build

# Construcción de lanzamiento
swift build -c release
```

3. **Ejecutar la aplicación**
```bash
# Modo desarrollo
swift run

# O usar el script de construcción
./run_app.sh
```

### Instalación

1. **Copiar a Aplicaciones**
```bash
cp -r .build/debug/FlowKey.app /Applications/
```

2. **Habilitar Método de Entrada**
   - Abrir Configuración del Sistema > Teclado > Fuentes de Entrada
   - Hacer clic en "+" para agregar nueva fuente de entrada
   - Seleccionar "FlowKey" de la lista
   - Habilitarlo en sus fuentes de entrada

## 🎯 Guía de Uso

### Traducción Básica
1. Seleccione texto en cualquier aplicación
2. La traducción aparece automáticamente en la superposición
3. Use el botón de copiar para guardar resultados

### Acciones Rápidas
- **Triple pulsación de Espacio**: Traducción instantánea de la selección actual
- **Cmd+Shift+T**: Activador manual de traducción
- **Cmd+Shift+V**: Activación de entrada de voz

### Funciones de Voz
1. Habilite el reconocimiento de voz en Configuración
2. Haga clic en el botón del micrófono o use el atajo de voz
3. Hable naturalmente - el texto se transcribe y traduce
4. Los resultados aparecen instantáneamente con opciones de copia

### Cambio de Idioma
1. Abra Configuración de FlowKey
2. Navegue a la sección "Idioma de la Aplicación"
3. Seleccione su idioma preferido del menú desplegable
4. La interfaz se actualiza inmediatamente con localización completa

## 🔧 Desarrollo

### Configuración del Entorno de Desarrollo
```bash
# Instalar dependencias
swift package update

# Generar proyecto Xcode
swift package generate-xcodeproj

# Ejecutar pruebas
swift test

# Construir para lanzamiento
swift build -c release
```

### Componentes Clave

#### Núcleo del Método de Entrada
- `FlowInputController.swift`: Maneja entrada de usuario y procesamiento de texto
- `FlowInputMethod.swift`: Clase principal del método de entrada y registro del sistema
- `FlowCandidateView.swift`: Interfaz de selección de candidatos

#### Servicios de IA
- `MLXService.swift`: Integración de modelos de IA local
- `AIService.swift`: Interfaz unificada de servicios de IA
- `SpeechRecognizer.swift`: Capacidades de reconocimiento de voz

#### Localización
- `LocalizationService.swift`: Sistema de soporte multilingüe
- Soporta 5 idiomas principales con cambio en tiempo real
- Localización completa de UI con persistencia de preferencias del usuario

### Construir para Distribución
```bash
# Construir versión de lanzamiento
swift build -c release

# Crear paquete de aplicación
mkdir -p FlowKey.app/Contents/MacOS
cp .build/release/FlowKey FlowKey.app/Contents/MacOS/

# Firmar la aplicación (requerido para distribución)
codesign --deep --force --verify --verbose --sign "-" FlowKey.app
```

## 🤝 Contribuir

¡Bienvenimos las contribuciones! Por favor siga estos pasos:

1. **Hacer Fork del repositorio**
2. **Crear una rama de característica** (`git checkout -b feature/característica-asombrosa`)
3. **Confirmar sus cambios** (`git commit -m 'Agregar característica asombrosa'`)
4. **Empujar a la rama** (`git push origin feature/característica-asombrosa`)
5. **Abrir un Pull Request**

### Guías de Desarrollo
- Siga las convenciones de codificación Swift
- Agregue pruebas para nuevas características
- Actualice la documentación
- Asegúrese de que todas las pruebas pasen antes de enviar

## ❓ Preguntas Frecuentes

### P: ¿Cómo habilito el método de entrada?
R: Copie la aplicación a la carpeta de Aplicaciones, luego vaya a Configuración del Sistema > Teclado > Fuentes de Entrada, haga clic en "+" y seleccione "FlowKey".

### P: ¿La traducción no funciona?
R: Verifique su conexión de internet para traducción en línea, o asegúrese de que los modelos de IA local estén descargados para modo sin conexión.

### P: ¿El reconocimiento de voz no funciona?
R: Otorgue permisos de micrófono en Configuración del Sistema > Privacidad y Seguridad > Micrófono, y asegúrese de que los modelos de voz estén descargados.

### P: ¿Cómo cambio el idioma de la interfaz?
R: Abra Configuración de FlowKey, vaya a "Idioma de la Aplicación", y seleccione su idioma preferido del menú desplegable.

## 📋 Registro de Cambios

### v1.0.0 (2025-08-23)
- ✅ Soporte multilingüe completo (5 idiomas)
- ✅ Cambio de idioma en tiempo real
- ✅ Marco de integración de modelos de IA local
- ✅ Traducción de selección con interfaz de superposición
- ✅ Fundamentos de reconocimiento de voz
- ✅ Arquitectura de privacidad primero
- ✅ Capacidades de sincronización iCloud

### Hoja de Ruta
- 🚧 Modelos de IA sin conexión avanzados
- 🚧 Reconocimiento de voz mejorado
- 🚧 Base de conocimiento con búsqueda semántica
- 🚧 Reescritura inteligente de texto
- 🚧 Más soporte de idiomas

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT. Vea [LICENSE](LICENSE) para detalles.

## 📞 Contacto

- **Problemas**: [GitHub Issues](https://github.com/zh30/flow-key/issues)
- **Discusiones**: [GitHub Discussions](https://github.com/zh30/flow-key/discussions)
- **Correo**: support@flowkey.app
- **Sitio Web**: [flowkey.app](https://flowkey.app)

---

**FlowKey** — Escriba más inteligentemente. Comunique mejor. 🚀