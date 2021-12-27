const Migrations = artifacts.require("ETHPool");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
