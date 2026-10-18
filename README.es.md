# Laboratorio de Apache Kafka con Docker Compose: topics, productores, consumidores, particiones y offsets en el navegador

[English](README.md) | [Français](README.fr.md) | [日本語](README.ja.md) | [Español](README.es.md)

[![check](https://github.com/mitsurutech/lab-kafka/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-kafka/actions/workflows/check.yml)

Un **laboratorio de Apache Kafka** listo para usar en clase, de la [plataforma de aprendizaje MitsuruTech](https://mitsurutech.co.uk/es/learning), donde las escuelas y los centros dan a cada alumno sus propias bases de datos, contenedores y terminal en el navegador. Cada alumno recibe su propia copia de un **Apache Kafka de un solo broker** (modo KRaft, sin ZooKeeper) con **Kafka UI** al lado, para **crear un topic, producir mensajes, leerlos de nuevo desde el principio** y observar las **particiones y los offsets** que hacen de Kafka lo que es, sin instalar nada.

Es un solo archivo `docker-compose`, `compose.yaml`, que funciona igual en tu propio equipo que en la plataforma, donde cada alumno tiene una copia privada sin salida a internet.

## Qué hay

| Servicio | Imagen | Memoria | Qué es |
| --- | --- | --- | --- |
| `kafka` | [`apache/kafka:4.2.2`](https://hub.docker.com/r/apache/kafka) | 512 MB (256 MB de montón) | un nodo que es a la vez broker y controlador, con la creación automática de topics desactivada para que un topic exista porque lo creaste tú |
| `kafka-ui` | [`kafbat/kafka-ui:v1.5.0`](https://github.com/kafbat/kafka-ui) | 512 MB | una página web para crear topics, producir y leer mensajes, y ver particiones y offsets |

Las dos imágenes se ejecutan con un usuario sin privilegios y están fijadas a una versión, nunca `latest`. Es pequeño a propósito: unos 590 MB en uso en reposo y sano en unos diez segundos una vez descargadas las imágenes. Sirve para aprender, no para soportar carga, y no se guarda nada cuando el laboratorio se detiene.

## Usarlo en la plataforma

La [plataforma de aprendizaje MitsuruTech](https://mitsurutech.co.uk/es/learning) da a cada alumno su propia copia de un laboratorio, en el navegador, con una terminal al lado.

**Para probarlo:** abre la [página de contenedores](https://mitsurutech.co.uk/es/container), busca este laboratorio en **Laboratorios de ejemplo** y pulsa Iniciar. No hace falta una cuenta para probar uno.

**Para ponerlo como trabajo a una clase:**

1. En tu módulo, crea una tarea de tipo **Laboratorio** y elige **En un repositorio de GitHub**.
2. Indica `https://github.com/mitsurutech/lab-kafka` con la rama `main`. El archivo compose es el predeterminado, `compose.yaml`. Haz antes un fork del repositorio si quieres cambiar el archivo.
3. Publica. La copia de cada alumno parte del commit que publicaste, así que un cambio posterior aquí no altera un laboratorio ya asignado.
4. Di en la tarea qué hay que entregar (consulta [Para profesores](#para-profesores)) y asígnala como cualquier otra tarea.

El manual tiene una [página de este laboratorio](https://mitsurutech.co.uk/es/help/lab-kafka) y una [guía de laboratorios de contenedores](https://mitsurutech.co.uk/es/help/labs) que cubre el resto: qué puede decir un archivo compose, cuánta memoria recibe una copia y cómo abre, vigila y califica un profesor la copia de un alumno.

¿Aún no tienes una cuenta de centro? [El primer año es gratis](https://mitsurutech.co.uk/es/pricing) hasta 50 alumnos, y [registrarse](https://mitsurutech.co.uk/es/signup) solo pide una dirección de correo electrónico.

## Ejecutarlo en tu propio equipo

Necesitas Docker con el plugin Compose. El primer arranque descarga las imágenes.

```bash
docker compose -f compose.yaml -f local.yaml up
```

Abre <http://localhost:8080> para Kafka UI. `local.yaml` publica ese único puerto solo en `127.0.0.1`, así que es accesible desde tu propio ordenador y desde ningún otro sitio. El broker no se publica: en tu propio equipo, accede a él desde otro contenedor de la misma red como `kafka:9092`. Páralo con `Ctrl-C` y elimínalo con `docker compose -f compose.yaml -f local.yaml down -v`.

## Paso a paso

1. **Abre Kafka UI** y elige el clúster, `lab`. Muestra un broker y ningún topic.
2. **Crea un topic.** Topics, luego Add a Topic: un nombre como `orders` y **3 particiones**. Un topic es un registro con nombre; sus particiones son los trozos en que se divide. El factor de replicación es 1, porque hay un solo broker.
3. **Produce mensajes.** En la página del topic pulsa Produce Message, elige una partición y envía unos cuantos con una clave y un valor. Cada mensaje se añade al final de una partición y recibe el siguiente **offset** en ella, contando desde cero. Cada partición cuenta por su cuenta.
4. **Léelos de nuevo desde el principio.** La pestaña Messages del topic lee con un control de posición que empieza en Newest; ajústalo para leer desde el principio, que es lo que hace un consumidor nuevo cuando no tiene una posición guardada. Cada fila muestra su offset y su partición.
5. **Mira los offsets.** El Overview del topic lista cada partición con su First Offset y su Next Offset. El next offset es el offset que recibirá el siguiente mensaje, así que una partición con dos mensajes tiene un next offset de 2.

La terminal que hay junto al laboratorio hace lo mismo con `curl`, porque el puesto de trabajo no tiene las herramientas de línea de comandos de Kafka: Kafka UI tiene una API web, accesible desde la terminal como `kafka-ui:8080`, y es la que llama la propia página. Por ejemplo, esto crea un topic y luego lista el offset de cada partición:

```bash
curl -s -X POST -H "Content-Type: application/json" -d '{"name":"orders","partitions":3,"replicationFactor":1,"configs":{}}' http://kafka-ui:8080/api/clusters/lab/topics -o /dev/null -w "%{http_code}"
curl -s http://kafka-ui:8080/api/clusters/lab/topics/orders | grep -o '"partition":[0-9]*\|"offsetMax":[0-9]*'
```

Producir a través de esa API necesita un número de partición, así que un comando nombra una.

## Para profesores

Nada en este laboratorio se califica automáticamente. El alumno entrega pruebas y tú las calificas, como cualquier otro laboratorio.

**Pide pruebas en dos mitades.** Primero, la prueba del trabajo: una captura de pantalla de las particiones del topic con sus offsets, y de los mensajes leídos de nuevo desde el principio. Segundo, la comprensión: con sus propias palabras, por qué cada partición empieza a contar en cero, por qué leer desde el principio devuelve mensajes que quien lee nunca había visto y qué cambiaría con más de un broker.

**Dónde encaja en un curso.** Kafka es adecuado para una unidad sobre arquitectura orientada a eventos, mensajería y colas, canalizaciones de big data o sistemas distribuidos: la idea de que un topic es un registro al que solo se añade y de que la posición de un consumidor es solo un offset. Consulta la unidad de tu propio organismo de certificación para ver la redacción exacta; aquí no se cita ninguna.

**Quién ve qué.** Una copia es privada del alumno que la inició. Un miembro del personal que da el módulo puede abrirla para ver lo que ha hecho el alumno, y abrir el trabajo de un alumno queda anotado en el registro de accesos, que el alumno puede leer.

## Lo que no funciona en un laboratorio

El laboratorio no tiene ninguna salida a internet, así que nada de fuera puede leer ni escribir en el broker. Es un solo broker, por lo que la replicación, la elección de líder y el reequilibrio de un grupo de consumidores entre brokers se describen, no se muestran. Los mensajes y los topics del broker no se guardan cuando el laboratorio se detiene. La terminal no tiene herramientas de línea de comandos de Kafka como `kafka-topics.sh`; están en la imagen del broker, no en la terminal, así que el laboratorio enseña con Kafka UI y su API web.

## Solución de problemas

- **Kafka UI no aparece justo después de Iniciar.** Espera unos segundos y pulsa Abrir de nuevo: el laboratorio solo se declara listo cuando el broker responde y la página ha arrancado.
- **Un topic que creaste ha desaparecido.** El broker no guarda nada entre ejecuciones; créalo de nuevo.
- **En tu propio equipo, el puerto 8080 ya está en uso.** Cambia el número de la izquierda en `local.yaml`, por ejemplo `127.0.0.1:8081:8080`, y abre ese puerto en su lugar.

## Comprobar el laboratorio

`test/check.sh` arranca el laboratorio como lo hace el ejecutor de la plataforma con cada servicio (todas las capacidades retiradas, `no-new-privileges`, un límite de procesos, límites de memoria y sin salida a internet) y luego comprueba desde dentro de su red lo que promete esta página: un broker KRaft, un topic de tres particiones, mensajes que van a dos de ellas con cada partición contando desde cero, y una lectura desde el principio. Necesita Docker y se ejecuta en cada push, que es la insignia de la parte superior.

```bash
test/check.sh
```

## Versiones y licencias

[Apache Kafka](https://kafka.apache.org) tiene licencia Apache-2.0 y [Kafka UI](https://github.com/kafbat/kafka-ui) tiene licencia Apache-2.0. Las imágenes son `apache/kafka:4.2.2` y `kafbat/kafka-ui:v1.5.0`, ejecutadas sin modificar desde las imágenes públicas de los propios proyectos; nada de ellas se construye ni se redistribuye aquí.

Las aplicaciones que contienen tienen las licencias de sus propios proyectos, enlazadas arriba.

## Licencia

Esta obra está bajo licencia [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Puedes compartirla y adaptarla para aprender y enseñar, si citas a Mitsuru Technologies Ltd, no la usas comercialmente y compartes lo que hagas con ella bajo la misma licencia. El texto completo está en el archivo `LICENSE`.

## Acerca de

Hecho por [Mitsuru Technologies](https://mitsurutech.co.uk) para la [plataforma de aprendizaje MitsuruTech](https://mitsurutech.co.uk/es/learning): Python, Java, Go, Node, SQL y Linux en el navegador para escuelas y centros, con laboratorios de contenedores, aplicaciones web desplegadas desde GitHub y cuestionarios que se califican solos. Prueba código sin cuenta en el [entorno de pruebas](https://mitsurutech.co.uk/es/playground).

Más laboratorios del mismo sitio: [lab-valkey](https://github.com/mitsurutech/lab-valkey), [lab-spark](https://github.com/mitsurutech/lab-spark), [lab-observability](https://github.com/mitsurutech/lab-observability), [lab-docker-basics](https://github.com/mitsurutech/lab-docker-basics), [lab-mysql-phpmyadmin](https://github.com/mitsurutech/lab-mysql-phpmyadmin) y [lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea).
