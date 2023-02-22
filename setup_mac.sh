#!/bin/zsh

# Args
apiClient="$1"
pathToKey="$2"

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
nocolor='\033[0m'

echo -e "${red}"
# check this scripts is given 2 argvs
if [ "$#" -ne 2 ]; then
    echo "Missing parameters: API_CLIENT and PRIV_KEY_FILE"
    echo -e "${blue}Run: $0 API_CLIENT PRIV_KEY_FILE${nocolor}"
    exit
fi

# Check if apiClient argv is empty
if [[ -z "$apiClient" ]]; then
  echo "Missing API Client ID"
  exit
fi
# Check if pathToKey argv is empty
if [[ -z "$pathToKey" ]]; then
  echo "Missing Private Key path"
  exit
elif ! [[ -f "$pathToKey" ]]; then # check if pathToKey is not a valid file
  echo "Private Key is not a valid file: $pathToKey"
  exit
fi

# check that pathToKey is absolute and not relative
# absolute = /home/user/folder/priv_key.pem
# relative = private_key.pem
case $pathToKey in
  /*) echo -e "${green}Starting install setup${nocolor}" ;;
   *) echo -e "Please use absolute path for private key: $pathToKey${nocolor}"
      echo -e "Example: $(pwd)/$pathToKey"
      exit ;;
esac

export API_CLIENT="$apiClient"
export PRIV_KEY_FILE="$pathToKey"

echo "
██████  ██    ██ ██████  ███████ ███████ ████████  ██████  ██████   █████   ██████  ███████
██   ██ ██    ██ ██   ██ ██      ██         ██    ██    ██ ██   ██ ██   ██ ██       ██
██████  ██    ██ ██████  █████   ███████    ██    ██    ██ ██████  ███████ ██   ███ █████
██      ██    ██ ██   ██ ██           ██    ██    ██    ██ ██   ██ ██   ██ ██    ██ ██
██       ██████  ██   ██ ███████ ███████    ██     ██████  ██   ██ ██   ██  ██████  ███████
"

if [[ ! "$(uname -s)" == "Darwin" ]]; then
  echo -e "${red}Not macOS${nocolor}"
  exit
fi

# Install xcode
xcode-select --install

# HMCTL setup

echo -e "${blue}################################"
echo -e "#         HMCTL setup          #"
echo -e "################################${nocolor}"

echo -e "${green}Downloading HMCTL..."
if [[ "$(uname -m)" == "arm64" ]]; then
  sudo curl -L -o /usr/local/bin/hmctl https://github.com/PureStorage-OpenConnect/hmctl/releases/latest/download/hmctl-darwin-arm64
else
  sudo curl -L -o /usr/local/bin/hmctl https://github.com/PureStorage-OpenConnect/hmctl/releases/latest/download/hmctl-darwin-amd64
fi

# check last command exit status
if [ $? -eq 0 ]; then
  echo -e "${green}HMCTL download to: /usr/local/bin/hmctl"
else
  echo -e "${red}HMCTL fail to download"
  exit
fi
# give hmctl execute permissions
sudo chmod +x /usr/local/bin/hmctl
# create folder .pure under home folder
mkdir -p ~/.pure/


# create file: ~/.pure/fusion.json (replace if exist)
sudo echo '{
  "default_profile": "main",
  "profiles": {
    "main": {
      "env": "pure1",
      "endpoint": "https://api.pure1.purestorage.com/fusion",
      "auth": {
        "issuer_id": "'${apiClient}'",
        "private_pem_file": "'${pathToKey}'"
      }
    }
  }
}' | sudo tee ~/.pure/fusion.json

# HMCTL test
echo -e "${blue}################################"
echo -e "#         HMCTL test           #"
echo -e "################################${nocolor}"

hmctl region list

# Python setup
echo -e "${blue}################################"
echo -e "#         Python setup         #"
echo -e "################################${nocolor}"

python3 -m ensurepip

echo -e "${blue}################################"
echo -e "#    Python Lib: Purefusion    #"
echo -e "################################${nocolor}"
pip3 install purefusion
pip3 install netaddr
pip3 install cryptography==3.4.8

# Python smoke test
echo -e "${blue}################################"
echo -e "#      Python smoke test       #"
echo -e "################################${nocolor}"
sudo chmod +x python/00_smoke_test.py
python3 python/00_smoke_test.py

# check if last command fail
if [ $? -eq 1 ]; then
  echo -e "${red}################################"
  echo -e "#   FAIL: Python smoke test    #"
  echo -e "################################${nocolor}"
fi

# Ansible setup
echo -e "${blue}################################"
echo -e "#         Ansible setup        #"
echo -e "################################${nocolor}"

python3 -m pip install --user ansible
sudo ansible-galaxy collection install purestorage.fusion
sudo ansible-galaxy collection install community.general
sudo ansible-galaxy collection install ansible.posix

# This is just a hack until these changes are merged into the mainline Ansible collection
sudo cp patches/fusion_region.py "$HOME/.ansible/collections/ansible_collections/purestorage/fusion/plugins/modules/"
sudo cp patches/fusion_se.py "$HOME/.ansible/collections/ansible_collections/purestorage/fusion/plugins/modules/"

echo -e "${blue}################################"
echo -e "#     Ansible smoke test     #"
echo -e "################################${nocolor}"
sudo ansible-playbook ansible/smoke_test.yml

# check if last command fail
if [ $? -eq 0 ]; then
    # if success
  echo -e "${green}################################"
  echo -e "#     OK:Ansible smoke test     #"
  echo -e "################################${nocolor}"
else
  echo -e "${red}################################"
  echo -e "#    FAIL:Ansible smoke test   #"
  echo -e "################################${nocolor}"
fi

# Terraform setup
echo -e "${blue}################################"
echo -e "#       Terraform setup        #"
echo -e "################################${nocolor}"

if [[ "$(uname -m)" == "arm64" ]]; then
  sudo curl -L -o ./terraform.zip https://releases.hashicorp.com/terraform/1.3.8/terraform_1.3.8_darwin_arm64.zip
else
  sudo curl -L -o ./terraform.zip https://releases.hashicorp.com/terraform/1.3.8/terraform_1.3.8_darwin_amd64.zip
fi
unzip ./terraform.zip
chmod +x ./terraform
if [[ -f "/usr/local/bin/terraform" ]]; then
  sudo rm /usr/local/bin/terraform
fi
sudo mv ./terraform /usr/local/bin/terraform
rm ./terraform
sudo rm ./terraform.zip

# Terraform test
echo -e "${blue}################################"
echo -e "#       Terraform test        #"
echo -e "################################${nocolor}"

color_terraform="$red"
terraform_version=$(terraform -version)
# check last command exit status
if [ $? -eq 0 ]; then
  color_terraform="$green"
fi
echo -e "${color_terraform}################################"
echo -e "$terraform_version"
echo -e "################################${nocolor}"