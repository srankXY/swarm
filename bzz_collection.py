import sys,json
import time

import requests

apiUrl = 'http://127.0.0.1:8080/xdai/'
to_addr = 'd3d78f2aec17fc7eee1d9190d4b03ef7df46392f'
contract_addr = '0xdBF3Ea6F5beE45c02255B2c26a16F300502F68da'

with open("1.txt", 'r') as f:
    pk = f.readlines()

for i in pk:
    i = json.loads(i)
    data = dict({
        "from_addr": i['address'],
        "to_addr": to_addr,
        "priv_key": i['privatekey'],
    })
    # erc20 回收
    data['contract_addr'] = contract_addr
    amount = float(requests.post(url=apiUrl + 'get_erc20_blance/', data={'contract_addr': contract_addr, 'addr': i['address']}).json()['results']['balance'])
    if amount < 0 or amount == 0:
        pass
    else:
        data['amount'] = amount
        print(requests.post(url=apiUrl+'erc20_transfer/', data=data).json())
        time.sleep(3)

    # xdai 回收
    amount = float(requests.post(url=apiUrl+'get_balance/', data={'addr': i['address']}).json()['results']['balance']) - 0.01
    if amount < 0 or amount == 0:
        continue
    else:
        data['amount'] = amount
        print(requests.post(url=apiUrl + 'transfer/', data=data).text)
