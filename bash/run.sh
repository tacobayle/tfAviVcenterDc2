directory="tfAviVcenter"
cd ~/${directory}
$(terraform output -json | jq -r .destroy_avi.value)
sleep 5
terraform destroy -auto-approve -var-file=avi.json
cd ..
rm -fr ${directory}
git clone https://github.com/tacobayle/${directory}
cd ${directory}
TF_VAR_avi_password="***"
TF_VAR_ubuntu_password="***"
terraform init
terraform apply -auto-approve -var-file=avi.json
