First of all put proxies in `proxies.txt` using 
```bash
nano proxies.txt
```

After that use use `wallet_i.json` to put your private key, public key, public hash(tbtc address) etc... 
create as much as you want like- 
for 5 wallets create 5 files named like-- using 
```bash
nano wallet_1.json
```

`wallet_1.json , wallet_2.json, wallet_3.json` 
etc 
To get these you can check- https://testnet.popstats.hemi.network

search your address here 

you'll get all your details like eth address, tbtc address, public key etc 

intall these 
```bash
sudo apt-get update
sudo apt-get install -y wget jq curl
```
and 
```bash
sudo apt-get install figlet 
```
make script executable using 
```bash
 chmod +x hemi.sh
```
then run it using
```bash
 ./hemi.sh
```
Make sure you already have installed 
docker and docker compose...
Commit #1 on 2024-01-10
Commit #2 on 2024-01-18
Commit #3 on 2024-02-01
Commit #4 on 2024-02-04
Commit #5 on 2024-02-09
