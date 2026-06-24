import xrpl from "xrpl";
const wallet = xrpl.Wallet.generate();
console.log(JSON.stringify({
  classicAddress: wallet.classicAddress,
  seed: wallet.seed,
  note: "Private/dev only. Do not use this seed on public networks."
}, null, 2));
