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

### 🎯 Sistema de Traducción Completo
- ✅ **Traducción de Selección**: Traducción instantánea de cualquier texto seleccionado con interfaz superpuesta
- ✅ **Traducción Rápida**: Triple pulsación de Espacio para traducción inmediata
- ✅ **Traducción de Método de Entrada**: Reemplazo directo de texto en campos de entrada
- ✅ **Traducción Híbrida**: Modos de traducción En línea/Local/Inteligente
- ✅ **Soporte Multiidioma**: Cambio fluido entre los principales idiomas del mundo

### 🚀 Integración de IA Completa
- ✅ **Traducción de IA Local**: Modelos de traducción sin conexión alimentados por MLX
- ✅ **Reconocimiento de Voz**: Dictado de voz y comandos basados en Whisper
- ✅ **Detección Inteligente de Texto**: Análisis de texto y sugerencias conscientes del contexto
- ✅ **Recomendaciones Inteligentes**: Sugerencias contextuales alimentadas por IA
- ✅ **Base de Conocimiento**: Búsqueda semántica con documentos personales

### 🎙️ Sistema de Comandos de Voz
- ✅ **16 Comandos Integrados**: Traducción, inserción, búsqueda, comandos del sistema
- ✅ **Comandos de Voz Personalizados**: Cree comandos de voz personalizados
- ✅ **Atajo Global**: Command+Shift+V para activación de voz
- ✅ **Retroalimentación en Tiempo Real**: Indicadores de estado y formas de onda visuales
- ✅ **Reconocimiento Multiidioma**: Soporte para chino, inglés, japonés, coreano

### 📚 Procesamiento Inteligente de Texto
- ✅ **Reescritura Inteligente**: Conversión de estilo y corrección gramatical
- ✅ **Sistema de Plantillas**: Gestión completa de plantillas de documentos
- ✅ **Gestión de Frases**: Inserción y gestión rápida de frases
- ✅ **Conversión de Estilo de Texto**: Optimización de terminología profesional
- ✅ **Aprendizaje de Hábitos del Usuario**: Aprendizaje inteligente de preferencias del usuario

### 🔒 Privacidad y Seguridad
- ✅ **Cifrado Extremo a Extremo**: Mecanismo completo de protección de privacidad
- ✅ **Procesamiento Local-First**: Todo el procesamiento de IA ocurre en el dispositivo
- ✅ **Copia de Seguridad de Datos**: Sistema automático de copia de seguridad y restauración
- ✅ **Sincronización Segura en la Nube**: Sincronización iCloud con resolución de conflictos
- ✅ **Control de Acceso**: Gestión de permisos granular

### 🌐 Nube y Sincronización
- ✅ **Integración iCloud**: Sincronización de datos entre dispositivos
- ✅ **Soporte de Modo Sin Conexión**: Funcionalidad completa sin conexión a internet
- ✅ **Resolución de Conflictos de Sincronización**: Manejo inteligente de conflictos
- ✅ **Sincronización en Tiempo Real**: Actualizaciones instantáneas en todos los dispositivos
- ✅ **Consistencia de Datos**: Integridad de datos asegurada entre plataformas

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

### v1.0.0 (2025-08-23) - **100% Implementación Completa**
#### 🎯 Fase 1: Fundación Central (100% Completo)
- ✅ **Marco de Método de Entrada**: Integración completa de IMKInputMethod
- ✅ **Traducción de Selección**: Selección y traducción de texto en tiempo real
- ✅ **Traducción Rápida**: Traducción instantánea con triple espacio
- ✅ **Almacenamiento de Datos**: Modelos de Core Data con cifrado
- ✅ **Traducción de Campo de Entrada**: Funcionalidad de reemplazo de texto directo

#### 🚀 Fase 2: Integración de IA (100% Completo)
- ✅ **Traducción de IA Local**: Modelos de traducción sin conexión alimentados por MLX
- ✅ **Sistema de Base de Conocimiento**: Base de datos vectorial con búsqueda semántica
- ✅ **Reconocimiento de Voz**: Procesamiento de voz basado en Whisper
- ✅ **Detección Inteligente de Texto**: Análisis de texto consciente del contexto
- ✅ **Optimización de Calidad de Traducción**: Sistema de aprendizaje continuo

#### 🌐 Fase 3: Nube y Eficiencia (100% Completo)
- ✅ **Integración iCloud**: Sincronización de datos entre dispositivos
- ✅ **Sistema de Comandos de Voz**: 16 comandos integrados con soporte personalizado
- ✅ **Procesamiento Inteligente de Texto**: Conversión de estilo y corrección gramatical
- ✅ **Sistema de Plantillas**: Gestión completa de plantillas de documentos
- ✅ **Gestión de Frases**: Inserción y organización rápida de frases

#### 🔒 Seguridad y Privacidad (100% Completo)
- ✅ **Cifrado Extremo a Extremo**: Protección de datos completa
- ✅ **Arquitectura de Privacidad Primero**: Todo el procesamiento en el dispositivo
- ✅ **Sistema de Copia de Seguridad de Datos**: Copia de seguridad y restauración automática
- ✅ **Control de Acceso**: Gestión de permisos granular

#### 🌍 Soporte Multilingüe (100% Completo)
- ✅ **5 Idiomas Principales**: Inglés, Chino, Español, Hindi, Árabe
- ✅ **Cambio de Idioma en Tiempo Real**: Localización instantánea de la interfaz
- ✅ **Traducción Completa de UI**: Todos los elementos de la interfaz localizados
- ✅ **Persistencia de Preferencias del Usuario**: Configuración de idioma guardada automáticamente

### ✨ Estado del Proyecto: **100% Completo**
Todas las características planificadas han sido implementadas y probadas con éxito. FlowKey es ahora un método de entrada inteligente con todas las funciones y capacidades completas de IA.

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT. Vea [LICENSE](LICENSE) para detalles.

## 📞 Contacto

- **Problemas**: [GitHub Issues](https://github.com/zh30/flow-key/issues)
- **Discusiones**: [GitHub Discussions](https://github.com/zh30/flow-key/discussions)
- **Correo**: hello@zhanghe.dev
- **Sitio Web**: [zhanghe.dev](https://zhanghe.dev)

---

**FlowKey** — Escriba más inteligentemente. Comunique mejor. 🚀