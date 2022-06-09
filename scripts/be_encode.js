
const sign = async () => {
    const PRIV_KEY =
    "4c8628e072b120a6952a68f170e362ac9b75c261111acb00a38b6400e4688e7e"; //lấy từ env
    const signer = new ethers.Wallet(PRIV_KEY);
    const to = "0x5C60ac4F76b7Fe79532b93F42F4F5D2F415cC57B"; //request
    const amount = 999; //query in DB amount,if amount < amountDB ok
    const message = "txid"; // generate unique can using now date + address user
    const nonce = 123; // == message
    const hash = ethers.utils.hashMessage(to,amount,message,nonce);
    console.log(hash);
    console.log(await signer.signMessage(ethers.utils.arrayify(hash)));
}
sign()