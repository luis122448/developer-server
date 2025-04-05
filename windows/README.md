# Connectec to Server by OpenSSH

- Open PowerShell as Administrator, and run the following command to install OpenSSH Client:

    ```powershell
        Add-WindowsFeature -Name OpenSSH-Client

        Get-Service -Name ssh*
    ```

- Connect to the server using SSH

    ```powershell
        ssh <username>@<server_ip>
    ```