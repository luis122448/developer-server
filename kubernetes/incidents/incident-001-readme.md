# Incident 001: GitLab and Harbor Cluster Outage

**Date:** November 18, 2025

**Author:** Gemini

## 1. Summary

On Tuesday, November 18, 2025, a cluster failure occurred, affecting the `gitlab`, `harbor`, and `gitlab-runner` services. The root cause was the unexpected shutdown of the x86 node `5825u-002`. This caused the pods on that node to become unresponsive, leading to a cascading failure of dependent services. The issue was resolved by identifying the failed node, forcefully deleting the stuck pods, correcting a configuration error in `gitlab-runner`, and restarting the affected services.

## 2. Timeline

*   **Initial Report:** The user reported that the `gitlab`, `harbor`, and `gitlab-runner` services were down, suspecting a node failure.
*   **Investigation:**
    *   It was confirmed that the `5825u-002` node was in a `NotReady` state.
    *   Numerous pods in `Terminating` and `CrashLoopBackOff` states were identified in the `gitlab` and `harbor` namespaces.
*   **Resolution:**
    *   All pods from the dead node were forcibly deleted.
    *   A TOML syntax error in the `gitlab-runner` configmap was corrected.
    *   The `gitlab-runner`, `gitlab-postgresql`, and `harbor-jobservice` pods were restarted.
*   **Recovery:** All services were restored and are now fully functional.

## 3. Commands and Procedures

Here is a detailed list of the commands and procedures used to resolve the incident:

### 3.1. Initial Investigation

*   **Check node status:**
    ```bash
    kubectl get nodes -o wide
    ```
    This command showed that the `5825u-002` node was in a `NotReady` state.

*   **Check pod status:**
    ```bash
    kubectl get pods --all-namespaces | grep -E 'gitlab|harbor'
    ```
    This command showed that multiple `gitlab` and `harbor` pods were in `Terminating` or `CrashLoopBackOff` states.

### 3.2. GitLab Runner Fix

*   **Get logs from the crashing `gitlab-runner` pod:**
    ```bash
    kubectl logs gitlab-gitlab-runner-5dbdc8bb4c-m5nqx -n gitlab
    ```
    The logs revealed a TOML parsing error in the `config.template.toml` file.

*   **Get the `gitlab-runner` configmap:**
    ```bash
    kubectl get configmap gitlab-gitlab-runner -n gitlab -o yaml > gitlab-runner-cm-fix.yaml
    ```
    This command saved the configmap to a local file for editing.

*   **Correct the `config.template.toml` file:**
    The `config.template.toml` file within `gitlab-runner-cm-fix.yaml` was edited to correct the TOML syntax. The `[runners.kubernetes.pod_spec]` section was removed, and the `containers` and `volumes` sections were moved directly under `[runners.kubernetes]`.

*   **Apply the corrected configmap:**
    ```bash
    kubectl apply -f gitlab-runner-cm-fix.yaml
    ```

*   **Restart the `gitlab-runner` pod:**
    ```bash
    kubectl delete pod gitlab-gitlab-runner-5dbdc8bb4c-m5nqx -n gitlab
    ```

### 3.3. GitLab and Harbor Recovery

*   **List pods on the dead node:**
    ```bash
    kubectl get pods --all-namespaces -o wide | grep '5825u-002'
    ```
    This command listed all the pods that were running on the dead node.

*   **Force-delete pods from the dead node:**
    A series of `kubectl delete pod` commands were used to forcibly remove all the pods from the dead node. For example:
    ```bash
    kubectl delete pod gitlab-runner-cf6995f45-dz65v -n gitlab-runner --force --grace-period=0
    kubectl delete pod gitlab-postgresql-0 -n gitlab --force --grace-period=0
    kubectl delete pod harbor-database-0 -n harbor --force --grace-period=0
    # ... and so on for all pods on the dead node
    ```

*   **Restart `harbor-jobservice`:**
    ```bash
    kubectl delete pod harbor-jobservice-844f96df85-n5vxz -n harbor
    ```
    This command restarted the `harbor-jobservice` pod, which was stuck in a `CrashLoopBackOff` state.

## 4. Conclusion

The incident was caused by a single node failure, which cascaded to the services running on it. The recovery process involved identifying the failed components and manually intervening to bring them back online. The `gitlab-runner` configuration error was a pre-existing issue that was exposed by the node failure.

To prevent similar incidents in the future, it is recommended to:
*   Implement a more robust monitoring and alerting system to detect node failures more quickly.
*   Review the `gitlab-runner` configuration to ensure it is correct and resilient to node failures.
*   Consider implementing automated node fencing and remediation to handle dead nodes automatically.