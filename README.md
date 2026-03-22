# Deploy a React Application on Azure VM Using Terraform

This project provisions an Azure infrastructure using Terraform and deploys a React application on an Ubuntu 20.04 virtual machine served through Nginx — combining infrastructure as code with manual application deployment over SSH.

---

## Architecture

```
Internet
    |
Public IP Address
    |
Network Interface (NIC)
    |    \
    |   NSG (ports 22 + 80)
    |
Virtual Machine (Ubuntu 20.04)
    Nginx (reverse proxy, port 80)
        |
    Next.js / React App (port 3000)
        |
Subnet (10.0.1.0/24)
    |
Virtual Network (10.0.0.0/16)
    |
Resource Group
```

---

## Resources Provisioned

| Resource | Name | Description |
|---|---|---|
| Resource Group | react-app-rg | Container for all resources |
| Virtual Network | react-vnet | Private network (10.0.0.0/16) |
| Subnet | react-subnet | VM subnet (10.0.1.0/24) |
| Network Security Group | react-nsg | Opens ports 22 (SSH) and 80 (HTTP) |
| Public IP | react-public-ip | Static IP, Standard SKU |
| Network Interface | react-nic | Connects VM to subnet and public IP |
| NSG Association | — | Attaches NSG rules to the NIC |
| Linux Virtual Machine | react-vm | Ubuntu 20.04, Standard_B2s |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) (v1.0+)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- An active [Azure Subscription](https://portal.azure.com)
- Git, SSH client

---

## Quick Start

### Step 1 — Clone the repository

```bash
git clone https://github.com/Nicholasojinni/azure-react-app-terraform.git
cd azure-react-app-terraform
```

### Step 2 — Log in to Azure

```bash
az login
```

### Step 3 — Initialize and deploy

```bash
terraform init
terraform plan
terraform apply
```

Type `yes` when prompted. Note the `public_ip_address` and `ssh_command` from the output.

### Step 4 — SSH into the VM

```bash
ssh azureuser@<public_ip_address>
```

Password: `ReactApp@1234!`

### Step 5 — Install Node.js 18, Nginx and Git

```bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs git nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

> **Important:** Always install Node.js 18 using the NodeSource script. Ubuntu's default repository installs an outdated version (v10) that is incompatible with modern React applications.

### Step 6 — Clone and configure the React app

```bash
git clone https://github.com/pravinmishraaws/my-react-app.git
cd my-react-app/src
nano App.js
```

Update your name and date in the file:
```jsx
<h2>Deployed by: <strong>Your Full Name</strong></h2>
<p>Date: <strong>DD/MM/YYYY</strong></p>
```

Save with **Ctrl+X → Y → Enter**, then go back to the project root:

```bash
cd ..
```

### Step 7 — Install dependencies and build

```bash
npm install
npm run build
```

### Step 8 — Deploy build files to Nginx

```bash
sudo rm -rf /var/www/html/*
sudo cp -r build/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

### Step 9 — Configure Nginx for React

```bash
echo 'server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.html;
    location / {
        try_files $uri /index.html;
    }
    error_page 404 /index.html;
}' | sudo tee /etc/nginx/sites-available/default > /dev/null

sudo systemctl restart nginx
```

> The `try_files $uri /index.html` directive is critical for React Router to work correctly in production. Without it, refreshing any page other than the homepage returns a 404.

### Step 10 — Visit the app

```
http://<public_ip_address>
```

### Step 11 — Destroy resources when done

```bash
exit
terraform destroy
```

---

## Outputs

| Output | Description |
|---|---|
| `public_ip_address` | VM public IP — use for SSH and browser access |
| `ssh_command` | Ready-to-use SSH connection command |

---

## Common Errors and Fixes

| Error | Fix |
|---|---|
| `SkuNotAvailable: Standard_B2s` | Change VM size to `Standard_D2s_v3` |
| `npm run build` fails with SyntaxError | Ubuntu default Node.js is v10 — install v18 via NodeSource script |
| Browser shows Nginx default page | Re-run the Nginx config command and restart Nginx |
| App loads but shows blank page | Ensure `sudo cp -r build/* /var/www/html/` was run (not `build/`) |

---

## Project Structure

```
azure-react-app-terraform/
├── main.tf         # All infrastructure resources
├── .gitignore      # Excludes Terraform binaries and state files
└── README.md       # This file
```

---

## Author

**Nicholas Ojinni**
DevOps Micro Internship (DMI) — Cohort 2 | Group 3
LinkedIn: (https://www.linkedin.com/in/ojinni-oluwafemi11/)
GitHub: (https://github.com/Nicholasojinni)

---

## Resources

- [React App Repository](https://github.com/pravinmishraaws/my-react-app)
- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [DevOps Micro Internship](https://pravinmishra.com/dmi)