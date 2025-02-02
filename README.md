# Terraform-aws-automate
Terraform-aws-automate project is to automate aws infra using Terraform (infrastructure as a code) insteded of manual process we will to make code and deploy on one command.

How to deploy this projects
1) Clone this Repository
   command: git clone https://github.com/AWS-DevOps-shubh/Terraform-aws-automate.git
2) Open in any code editor
3) Establish the connection of AWS Using AWS Congigure then give access key and secret access key
4) In provider.tf file mention the terraform version and the provider name and region means in which region you are deploy the resources.
5) Check all the code
   Note : In ec2_instance change the ami id
6) Review the code and open the terminal.
7) First command: terraform init --- Its Initialize the working directory and initialize the back to store the inftrastructure state.
8) Second command: terraform plan ---- Create and exicute the plan and show the changes to make the infrasture.
9) Third command: terraform apply ---- Its exicute the action process in the terraform plan shows.
After Terraform apply all the action process that show in the terraform plan that makes the infrasture on AWS.

Ones your work is done please remember to destroy all the resources else AWS send you the large amount of Bill.

10) To destroy: terraform destroy

