const { ethers } = require("hardhat");

const main = async () => {
  const [owner, addr1, addr2] = await ethers.getSigners();

  const contractFactory = await hre.ethers.getContractFactory("CropInsurance");
  const contract = await contractFactory.deploy();
  await contract.deployed();
  console.log("Contract deployed to:", contract.address);

  let registerTxn = await contract.connect(addr1).startInsurancePeriod(50, 300, 700, { value: ethers.utils.parseUnits("1", "ether")});
  await registerTxn.wait();

  insurer = await contract.insurer();
  console.log("Insurer: ", insurer);

  let registerUserTxn = await contract.connect(addr2).registerUser("farmer1", 46, 0, { value: ethers.utils.parseUnits("0.01", "ether")});
  await registerUserTxn.wait();

  let registeredUsers = await contract.policyHolders(`${addr2.address}`);
  console.log(registeredUsers);

  let payInstallmentTxn = await contract.connect(addr2).payInstallment({value: ethers.utils.parseEther("0.01")});
  await payInstallmentTxn.wait();

  registeredUsers = await contract.policyHolders(`${addr2.address}`);
  console.log(registeredUsers);

  payInstallmentTxn = await contract.connect(addr2).payInstallment({value: ethers.utils.parseEther("0.01")});
  await payInstallmentTxn.wait();

  registeredUsers = await contract.policyHolders(`${addr2.address}`);
  console.log(registeredUsers);

};

const runMain = async () => {
  try {
    await main();
    process.exit(0); // exit Node process without error
  } catch (error) {
    console.log(error);
    process.exit(1); // exit Node process while indicating 'Uncaught Fatal Exception' error
  }
  // Read more about Node exit ('process.exit(num)') status codes here: https://stackoverflow.com/a/47163396/7974948
};

runMain();