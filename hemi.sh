#!/bin/bash

# Function to print the introduction
print_intro() {
  echo -e "\033[94m"
  figlet -f /usr/share/figlet/starwars.flf "POP-MINING UPGRADE"
  echo -e "\033[0m"

  echo -e "\033[92m📡 Upgrading POP-MINING\033[0m"   # Green color for the description 
  echo -e "\033[96m👨‍💻 Created by: Cipher\033[0m"  # Cyan color for the creator
  echo -e "\033[95m🔧 Rebuilding PoP Mining Containers...\033[0m"  # Magenta color for the upgrade message

  echo "════════════════════════════════════════════════════════════" 
  echo "║       Follow us for updates and support:                 ║"
  echo "║                                                          ║"
  echo "║     Twitter:                                             ║"
  echo "║     https://twitter.com/0xrevrb                          ║"
  echo "║                                                          ║"
  echo "║     Telegram:                                            ║"
  echo "║     - https://t.me/oxreverb                              ║"
  echo "╚════════════════════════════════════════════════════════════"
}

# Call the introduction function
print_intro

# Function to print messages in purple
show() {
    echo -e "\033[1;35m$1\033[0m"
}

# Function to fetch dynamic fee
fetch_dynamic_fee() {
  max_retries=10
  retry_count=0
  set_fee=0
  CONST_FEE=1500

  echo "Trying to fetch recommended fees, max retries $max_retries..."

  while [ $retry_count -lt $max_retries ]; do
    set_fee=$(curl -m 5 -sSL "https://mempool.space/testnet/api/v1/fees/recommended" | jq .fastestFee)

    if [ $? -eq 0 ] && [ -n "$set_fee" ] && [ "$set_fee" != "null" ]; then
      echo "Request was successful, setting fees to $set_fee"
      break
    else
      echo "Request failed. Retrying..."
      retry_count=$((retry_count + 1))
      sleep 2
    fi
  done

  if [ $retry_count -eq $max_retries ]; then
    echo "Failed to fetch fees after $max_retries retries. Defaulting to $CONST_FEE"
    set_fee=$CONST_FEE
  fi

  # Apply the fee to the environment variable
  export POPM_STATIC_FEE=$set_fee
}

# Step 1: Stop all old containers
show "Stopping all old PoP mining containers..."
docker ps --filter "name=pop_mining_" --format "{{.ID}}" | xargs -I {} docker stop {}

# Step 2: Remove old containers
show "Removing old PoP mining containers..."
docker ps -a --filter "name=pop_mining_" --format "{{.ID}}" | xargs -I {} docker rm {}

# Step 3: Download the latest version of popmd
LATEST_VERSION="v0.8.0"
ARCH=$(uname -m)

show "Downloading the latest popmd binaries for version $LATEST_VERSION..."

if [ "$ARCH" == "x86_64" ]; then
    wget --quiet --show-progress "https://github.com/hemilabs/heminetwork/releases/download/$LATEST_VERSION/heminetwork_${LATEST_VERSION}_linux_amd64.tar.gz" -O "heminetwork_${LATEST_VERSION}_linux_amd64.tar.gz"
    tar -xzf "heminetwork_${LATEST_VERSION}_linux_amd64.tar.gz" -C ./ 
    mv heminetwork_${LATEST_VERSION}_linux_amd64/keygen ./keygen
    mv heminetwork_${LATEST_VERSION}_linux_amd64/popmd ./popmd
elif [ "$ARCH" == "arm64" ]; then
    wget --quiet --show-progress "https://github.com/hemilabs/heminetwork/releases/download/$LATEST_VERSION/heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz" -O "heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz"
    tar -xzf "heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz" -C ./
    mv heminetwork_${LATEST_VERSION}_linux_arm64/keygen ./keygen
    mv heminetwork_${LATEST_VERSION}_linux_arm64/popmd ./popmd
else
    show "Unsupported architecture: $ARCH"
    exit 1
fi

show "New binaries for version $LATEST_VERSION downloaded."

# Set the number of containers to upgrade automatically to 5
instance_count=5

# Step 5: Check if proxies.txt exists
if [ ! -f "proxies.txt" ]; then
    show "proxies.txt file not found. Exiting."
    exit 1
fi

# Read proxies from the file into an array
mapfile -t proxies < proxies.txt

# Step 6: Upgrade containers with existing wallets
for i in $(seq 1 $instance_count); do
    wallet_file="wallet_$i.json"
    if [ -f "$wallet_file" ]; then
        show "Upgrading container for Wallet $i..."

        # Extract private key from the wallet JSON file
        priv_key=$(jq -r '.private_key' "$wallet_file")

        if [[ -z "$priv_key" ]]; then
            show "Failed to retrieve private key from $wallet_file."
            exit 1
        fi

        # Fetch the dynamic fee
        fetch_dynamic_fee

        # Step 7: Assign SOCKS5 proxy from proxies.txt (if available)
        if [ $i -le ${#proxies[@]} ]; then
            socks5_proxy=${proxies[$((i-1))]}  # Get the proxy for the current container
            show "Using SOCKS5 proxy for container $i: $socks5_proxy"
        else
            socks5_proxy=""
            show "No SOCKS5 proxy for container $i. Proceeding without proxy."
        fi

        # Step 8: Create Dockerfile for the new container
        mkdir -p "pop_container_$i"
        cp keygen popmd pop_container_$i/  # Copy binaries into container directory
        cat << EOF > "pop_container_$i/Dockerfile"
FROM ubuntu:latest
RUN apt-get update && apt-get install -y wget jq curl
COPY ./keygen /usr/local/bin/keygen
COPY ./popmd /usr/local/bin/popmd
RUN chmod +x /usr/local/bin/keygen /usr/local/bin/popmd
WORKDIR /app
CMD ["popmd"]
EOF

        # Step 9: Build the new Docker image
        docker build -t pop_container_$i ./pop_container_$i

        # Step 10: Run the Docker container with or without SOCKS5 proxy
        if [ -n "$socks5_proxy" ]; then
            docker run -d --name pop_mining_$i --env POPM_BTC_PRIVKEY="$priv_key" --env POPM_STATIC_FEE="$POPM_STATIC_FEE" --env POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public --env ALL_PROXY="socks5://$socks5_proxy" pop_container_$i
            show "PoP mining container $i upgraded with SOCKS5 proxy: $socks5_proxy."
        else
            docker run -d --name pop_mining_$i --env POPM_BTC_PRIVKEY="$priv_key" --env POPM_STATIC_FEE="$POPM_STATIC_FEE" --env POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public pop_container_$i
            show "PoP mining container $i upgraded without a proxy."
        fi
    else
        show "Wallet file $wallet_file does not exist. Skipping..."
    fi
done

show "All PoP mining containers have been successfully upgraded to version $LATEST_VERSION."
