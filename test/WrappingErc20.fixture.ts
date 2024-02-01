import hre from "hardhat";

import type { WrappingERC2O } from "../../types";

export async function deployWrappingERC2OFixture(): Promise<{ contract: WrappingERC2O; address: string }> {
  const accounts = await hre.ethers.getSigners();
  const contractOwner = accounts[0];

  const contractFactory = await hre.ethers.getContractFactory("WrappingERC2O");
  const contract = await contractFactory.connect(contractOwner).deploy("Fhenix", "FHE"); // City of Zama's battle
  await contract.waitForDeployment();
  const address = await contract.getAddress();

  return { contract, address };
}