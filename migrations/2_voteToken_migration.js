const voteToken = artifacts.require("voteToken");

module.exports = function(deployer) {
  deployer.deploy(voteToken);
};
