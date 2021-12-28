const Migrations = artifacts.require("Splitter");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
