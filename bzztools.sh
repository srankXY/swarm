#!/usr/bin/env bash

workdir=/bee
tmp_files_url='http://git.168node.com/yangxilin/crust/raw/master/swarm/bzz.tgz' # 定义模板文件位置
celf_version=0.4.12                                                             # 版本信息请上官网查看后填写正确
bee_version=1.0.0

tmp_api=8003   # 模板api 端口
tmp_p2p=8004   # 模板p2p 端口
tmp_debug=8005 # 模板debug 端口

helper() {
  echo -e '\n useage: \n
  -h,                   open this help info \n
  deploy,               params {int}, example:10,20 \n
  get_eth_addr,         show all node eth addr \n
  install_exportKey     install exportSwarmKey tools \n
  exportKey             export all swarm Keys \n
  conf,                 alter specify config file, supported {alter | add | del} \n
                        "alter | add | del" supported params is "filename old_value new_value"
  upgrade|downgarde,    params {bee version, bee_celf version, cashout_shell} \n
  start,                start all bee node \n
  deposit,              supported {bzz | eth}， deposit bzz and eth to current addr \n
                        bzz|eth params [int] {1,2,3} \n
                        first deploy, u no need to set deposit params, please use: "bzztools deposit" \n
                        deposit support breakpoint continue, if u exit while depositing, u can just use:"bzztools deposit" continue\n
  stats，                supported {"node-info" | status | cashout},\n
                        "status" return all node current api status, \n
                        "node-info" supported {peer | cheque {-c} | cheque_address | all_address | cheque_balance | settlements} return all node "related" info.\n
                        "cashout" default return all node latest cashout sum info, use -v show detail info\n
  cashout,              cashout node cheque, supported { cashout-all null | 5 | 10} \n
  install_celf,         install bee-clef for keys \n
  default deploy celf version 0.4.12, bee version 0.6.2,\n
  if u want deploy other version, please open "https://github.com/ethersphere/bee/releases" for query other version \n

  example: \n
  bash bzztools.sh deploy 20 \n
  bash bzztools.sh get_eth_addr \n
  bash bzztools.sh conf alter cashout.sh MIN_AMOUNT=10000000000000000 MIN_AMOUNT=1000 \n
  bash bzztools.sh start \n
  bash bzztools.sh cashout cashout-all 1\n
  bash bzztools.sh stats status \n
  bash bzztools.sh stats peer \n
  bash bzztools.sh deposit bzz 1 \n
  bash bzztools.sh upgrade bee 0.6.2'
}

install_celf() {
  cd $workdir
  wget https://github.com/ethersphere/bee-clef/releases/download/v${celf_version}/bee-clef_${celf_version}_amd64.deb
  sudo dpkg -i bee-clef_${celf_version}_amd64.deb && rm -rf bee-clef_${celf_version}_amd64.deb
  sudo service start bee-clef && sudo systemctl enable bee-celf
  if [[ $(grep -elf bee-clef | grep -v grep) ]]; then echo -e "\n !!!!!!!!!!!!!! \e[5;36m bee-clef runing \e[0m !!!!!!!!!!!!\n"; fi
}

install_exportKey(){
  wget -O $workdir/bin/exportKey https://github.com/ethersphere/exportSwarmKey/releases/download/v0.1.0/export-swarm-key-linux-amd64
  chmod +x $workdir/bin/exportKey
}

