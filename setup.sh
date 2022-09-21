# Args
apiClient=$1
pathToKey=$2
export API_CLIENT=$1
export PATH_TO_KEY=$2

# HMCTL setup
wget -O /usr/bin/hmctl https://github.com/PureStorage-OpenConnect/hmctl/releases/download/v1.0.28/hmctl-linux-amd64
chmod +x /usr/bin/hmctl
mkdir -p .pure/
echo "{
  "default_profile": "admin",
  "profiles": {
    "user1": {
      "env": "pure1",
      "endpoint": "https://api.pure1.purestorage.com/fusion",
      "auth": {
        "issuer_id": "$apiClient",
        "private_pem_file": "$pathToKey"
      }
    }
  }
}" > .pure/fusion.json

# HMCTL test
hmctl region list

# Python setup
python3 -m pip install --user install purefusion

# Python test
chmod +x python/smoke_test.py
python3 python/smoke_test.py

# Ansible setup
python3 -m pip install --user ansible
ansible-galaxy collection install purestorage.fusion

# Ansible test
ansible-playbook ansible/smoke_test.yml

# Terraform setup
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform

# Terraform test
terraform -help
cd terraform
terraform init