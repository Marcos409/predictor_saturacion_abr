# TI-Saturation Predictor

Aplicación web en Flutter para que ingenieros de TI de NMiko S.A.C. simulen la
saturación de una Capa Web (tanque A) y una Base de Datos (tanque B) mediante
ecuaciones diferenciales.

El modelo usa minutos como única unidad de tiempo. Todos los parámetros,
coeficientes, capacidades, límites y recetas se cargan desde archivos JSON; no
hay valores del modelo escritos en el código.

## Requisitos

- Flutter 3.41.7 o superior (Dart 3.11.5 o superior).
- Navegador Chrome para ejecutar la versión web.
- PowerShell en Windows para los comandos de ejemplo.

Comprueba el entorno con:

```powershell
flutter --version
flutter doctor
```

## Ejecutar la aplicación

Desde la raíz del proyecto:

```powershell
flutter pub get
flutter run -d chrome
```

Si Chrome no está disponible, usa el servidor web:

```powershell
flutter run -d web-server
```

Para generar una compilación estática de producción:

```powershell
flutter build web --release
```

El resultado queda en `build/web`.

## Validar el proyecto

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

El proyecto debe quedar sin errores ni advertencias y con todas las pruebas en
verde.

## Módulos de la aplicación

- **Dashboard:** resumen de colapsos, ventana de acción y estado del Auto-Scaling.
- **Escenarios:** selección del escenario de tráfico que alimenta la simulación.
- **Fase 1 · Tráfico:** edición de los parámetros de `v1(t)`.
- **Fase 2 · Servidores:** edición de coeficientes, capacidades, condiciones
  iniciales y tiempo de reacción de TI.
- **Simulación en vivo:** reproducción, pausa, velocidad y escalado manual.
- **Alertas y Auto-Scaling:** avisos, alerta crítica, eventos y escalado automático.
- **Resultados:** comparación de los cuatro escenarios y lectura del semáforo.
- **Ver la matemática:** sistema de ecuaciones, EDO de segundo orden, valores
  propios, solución analítica, derivadas, límites y verificación cruzada.
- **Verificación ABR:** carga los valores del ABR, resuelve la Fase 1 y la Fase 2,
  compara las ecuaciones del motor con la referencia y muestra colapsos,
  ventana de acción y límites.
- **Configuración (JSON):** carga, descarga y restauración del caso base.

## Configuración del modelo

Los archivos se encuentran en `assets/config/` y se declaran como assets en
`pubspec.yaml`:

- `sistema.json`: tanques, caudales, volúmenes, límites, condiciones iniciales,
  tiempo de reacción, umbral de aviso, simulación, Auto-Scaling, verificación y
  semáforo.
- `escenarios.json`: versión, unidad de tiempo, variable independiente y lista de
  escenarios de tráfico con sus parámetros y la expresión `v1(t)`.
- `soluciones.json`: expresiones analíticas `x(t)` e `y(t)` usadas por la
  verificación cruzada.
- `referencia_abr.json`: valores del ABR editados a mano. Incluye la sección
  `tanques` y un caso por escenario con las ecuaciones de referencia.

### Editar los JSON

1. Abre el archivo correspondiente en `assets/config/`.
2. Modifica solo los valores; conserva los nombres de las claves y la estructura.
3. Mantén `"unidad_tiempo": "min"` en `sistema.json`, `escenarios.json` y
   `soluciones.json`.
4. Guarda el archivo y reinicia la aplicación para volver a cargar los assets.

Ejemplo de `sistema.json`:

```json
{
  "version": 2,
  "unidad_tiempo": "min",
  "tanques": {
    "modo_coeficientes": "derivado",
    "c1": 1,
    "volumen_A": 100,
    "volumen_B": 200,
    "limite_A": 100,
    "limite_B": 200,
    "tiempo_reaccion_min": 10,
    "caudales": {
      "A_a_B": 20,
      "A_salida": 10,
      "B_a_A": 20,
      "B_salida": 60
    },
    "coeficientes_directos": {
      "a11": -0.3,
      "a12": 0.1,
      "a21": 0.2,
      "a22": -0.4
    }
  },
  "condiciones_iniciales": { "x0": 0, "y0": 0 },
  "umbral_alerta": 0.7,
  "simulacion": { "paso": 0.05, "tiempo_final": 30 },
  "auto_scaling": {
    "incremento_capacidad": 50,
    "retraso": 1,
    "maximo_escalados": 4
  },
  "verificacion": { "umbral_error": 0.01 },
  "semaforo": { "ventana_amarilla": 0, "ventana_verde": 5 }
}
```

