# How to Install and Configure the AWS CLI on Ubuntu

This guide provides step-by-step instructions to install and configure the AWS Command Line Interface (CLI) on an Ubuntu system. The AWS CLI is an essential tool for managing your AWS services from the terminal.

---

## Step 1: Installation

AWS recommends installing the CLI using the official bundled installer, as it includes all dependencies and is self-contained. This method avoids potential conflicts with other Python packages.

1.  **Download the Installer**

First, download the latest version of the AWS CLI v2 installer for Linux x86_64. We use `curl` to download it and save it as `awscliv2.zip`.

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
```

2.  **Unzip the Installer**

You will need the `unzip` package. If you don't have it, install it first:

```bash
sudo apt-get update
sudo apt-get install -y unzip
```

Now, unzip the downloaded file:

```bash
unzip vps/aws/awscliv2.zip -d ./vps/aws/
```

3.  **Run the Installer**

Execute the install script with `sudo`. This will install the CLI to `/usr/local/aws-cli` and create a symbolic link at `/usr/local/bin/aws`.

```bash
sudo .vps/aws/aws/install
```

4.  **Verify the Installation**

Check that the installation was successful by running:

```bash
aws --version
```

You should see an output like: `aws-cli/2.x.x Python/3.x.x Linux/...`

5.  **Clean Up**

You can now remove the downloaded zip file and the extracted directory.

```bash
rm vps/aws/awscliv2.zip
rm -rf vps/aws/aws/
```

---

## Step 2: Configuration

To interact with your AWS account, you need to configure the CLI with your credentials. The easiest way to do this is with the `aws configure` command.

### Prerequisites for Configuration

You need an **Access Key ID** and a **Secret Access Key**. You can generate these from the AWS IAM console for a specific user. **Never use your root account credentials.** Always create a dedicated IAM user with the minimum necessary permissions.

### Running `aws configure`

1.  **Start the Configuration Wizard**

Run the following command in your terminal:

```bash
aws configure
```

2.  **Enter Your Credentials**

The command will prompt you for four pieces of information. Press `Enter` after each one.

*   **AWS Access Key ID:** Paste the Access Key ID you generated from the IAM console.

```
AWS Access Key ID [None]: YOUR_ACCESS_KEY_ID
```

*   **AWS Secret Access Key:** Paste the corresponding Secret Access Key.
    
```
AWS Secret Access Key [None]: YOUR_SECRET_ACCESS_KEY
```

*   **Default region name:** Enter the AWS Region you want to send your API requests to by default (e.g., `us-east-1`, `eu-west-1`). This is important because many services are region-specific.
    
```
Default region name [None]: us-east-1
```

*   **Default output format:** This determines how results are formatted. `json` is a common choice for scripting and readability. Other options are `yaml`, `yaml-stream`, `text`, and `table`.
    
```
Default output format [None]: json
```

### Where is the Configuration Stored?

The `aws configure` command stores your credentials in a folder named `.aws` within your home directory (`~/.aws`).

*   `~/.aws/credentials`: Stores the Access Key ID and Secret Access Key.
*   `~/.aws/config`: Stores the default region and output format.

**Security Note:** The credentials file is stored in plain text. On a multi-user system, ensure that this file has appropriate permissions (readable only by your user).

---

## Step 3: Test the Configuration

To confirm that everything is working, run a simple command to interact with AWS. For example, this command asks the IAM service who you are authenticated as.

```bash
aws sts get-caller-identity
```

If successful, you will see a JSON output containing your AWS Account ID, User ID, and the ARN of the IAM user whose credentials you configured.

```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-user-name"
}
```

You are now ready to manage your AWS resources from the command line!
