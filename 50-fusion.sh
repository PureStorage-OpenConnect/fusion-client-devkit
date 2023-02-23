if [ ! -d "/api-client" ]; then
	echo "api-client directory not mounted. Did you run with docker -v <path-to-api-client>:/api-client?"
	exit 1
fi

if [ ! -f "/api-client/issuer" ]; then
	echo "issuer not found. Did you add the file issuer containing the application ID into your api-client folder?"
	exit 1
fi

if [ ! -f "/api-client/private-key.pem" ]; then
	echo "private-key.pem not found. Did you add the file private-key.pem containing the private key into your api-client folder?"
	exit 1
fi

mkdir -p ~/.pure/
cat <<EOF > ~/.pure/fusion.json
{
  "default_profile": "default",
  "profiles": {
    "default": {
      "auth": {
	"issuer_id": "$(cat /api-client/issuer)",
        "private_pem_file": "/api-client/private-key.pem"
      },
      "endpoint": "https://api.pure1.purestorage.com/fusion",
      "env": "pure1"
    }
  }
}
EOF

export PRIV_KEY_FILE="/api-client/private-key.pem"
export API_CLIENT="$(cat /api-client/issuer)"

# Turn on auto-completion for hmctl
source <(hmctl completion bash)
source /etc/bash_completion.d/hmctl