Con `"modo_coeficientes": "derivado"` los coeficientes se calculan a partir de
los caudales y los volúmenes. Con `"directo"` se usan los valores de
`coeficientes_directos`.

Cada escenario de `escenarios.json` debe incluir `id`, `nombre`, `edo`,
`parametros` y `v1`:

```json
{
  "id": "lineal",
  "nombre": "Lineal",
  "edo": "x' = v1(t) + a11*x + a12*y ; y' = a21*x + a22*y",
  "parametros": [
    { "clave": "P0", "nombre": "P0", "valor": 10 },
    { "clave": "m", "nombre": "m", "valor": 5 }
  ],
  "v1": "P0 + m*t"
}
```

Las expresiones aceptan operaciones aritméticas, `sin`, `cos`, `pi` y `exp`
(también escrita como `EXP`). La variable independiente es `t`.

### Editar la referencia del ABR

`assets/config/referencia_abr.json` guarda los valores del ABR tal como los
define el usuario. La aplicación no los corrige ni los recalcula.

- `tanques`: usa la misma estructura que la sección `tanques` de `sistema.json`
  (`modo_coeficientes`, `c1`, volúmenes, límites, caudales y coeficientes).
- `casos`: un elemento por escenario. `fase1` describe la EDO y `v1(t)`;
  `fase2` contiene `x(t)`, `y(t)` y las condiciones iniciales de referencia.
- `esperado`: colapsos y ventana de acción esperados, con su tolerancia.

Si un caso tiene `fase2.x` o `fase2.y` en `null`, el módulo **Verificación ABR**
compara automáticamente la solución del motor contra RK4 y muestra la nota
"Referencia pendiente".

### Cargar y descargar configuración desde la aplicación

En el módulo **Configuración (JSON)**:

- **Descargar configuración actual** genera
  `configuracion_ti_saturacion.json` con las tres secciones.
- **Cargar JSON** reemplaza la configuración completa. Si el archivo es inválido,
  falta una sección o la unidad de tiempo no es `min`, no se modifica el estado.
- **Restaurar caso base** vuelve a los valores originales de `assets/config/`.

## Modelo de referencia

El caso base usa:

- `x' = v1(t) - 0.3x + 0.1y`
- `y' = 0.2x - 0.4y`
- `x(0) = 0`, `y(0) = 0`
- `v1(t) = 10 + 5t`
- Capacidad de la Capa Web: 100
- Capacidad de la Base de Datos: 200
- Tiempo de reacción de TI: 10 min

Con esos valores se espera un colapso de la Capa Web cercano a 6.9 min, un
colapso de la Base de Datos cercano a 25 min y una Ventana de Acción de
aproximadamente -3.1 min.

La solución analítica de referencia es:

- `x(t) = -50 + 20t + 50e^(-0.2t)`
- `y(t) = -50 + 10t + 50e^(-0.2t)`

## Estructura del código

```text
lib/
  app/                  estado, tema, navegación y widgets compartidos
  core/config/          carga de assets de configuración y referencia ABR
  core/engine/          solver Runge-Kutta, solver analítico, evaluadores y detector
  core/models/          modelos de configuración y resultados
  features/             pantallas por módulo (sin dependencias entre módulos)
assets/config/          configuración editable del modelo
test/                   pruebas de motor, estado, configuración y widgets
```

Los módulos de `lib/features` no se importan entre sí. La comunicación se realiza
a través de los modelos y utilidades de `lib/core` y `lib/app`.

## Pruebas

Las pruebas cubren el caso base del motor, la solución analítica general, la
detección de colapsos, la ventana de acción, la verificación cruzada, la
verificación ABR, las validaciones de los tanques, el semáforo, la serialización
de la configuración y la navegación principal.

```powershell
flutter test
```

Para ejecutar un grupo específico:

```powershell
flutter test test/engine
flutter test test/app
```
