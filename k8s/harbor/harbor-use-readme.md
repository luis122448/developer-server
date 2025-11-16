# How to Use Harbor for Image Management

This guide provides a comprehensive walkthrough of how to use Harbor to manage your container images. It covers creating users, projects, pushing and pulling images, and using them in your applications.

## 1. Logging into the Harbor UI

First, you need to log into the Harbor web interface to perform administrative tasks.

1.  **Open your web browser** and navigate to the Harbor URL:
    `https://harbor.bbg.pe`

2.  **Log in as the administrator** using the following credentials:
    *   **Username:** `admin`
    *   **Password:** ``

Once logged in, you will have access to all of Harbor's administrative features.

## 2. Creating a Project

In Harbor, images are organized into projects. It is a best practice to create a new project for each application or team.

1.  In the Harbor UI, navigate to **Projects** in the left-hand menu.
2.  Click the **+ New Project** button.
3.  Enter a **Project Name** (e.g., `my-app`).
4.  Choose the **Access Level**:
    *   **Public:** Anyone can pull images from this project.
    *   **Private:** Only users with explicit permissions can pull images.
5.  Click **OK** to create the project.

## 3. Creating a User and Assigning Permissions

For security, you should create a dedicated user for pushing and pulling images instead of using the admin account.

1.  Navigate to **Users** in the left-hand menu.
2.  Click the **+ New User** button.
3.  Fill in the user details:
    *   **Username:** (e.g., `robot-user`)
    *   **Email:** (e.g., `robot@example.com`)
    *   **Full Name:** (e.g., `Robot User`)
    *   **Password:** Set a strong password for the user.
4.  Click **OK** to create the user.

Now, you need to grant this user permissions to your project:

1.  Go back to **Projects** and click on the project you created (e.g., `my-app`).
2.  Go to the **Members** tab.
3.  Click the **+ Add Member** button.
4.  Enter the username you just created (e.g., `robot-user`).
5.  Assign a **Role** to the user:
    *   **Project Admin:** Full control over the project.
    *   **Maintainer:** Can push and pull images.
    *   **Developer:** Can push and pull images.
    *   **Guest:** Can only pull images.
    *   **Limited Guest:** Can only pull images, and cannot see other members.
    For a CI/CD pipeline or a developer machine, **Maintainer** or **Developer** is a good choice.
6.  Click **OK** to add the member to the project.

## 4. Configuring Docker to Use Harbor

To push and pull images, you need to configure the Docker daemon on your client machines to trust the Harbor registry. Since Harbor is using a valid certificate from Let's Encrypt, you should not need to configure Docker to trust the certificate.

However, if you encounter issues, you can configure the Docker daemon to trust the Harbor registry by adding the following to `/etc/docker/daemon.json`:

```json
{
  "insecure-registries": ["harbor.bbg.pe"]
}
```

Then, restart the Docker daemon:

```bash
sudo systemctl restart docker
```

**Note:** Using `insecure-registries` is not recommended for production environments. It is better to ensure that the Docker clients trust the certificate used by Harbor.

## 5. Pushing an Image to Harbor

Now you are ready to push an image to your Harbor project.

1.  **Log in to Harbor from the Docker CLI:**
    Use the credentials of the new user you created.

    ```bash
    docker login harbor.bbg.pe
    ```

2.  **Tag your local image:**
    Before you can push an image, you need to tag it with the Harbor registry URL and project name.

    For example, if you have a local image named `my-image:latest`, you would tag it like this:

    ```bash
    docker tag my-image:latest harbor.bbg.pe/my-app/my-image:latest
    ```

3.  **Push the image to Harbor:**
    Now, push the tagged image to Harbor.

    ```bash
    docker push harbor.bbg.pe/my-app/my-image:latest
    ```

## 6. Pulling an Image from Harbor

To pull an image from Harbor, you also need to be logged in.

1.  **Log in to Harbor from the Docker CLI:**

    ```bash
    docker login harbor.bbg.pe
    ```

2.  **Pull the image:**

    ```bash
    docker pull harbor.bbg.pe/my-app/my-image:latest
    ```

## 7. Using a Harbor Image in `docker-compose.yml`

To use an image from Harbor in a `docker-compose.yml` file, you simply reference the full image name.

```yaml
version: '3.8'

services:
  my-service:
    image: harbor.bbg.pe/my-app/my-image:latest
    ports:
      - "8080:80"
```

If your project is **private**, the machine running `docker-compose` must be logged into Harbor. You can do this by running `docker login harbor.bbg.pe` on the host machine before running `docker-compose up`.

For Kubernetes, you would create an `imagePullSecret` from your Docker credentials and add it to your service account or pod specification.
