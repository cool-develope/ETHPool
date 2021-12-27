const ETHPool = artifacts.require('ETHPool')

contract('ETHPool test', async (accounts) => {
    it('It should be success', async () => {
        const instance = await ETHPool.deployed();

        let total_deposit, aBalance, bBalance;

        aBalance = web3.utils.fromWei(await web3.eth.getBalance(accounts[1]));
        bBalance = web3.utils.fromWei(await web3.eth.getBalance(accounts[3]));
        
        await instance.deposit.sendTransaction({from: accounts[1], value: web3.utils.toWei("1.5", "ether")});
        await instance.deposit.sendTransaction({from: accounts[2], value: web3.utils.toWei("2.5", "ether")});
        await instance.deposit.sendTransaction({from: accounts[3], value: web3.utils.toWei("1", "ether")});

        await instance.addReward.sendTransaction({from: accounts[0], value: web3.utils.toWei("0.5", "ether")});

        total_deposit = await instance.totalDeposit.call(); 
        console.log("Total Deposit: ", web3.utils.fromWei(total_deposit));

        await instance.withdraw.sendTransaction({from: accounts[3]});

        await instance.addReward.sendTransaction({from: accounts[0], value: web3.utils.toWei("0.4", "ether")});
        
        console.log("Reward: ", web3.utils.fromWei(await web3.eth.getBalance(accounts[3])) - bBalance);

        total_deposit = await instance.totalDeposit.call();
        console.log("Total Deposit: ", web3.utils.fromWei(total_deposit));

        await instance.withdraw.sendTransaction({from: accounts[1]});

        console.log("Reward: ", web3.utils.fromWei(await web3.eth.getBalance(accounts[1])) - aBalance);
    })
})