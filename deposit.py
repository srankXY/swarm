# from eth_account import Account
# import math
# from hexbytes import HexBytes
# pip install --upgrade pip --trusted-host mirrors.aliyun.com -i http://mirrors.aliyun.com/pypi/simple/

import sys, json
import time

from web3 import Web3
from web3.middleware import geth_poa_middleware

# node = Web3.HTTPProvider('https://goerli.infura.io/v3/2d20ab2e2b8d4fdc92a0870da78107e6')
node = Web3.HTTPProvider('https://rpc.xdaichain.com/')
w3 = Web3(node)
# contract_addr = '0x2aC3c1d3e24b45c6C310534Bc2Dd84B5ed576335'
contract_addr = '0xdBF3Ea6F5beE45c02255B2c26a16F300502F68da'

from_addr = sys.argv[1]
to_addr = sys.argv[3]
to_addr = w3.toChecksumAddress(to_addr)
priv_key = sys.argv[2]
count = int(sys.argv[4])
value = w3.toWei(count, 'ether')

w3.middleware_onion.inject(geth_poa_middleware, layer=0)

def get_eth():
    balance = w3.fromWei(w3.eth.get_balance(to_addr), 'ether')
    print("xeth/xdai balance: %s" % balance)
    return balance

def get_bzz():
    con_addr = w3.eth.contract(address=contract_addr, abi=EIP20_ABI)
    decimals = con_addr.functions.decimals().call()
    DECIMALS = 10 ** decimals
    balance = con_addr.functions.balanceOf(to_addr).call() / DECIMALS
    print("gbzz/xbzz balance: %s" % balance)
    return balance

def send_eth():
    sig_tx = w3.eth.account.sign_transaction(dict(
        nonce=w3.eth.get_transaction_count(from_addr, 'pending'),
        gasPrice=w3.eth.gas_price,
        gas=2000000,
        to=to_addr,
        value=value,
        # data=b'',
        ),
        priv_key,
    )
    reslut = w3.eth.send_raw_transaction(sig_tx.rawTransaction)
    print("xdai/eth send success!!!!!")
    print("txid: %s" % w3.toHex(reslut))
    print("account balance: %s" % w3.fromWei(w3.eth.get_balance(from_addr), 'ether'))


def send_erc20():
    '''ERC20 代币交易'''
    con_addr = w3.eth.contract(address=contract_addr, abi=EIP20_ABI)
    trans = con_addr.functions.transfer(
        to_addr,
        count*10000000000000000,
    ).buildTransaction({
        'chainId': 100,
        'nonce': w3.eth.get_transaction_count(from_addr, 'pending'),
        'gasPrice': w3.eth.gas_price,
        'gas': 2000000,
        'value': 0,
    })
    signed_txn = w3.eth.account.sign_transaction(trans, priv_key)
    reslut = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
    print("xbzz send success!!!!!")
    print("txid: %s" % w3.toHex(reslut))
    print("send account: %s" % count)

def run_eth():
    try:
        send_eth()
    except Exception as e:
        print(e)
        time.sleep(5)
        send_eth()

def run_bzz():
    try:
        send_erc20()
    except Exception as e:
        print(e)
        time.sleep(5)
        send_erc20()

if __name__ == '__main__':
    EIP20_ABI = json.loads('[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_owner","type":"address"},{"indexed":true,"name":"_spender","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Approval","type":"event"}]')

    # print(to_addr)
    # input()
    if sys.argv[5] == 'eth' and get_eth() < 1:
        run_eth()
    if sys.argv[5] == 'bzz' and get_bzz() < 1:
        run_bzz()

    if sys.argv[5] == 'all':
        if get_eth() < 1:
            run_eth()

        time.sleep(5)

        if get_bzz() < 1:
            run_bzz()

        time.sleep(5)