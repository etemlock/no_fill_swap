const Token = artifacts.require("Token");
const NFSwap = artifacts.require("NFSwap");

module.exports = async function(deployer) {
  //Deploy Token
  await deployer.deploy(Token);
  const token = await Token.deployed();

  //Deploy NFSwap
  await deployer.deploy(NFSwap, token.address);
  const nfswap = await NFSwap.deployed();

  //transfers full supply to NFSwap contract
  await token.transfer(nfswap.address, '1000000000000000000000000')
};