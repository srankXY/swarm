# from eth_account import Account
# import math
# from hexbytes import HexBytes
# pip install --upgrade pip --trusted-host mirrors.aliyun.com -i http://mirrors.aliyun.com/pypi/simple/

import sys,json
from web3 import Web3
from web3.middleware import geth_poa_middleware

node = Web3.HTTPProvider('https://rpc.kiln.themerge.dev')
w3 = Web3(node)
contract_addr = '0xdBF3Ea6F5beE45c02255B2c26a16F300502F68da'

# from_addr = '0x31a24fEFE2B4E595505021E42c797E0eecAfccB1'
# priv_key = '2601098255ce07d1d386fac9633631e49fe2b4ebb7bdb1378a4c837f8733631e'
from_addr = '0x99aF1303b692e3A502ff57f99BdDb4eD0CbBA475'
priv_key = 'bf3dfc4a06a993e2fe63ca3b09f39de77b61d2c6002d821162ef384d2c7d82a6'

to_addr = w3.toChecksumAddress('0x96F23019BdF9785c9a3f20AeEE86A3F15819a312')
value = w3.toWei(0.1, 'ether')

w3.middleware_onion.inject(geth_poa_middleware, layer=0)

def send_eth():
    sig_tx = w3.eth.account.sign_transaction(dict(
        nonce=w3.eth.get_transaction_count(from_addr),
        gasPrice=w3.eth.gas_price,
        chainId=w3.eth.chainId,
        gas=100000,
        to=to_addr,
        value=value,
        # data=b'',
        ),
        priv_key,
    )
    reslut = w3.eth.send_raw_transaction(sig_tx.rawTransaction)
    print("eth send success!!!!!")
    print("txid: %s" % w3.toHex(reslut))
    print("account balance: %s" % w3.fromWei(w3.eth.get_balance(from_addr), 'ether'))


def send_erc20():
    '''ERC20 代币交易'''
    con_addr = w3.eth.contract(address=contract_addr, abi=EIP20_ABI)
    trans = con_addr.functions.transfer(
        to_addr,
        1*10000000000000000,
    ).buildTransaction({
        'chainId': 100,
        'nonce': w3.eth.get_transaction_count(from_addr, 'pending'),
        'gasPrice': w3.eth.gas_price,
        'gas': 500000,
        'value': 0,
    })
    signed_txn = w3.eth.account.sign_transaction(trans, priv_key)
    reslut = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
    print("bzz send success!!!!!")
    print('to addr: %s' % to_addr)
    print("txid: %s" % w3.toHex(reslut))
    print("send account: %s" % 1)

if __name__ == '__main__':
    EIP20_ABI = json.loads('[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_owner","type":"address"},{"indexed":true,"name":"_spender","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Approval","type":"event"}]')

    # print(abi)
    # send_erc20()
    send_eth()