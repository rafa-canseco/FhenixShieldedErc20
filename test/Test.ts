import { expect } from "chai";
import { ethers } from "hardhat";
import { WrappingERC2O,Wrapping } from "../../types";
import hre from "hardhat";
import {createFheInstance} from "../utils/instance";
import { deployWrappingERC2OFixture } from "./WrappingERC20.fixture";
import type { Signers } from "../types";

describe("WrappingERC20", function () {
  before(async function () {
    this.signers = {} as Signers;
    const signers = await ethers.getSigners();
    this.signers.alice = signers[0];
    this.signers.bob = signers[1];
});
beforeEach(async function () {
    const { contract, address } = await deployWrappingERC2OFixture();
    this.wrappingERC20 = contract;
    this.contractAddress = address;
    this.instances = await createFheInstance(hre, address);
});

describe("Deployment", function () {
    it("Should deploy the WrappingERC20 contract", async function () {
        expect(this.wrappingERC20.address).to.not.equal(0);
    });
  it("should wrap and unwrap tokens correctly", async function () {
    const wrapAmount = 1;
    const initialAliceBalance = await this.wrappingERC20.balanceOf(this.signers.alice.address);

    await this.wrappingERC20.wrap(wrapAmount);

    const balanceAfterWrapAlice = await this.wrappingERC20.balanceOf(this.signers.alice.address);
    expect(balanceAfterWrapAlice).to.equal(initialAliceBalance.sub(wrapAmount));

    await this.wrappingERC20.unwrap(wrapAmount);

    const finalAliceBalance = await this.wrappingERC20.balanceOf(this.signers.alice.address);
    expect(finalAliceBalance).to.equal(initialAliceBalance);
  });
  it("should allow encrypted token transfer between two users", async function () {
    const wrapAmount = 1000;
    const transferAmount = 500;
    const encryptedTransferAmount = await this.instances.instance.encrypt_uint32(transferAmount);

    // Alice wraps some tokens to get their encrypted version
    await this.wrappingERC20.connect(this.signers.alice).wrap(wrapAmount);

    // Alice transfers encrypted tokens to Bob
    await this.wrappingERC20.connect(this.signers.alice).transferEncrypted(this.signers.bob.address, encryptedTransferAmount);

    // Check that Alice has the correct amount of tokens after the transfer
    const encryptedBalanceAlice = await this.wrappingERC20.encryptedBalanceOf(this.signers.alice.address);
    const balanceAlice = this.instances.instance.unseal(this.contractAddress, encryptedBalanceAlice);
    expect(Number(balanceAlice)).to.equal(wrapAmount - transferAmount);

    // Check that Bob has received the correct amount of encrypted tokens
    const encryptedBalanceBob = await this.wrappingERC20.encryptedBalanceOf(this.signers.bob.address);
    const balanceBob = this.instances.instance.unseal(this.contractAddress, encryptedBalanceBob);
    expect(Number(balanceBob)).to.equal(transferAmount);
  });

  it("should not allow unwrapping more tokens than are wrapped", async function () {
    const wrapAmount = 100;
    const unwrapAmount = 200;

    // Alice wraps some tokens to get their encrypted version
    await this.wrappingERC20.connect(this.signers.alice).wrap(wrapAmount);

    // Attempt to unwrap more tokens than Alice wrapped, which should fail
    await expect(this.wrappingERC20.connect(this.signers.alice).unwrap(unwrapAmount))
      .to.be.revertedWith("FHE operation failed");

    // Check that Alice's encrypted balance remains the same after the failed attempt
    const encryptedBalanceAlice = await this.wrappingERC20.encryptedBalanceOf(this.signers.alice.address);
    const balanceAlice = this.instances.instance.unseal(this.contractAddress, encryptedBalanceAlice);
    expect(Number(balanceAlice)).to.equal(wrapAmount);
  });

})

})


