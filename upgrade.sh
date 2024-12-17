if [ $# != 1 ]
then
    echo "USAGE: $0 CHAIN_CODE[TBSC_BNB|ARBITRUM_ETH|BSC_BNB|ETH]"
    exit 1
fi

CHAIN_CODE=$1

mkdir -p ~/.foundry/keystores
account_num=`cast wallet list | wc -l`
if [ $account_num -eq 0 ]
then
    echo "creating local wallet..."
    cast wallet new ~/.foundry/keystores
    if [ $? -ne 0 ]
    then
        echo "failed to create wallet"
        exit 1
    fi
fi

account=`cast wallet list | head -n 1 | awk '{print $1}'`
address=`cast wallet address --account ${account}`
echo "deploy using wallet ${address}"
source .deploy.env
RPC_URL=$(eval echo '$'${CHAIN_CODE}_RPC_URL)
ETHERSCAN_URL=$(eval echo '$'${CHAIN_CODE}_ETHERSCAN_URL)
ETHERSCAN_APIKEY=$(eval echo '$'${CHAIN_CODE}_ETHERSCAN_APIKEY)
export OWNER=$(eval echo '$'${CHAIN_CODE}_OWNER)
export ASSET_FACTORY=$(eval echo '$'${CHAIN_CODE}_ASSET_FACTORY)
export REFER_BUILD_DIR=$(eval echo '$'${CHAIN_CODE}_REFER_BUILD_DIR)
export CHAIN_CODE=${CHAIN_CODE}
forge clean && forge script script/Upgrade.s.sol --legacy --via-ir --account ${account} --rpc-url $RPC_URL \
    --verifier-url $ETHERSCAN_URL --etherscan-api-key $ETHERSCAN_APIKEY --broadcast --verify --ffi -vvv