exportKey(){
  for i in $(ls -d $workdir/* | grep -vE "bin|\."); do
    cd $i
    get_eth_addr
    echo -e "\n -----------------in $i-------------------- \n
    eth addr: $ETH_ADDRESS"
    $workdir/bin/exportKey data/keys/ $(cat password)
  done
}
conf(){
  file=$2
  alter(){
    old_value=$(echo ${1//'/'/'\/'})
    new_value=$(echo ${2//'/'/'\/'})
    for i in $(find $workdir -name "$file");do sed -i "s/$old_value/$new_value/g" $i;echo -e "$i alter success.. \n";done
  }
  add(){
    new_value=$1
    for i in $(find $workdir -name "$file");do sed -i "2a $new_value" $i;echo -e "$i add success.. \n";done
  }
  del(){
    value=$1
    for i in $(find $workdir -name "$file");do sed -i "/$value/d" $i;echo -e "$i del success.. \n";done
  }
  case $1 in
    alter)
      alter "$3" "$4"
    ;;
    add)
      add "$3"
    ;;
    del)
      del "$3"
  esac
}

install_bee() {
  mkdir -p $workdir/bin
  wget -O $workdir/bin/bee https://github.com/ethersphere/bee/releases/download/v${bee_version}/bee-linux-amd64
  chmod +x $workdir/bin/bee
}

alter_open_limit() {
  sed -i '/nofile 65535/d' /etc/security/limits.conf
  sed -i '/SHn 65535/d' /etc/profile
  sed -i '$a * soft nofile 65535' /etc/security/limits.conf
  sed -i '$a * hard nofile 65535' /etc/security/limits.conf
  echo "ulimit -SHn 65535" >>/etc/profile
  ulimit -n 65535
}

deploy() {
  deploy_count=$1 # 同一个服务器部署多少个节点
  for ((i = 1; i <= deploy_count; i++)); do
    mkdir ${workdir}/${tmp_p2p}
    cd ${workdir}/${tmp_p2p} && wget -O bzz.tgz ${tmp_files_url}
    tar -zxf bzz.tgz && rm -rf bzz.tgz
    bash init.sh init ${tmp_api} ${tmp_p2p} ${tmp_debug} ${pub_ip}
    tmp_api=$((tmp_api + 100))
    tmp_p2p=$((tmp_p2p + 100))
    tmp_debug=$((tmp_debug + 100))
  done
}

start() {
  for i in $(ls -d ${workdir}/* | grep -vE "bin|\."); do
    cd $i # sed -i 's/# pass/pass/' bee.yaml
    bash ./start.sh 2>/dev/null && echo "$i start ok.."
    sleep 1
  done
}

withdraw() {
  amount=$(($1*10000000000000000))
  for i in $(ls -d ${workdir}/* | grep -vE "bin|\."); do
    curl -s -XPOST http://localhost:$(($(echo $i | awk -F'/' '{print $NF}')+1))/chequebook/withdraw\?amount\=${amount} | jq && echo "$i withdraw $1 ok.."
    sleep 2
  done
}

get_eth_addr() {
    RESP=$($workdir/bin/bee init --config ./bee.yaml 2>&1)
    ETH_ADDRESS=$(echo "$RESP" | grep ethereum | cut -d' ' -f6 | tr -d '"')
}
deposit() {
  helper(){
    echo -e "\n usage: \n
    -h,              show deposit help info \n
    eth,             deposit eth to all node addr, supported params [int] {1,2,3} \n
    bzz,             deposit bzz to all node addr, supported params [int] {1,2,3} \n
    example: \n
    bzztools deposit eth 1 | bzz 1 \n
    bzztools deposit"
  }

  coin() {
    coin=$1
    count=$2
    for i in $(ls -d $workdir/* | grep -vE "bin|\."); do
#      if [[ $(ps -elf | grep $i | grep -v grep) ]]; then
#        echo -e "$i is already runing.."
#      else
      cd $i
      get_eth_addr
      echo -e "------------------- in $i ----------------------"
      echo -e "to addr is: $ETH_ADDRESS"
      bash -c "python3 $workdir/deposit.py $from_addr $from_addr_key $ETH_ADDRESS $count $coin"
      echo -e ""
      sleep 1
#      fi
    done
  }
  wget -O $workdir/deposit.py http://git.168node.com/yangxilin/crust/raw/master/swarm/deposit.py
  read -p "from addr:" from_addr
  read -p "from addr key:" from_addr_key
  case $1 in
    eth|bzz)
      count=$2
      if [[ ! $2 ]];then count=1;fi
      coin $1 $count
      ;;
    -h|*)
      if [[ $# == 0 ]];then
        coin 'all' 1
      else
        helper
      fi
  esac
  rm -rf $workdir/deposit.py
}

stats() {
  method=$1
  main() {

    for i in $(ls -d $workdir/* | grep -vE "bin|\."); do
      cd $i
      cmd=$(cat query.txt | grep $method | awk -F'"' '{print $2}')
      reslut=$(bash -c "$cmd")
      if [[ $method == 'cheque' && $1 == '-c' ]];then
        cheque_address=$(cat query.txt | grep cheque_address | awk -F'"' '{print $2}')
        cheque_count=$(echo $reslut | grep -c peer)
        echo -e "\n -----------------in $i-------------------- \n
$($cheque_address)
uncashout cheque count:  $cheque_count"
      else
        if [[ $reslut ]]; then
          echo -e "\n -----------------in $i-------------------- \n
$reslut "
        else
          echo -e "\n -----------------in $i-------------------- \n
\e[5;36m node api run faild!! \e[0m"
        fi
      fi
    done
  }

  cashout() {
    for i in $(ls -d $workdir/* | grep -vE "bin|\."); do
      cd $i
      cheque_address=$(cat query.txt | grep cheque_address | awk -F'"' '{print $2}')
      if [[ $1 == '-v' ]]; then
        echo -e "\n -----------------in $i-------------------- \n
$($cheque_address)"
        cat ./logs/cashout.log
      elif [[ ! $1 ]]; then
        count=$(cat ./logs/cashout.log | grep -c transaction)
        echo -e "\n -----------------in $i-------------------- \n
$($cheque_address) \n
latest_cheque_coutn: $count "
      else
        echo -e "\n cashout usage: \n
        -h,       show help info \n
        -v,       show latest cashout detail info, example: \n
        bzztools stats cashout -v \n
                       cashout"
        exit
      fi
    done
  }
  case $1 in
  cashout)
    cashout $2
    ;;
  -h)
    helper
    ;;
  *)
    main $2
    ;;
  esac
}

cashout() {
  cashout_all=$1
  count=$2
  for i in $(ls -d $workdir/* | grep -vE "bin|\."); do
    cd $i
    if [[ $# == 0 ]];then
      echo -e "------------------- in $i ------------------------ \n"
      bash cashout.sh
    else
      echo -e "------------------- in $i ------------------------ \n"
      bash cashout.sh $cashout_all $count | tee ./logs/cashout.log
    fi
  done
}

upgrade() {
  bee() {
    bee_version=$1
    rm -rf ${workdir}/bin/bee
    wget -O $workdir/bin/bee https://github.com/ethersphere/bee/releases/download/v${bee_version}/bee-linux-amd64
    chmod +x $workdir/bin/bee
  }
  cashout_shell(){
    for i in $(ls -d $workdir/* | grep -vE "bin|\."); do
      cd $i
      curl -s https://gist.githubusercontent.com/ralph-pichler/3b5ccd7a5c5cd0500e6428752b37e975/raw/cashout.sh | cat > cashout.sh && echo -e "$i upgrade success.."
    done
  }
  case $1 in
  bee)
    bee $2
    ;;
  cashout_shell)
    cashout_shell
    ;;
  *)
    helper
    ;;
  esac
}

case $1 in
  deploy)
    alter_open_limit
    apt install -y wget
    apt install jq -y
    #    install_celf
    apt update -y && apt list --upgradable && apt install python3-pip -y
    pip3 install web3 -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
    rm -rf /var/spool/cron/crontabs/root
    install_bee
    pub_ip=$(curl ifconfig.io 2> /dev/null)
    deploy $2
    chmod +x $workdir/bzztools.sh && ln -s $workdir/bzztools.sh /usr/bin/bzztools
    echo -e "-------------------------------------------------- \n
              $($workdir/bin/bee version) \n
      --------------------------------------------------- \n"
    chown root.crontab /var/spool/cron/crontabs/root && chmod 600 /var/spool/cron/crontabs/root
    service cron restart
    ;;
  upgrade | downgarde)
    upgrade $2 $3
    ;;
  start)
    start
    ;;
  get_eth_addr)
    for i in $(ls -d $workdir/* | grep -vE "bin|\."); do
      cd $i;get_eth_addr
      echo -e "\n -----------------in $i-------------------- \n
eth addr: $ETH_ADDRESS "
    done
    ;;
  deposit)
    deposit $2 $3
    ;;
  stats)
    stats $2 $3
    ;;
  cashout)
    cashout $2 $3
    ;;
  conf)
    conf $2 $3 "$4" "$5"
    ;;
  install_celf)
    install_celf
    ;;
  install_exportKey)
    install_exportKey
    ;;
  exportKey)
    exportKey
    ;;
  withdraw)
    withdraw $2
    ;;
  -h | *)
    helper
    ;;
esac
