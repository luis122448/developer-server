# Incidente 001: Caída de Clústeres GitLab y Harbor

**Fecha:** 18 de Noviembre de 2025

**Autor:** Gemini

## 1. Resumen

El martes 18 de noviembre de 2025, se produjo una falla en el clúster que afectó a los servicios `gitlab`, `harbor` y `gitlab-runner`. La causa raíz fue el apagado inesperado del nodo x86 `5825u-002`. Esto provocó que los pods de ese nodo dejaran de responder, lo que generó una falla en cascada de los servicios dependientes. El problema se resolvió identificando el nodo fallido, eliminando a la fuerza los pods atascados, corrigiendo un error de configuración en `gitlab-runner` y reiniciando los servicios afectados.

## 2. Cronología

*   **Informe Inicial:** El usuario reportó que los servicios `gitlab`, `harbor` y `gitlab-runner` estaban caídos, sospechando una falla de un nodo.
*   **Investigación:**
    *   Se confirmó que el nodo `5825u-002` estaba en estado `NotReady`.
    *   Se identificaron numerosos pods en estado `Terminating` y `CrashLoopBackOff` en los namespaces de `gitlab` y `harbor`.
*   **Resolución:**
    *   Se eliminaron a la fuerza todos los pods del nodo muerto.
    *   Se corrigió un error de sintaxis TOML en el configmap de `gitlab-runner`.
    *   Se reiniciaron los pods `gitlab-runner`, `gitlab-postgresql` y `harbor-jobservice`.
*   **Recuperación:** Todos los servicios se restablecieron y ahora están completamente funcionales.

## 3. Comandos y Procedimientos

Aquí tienes una lista detallada de los comandos y procedimientos utilizados para resolver el incidente:

### 3.1. Investigación Inicial

*   **Verificar el estado de los nodos:**
    ```bash
    kubectl get nodes -o wide
    ```
    Este comando mostró que el nodo `5825u-002` estaba en estado `NotReady`.

*   **Verificar el estado de los pods:**
    ```bash
    kubectl get pods --all-namespaces | grep -E 'gitlab|harbor'
    ```
    Este comando mostró que múltiples pods de `gitlab` y `harbor` estaban en estado `Terminating` o `CrashLoopBackOff`.

### 3.2. Corrección de GitLab Runner

*   **Obtener registros del pod `gitlab-runner` que fallaba:**
    ```bash
    kubectl logs gitlab-gitlab-runner-5dbdc8bb4c-m5nqx -n gitlab
    ```
    Los registros revelaron un error de análisis TOML en el archivo `config.template.toml`.

*   **Obtener el configmap de `gitlab-runner`:**
    ```bash
    kubectl get configmap gitlab-gitlab-runner -n gitlab -o yaml > gitlab-runner-cm-fix.yaml
    ```
    Este comando guardó el configmap en un archivo local para su edición.

*   **Corregir el archivo `config.template.toml`:**
    Se editó el archivo `config.template.toml` dentro de `gitlab-runner-cm-fix.yaml` para corregir la sintaxis TOML. Se eliminó la sección `[runners.kubernetes.pod_spec]` y las secciones `containers` y `volumes` se movieron directamente bajo `[runners.kubernetes]`.

*   **Aplicar el configmap corregido:**
    ```bash
    kubectl apply -f gitlab-runner-cm-fix.yaml
    ```

*   **Reiniciar el pod de `gitlab-runner`:**
    ```bash
    kubectl delete pod gitlab-gitlab-runner-5dbdc8bb4c-m5nqx -n gitlab
    ```

### 3.3. Recuperación de GitLab y Harbor

*   **Listar pods en el nodo muerto:**
    ```bash
    kubectl get pods --all-namespaces -o wide | grep '5825u-002'
    ```
    Este comando listó todos los pods que se estaban ejecutando en el nodo muerto.

*   **Forzar la eliminación de pods del nodo muerto:**
    Se utilizó una serie de comandos `kubectl delete pod` para eliminar a la fuerza todos los pods del nodo muerto. Por ejemplo:
    ```bash
    kubectl delete pod gitlab-runner-cf6995f45-dz65v -n gitlab-runner --force --grace-period=0
    kubectl delete pod gitlab-postgresql-0 -n gitlab --force --grace-period=0
    kubectl delete pod harbor-database-0 -n harbor --force --grace-period=0
    # ... y así sucesivamente para todos los pods en el nodo muerto
    ```

*   **Reiniciar `harbor-jobservice`:**
    ```bash
    kubectl delete pod harbor-jobservice-844f96df85-n5vxz -n harbor
    ```
    Este comando reinició el pod `harbor-jobservice`, que estaba atascado en un estado de `CrashLoopBackOff`.

## 4. Conclusión

El incidente fue causado por la falla de un solo nodo, que se extendió a los servicios que se ejecutaban en él. El proceso de recuperación implicó la identificación de los componentes fallidos y la intervención manual para volver a ponerlos en línea. El error de configuración de `gitlab-runner` era un problema preexistente que fue expuesto por la falla del nodo.

Para prevenir incidentes similares en el futuro, se recomienda:
*   Implementar un sistema de monitoreo y alerta más robusto para detectar fallas de nodos más rápidamente.
*   Revisar la configuración de `gitlab-runner` para asegurarse de que sea correcta y resistente a las fallas de los nodos.
*   Considerar la implementación de la delimitación y remediación automatizada de nodos para manejar los nodos muertos automáticamente.
