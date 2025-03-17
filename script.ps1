az login --use-device-code

az account show

az account show --query id --output tsv

terraform init

terraform fmt

terraform plan

terraform apply -auto-approve

terrform graph

terraform graph | dot -Tpng -o architecture1.pngs