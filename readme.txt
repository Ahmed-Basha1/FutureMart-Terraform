## **Project Overview**
This project focuses on deploying a **highly available and secure cloud infrastructure** using a **Hub-and-Spoke topology** on **Microsoft Azure**.
The architecture includes an **Azure Application Gateway** to securely publish a website while ensuring **scalability, security, and high performance**.

### **Key Features**
- **Security:** Multi-layer security implementation using **Azure WAF, Azure Firewall, and Network Security Groups (NSG)**.
- **Access Control:** A **Bastion Host** eliminates direct access to virtual machines, ensuring no workload ports or IPs are exposed.
- **Scalability & Management:** The **Hub-and-Spoke topology** provides centralized management and allows seamless future expansion.
- **Reliability & Disaster Recovery:** Incorporates **Azure Backup Vaults** for data protection and **Azure Monitor & Log Analytics** for real-time system monitoring and logging.
- **Automation:** The infrastructure is deployed using **Infrastructure as Code (IaC) with Terraform**, ensuring maintainability and consistency.
- **Visibility:** A **real-time dashboard** offers insights into system performance and security status.

---
## **Getting Started**

### **Prerequisites**
Ensure you have the following before deploying the infrastructure:
- An **Azure Subscription**
- **Terraform** installed on your local machine
- A **GitHub account** with Actions enabled
- **PowerShell** or **Azure CLI** installed

### **Installation & Deployment**
Follow these steps to deploy the infrastructure:

1. Clone this repository:
   ```sh
   git clone <repository-url>
   cd <repository-folder>
   ```
2. Authenticate with Azure:
   ```sh
   az login
   ```
3. Initialize Terraform and deploy the infrastructure:
   ```sh
   terraform init
   terraform plan
   terraform apply
   ```
4. Use **Azure Monitor** to track deployment status and validate deployed resources.

---
## **Dashboard Setup**
To set up the real-time dashboard, follow these steps:
1. Retrieve your **Azure Subscription ID** and **Subscription Name**:
   ```sh
   az account list --output table
   ```
2. Run the Python script to configure the dashboard:
   ```sh
   python python_convert_dashboard.py
   ```
3. Provide the script with your **Subscription ID** and **Subscription Name** when prompted.

---
## **Contributing**
Contributions are welcome! If you have suggestions or improvements, feel free to **open an issue** or submit a **pull request**.

---
## **Contact**
For inquiries or support, contact **Ahmed Basha** at **ahmedybasha@outlook.com** or connect via **[LinkedIn](linkedin.com/in/ahmedybasha/)**.

