#!/bin/bash

function echo_blue_bold {
    echo -e "\033[1;34m$1\033[0m"
}

# Install necessary packages
echo_blue_bold "Installing necessary packages..."
sudo apt update
sudo apt install -y curl git jq build-essential

# Install Node.js and npm if not installed
if ! command -v node &> /dev/null
then
    echo_blue_bold "Installing Node.js..."
    curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# Install npm@10.8.1 globally if not installed
if ! npm list -g npm@10.8.1 >/dev/null 2>&1; then
  echo_blue_bold "Installing npm@10.8.1..."
  npm install -g npm@10.8.1
  echo
else
  echo_blue_bold "npm@10.8.1 is already installed."
fi

# Install ethers@5.5.4 if not installed
if ! npm list -g ethers@5.5.4 >/dev/null 2>&1; then
  echo_blue_bold "Installing ethers@5.5.4..."
  npm install -g ethers@5.5.4
  echo
else
  echo_blue_bold "Ethers is already installed."
fi

echo

echo_blue_bold "Enter RPC URL of the network:"
read providerURL
echo
echo_blue_bold "Enter contract address:"
read contractAddress
echo
echo_blue_bold "Enter transaction data (in hex):"
read transactionData
echo
echo_blue_bold "Enter gas limit:"
read gasLimit
echo
echo_blue_bold "Enter gas price (in gwei):"
read gasPrice
echo
echo_blue_bold "Enter number of transactions to send:"
read numberOfTransactions
echo

temp_node_file=$(mktemp /tmp/node_script.XXXXXX.js)

cat << EOF > $temp_node_file
const ethers = require("ethers");

const providerURL = "${providerURL}";
const provider = new ethers.providers.JsonRpcProvider(providerURL);

const privateKeys = process.env.PRIVATE_KEY;

const contractAddress = "${contractAddress}";

const transactionData = "${transactionData}";

const numberOfTransactions = ${numberOfTransactions};

async function sendTransaction(wallet) {
    const tx = {
        to: contractAddress,
        value: 0,
        gasLimit: ethers.BigNumber.from(${gasLimit}),
        gasPrice: ethers.utils.parseUnits("${gasPrice}", 'gwei'),
        data: transactionData,
    };

    try {
        const transactionResponse = await wallet.sendTransaction(tx);
        console.log("\033[1;35mTx Hash:\033[0m", transactionResponse.hash);
        const receipt = await transactionResponse.wait();
        console.log("");
    } catch (error) {
        console.error("Error sending transaction:", error);
    }
}

async function main() {
    const wallet = new ethers.Wallet(privateKeys, provider);

    for (let i = 0; i < numberOfTransactions; i++) {
        console.log("Sending transaction", i + 1, "of", numberOfTransactions);
        await sendTransaction(wallet);
        // Random delay between 10 and 40 seconds
        const delay = Math.floor(Math.random() * (40000 - 10000 + 1)) + 10000;
        console.log(\`Waiting for \${delay / 1000} seconds...\`);
        await new Promise(resolve => setTimeout(resolve, delay));
    }
}

main().catch(console.error);
EOF

NODE_PATH=$(npm root -g):$(pwd)/node_modules node $temp_node_file

rm $temp_node_file
echo
echo_blue_bold "stay frosty"
echo
