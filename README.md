First of all put proxies in `proxies.txt`
After that use use `wallet_i.json`
to put your private key, public key, public hash(tbtc address) etc... 
create as much as you want like- 
for 5 wallets create 5 files named like-- 
`wallet_1.json , wallet_2.json, wallet_3.json` 
etc 
To get these you can check- https://testnet.popstats.hemi.network/
search your address here 
you'll get all your details like eth address, tbtc address, public key etc 

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
