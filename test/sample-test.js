const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RiderToken", function () {
  it("Should return the new riderToken once it's changed", async function () {
    const RiderToken = await ethers.getContractFactory("Rider");
    const riderToken = await RiderToken.deploy("RiderToken", "RT");
    await riderToken.deployed();

    expect(await riderToken.totalSupply()).to.equal("0");

    const [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    let tx = await riderToken.mint(owner.address, '10000');
    await tx.wait();

    expect(await riderToken.totalSupply()).to.equal("10000");
    expect(await riderToken.balanceOf(owner.address)).to.equal("10000");

    const Staking = await ethers.getContractFactory("Staking");
    const staking = await Staking.deploy();
    await staking.deployed();

    tx = await staking.setTokenAddress(riderToken.address);
    await tx.wait();

    expect(await staking.rtAddress()).to.equal(riderToken.address);

    tx = await riderToken.approve(staking.address, '100');
    await tx.wait();

    tx = await staking.stake('100');
    await tx.wait();

    expect(await riderToken.balanceOf(owner.address)).to.equal("9900");
    expect(await riderToken.balanceOf(staking.address)).to.equal("100");

    let stakingInfo = await staking.getStakingInfo(owner.address);
    expect(stakingInfo[1].length).to.equal(1);
    expect(stakingInfo[1][0].toString()).to.equal('100');
    expect(stakingInfo[2][0].toString()).to.equal('0');

    expect(await staking.getTotalClaimable(owner.address)).to.equal('0');

    tx = await riderToken.approve(staking.address, '100');
    await tx.wait();

    tx = await staking.stake('100');
    await tx.wait();

    stakingInfo = await staking.getStakingInfo(owner.address);
    expect(stakingInfo[1].length).to.equal(2);
    expect(stakingInfo[1][0].toString()).to.equal('100');
    expect(stakingInfo[2][0].toString()).to.equal('0');
    expect(stakingInfo[1][1].toString()).to.equal('100');
    expect(stakingInfo[2][1].toString()).to.equal('0');

    expect(await staking.getTotalClaimable(owner.address)).to.equal('200');

    expect(await riderToken.balanceOf(owner.address)).to.equal('9800');

    tx = await staking.claim('10');
    await tx.wait();

    expect(await riderToken.balanceOf(owner.address)).to.equal("9810");

    stakingInfo = await staking.getStakingInfo(owner.address);
    expect(stakingInfo[1].length === 2)
    expect(stakingInfo[1][0].toString()).to.equal('100');
    expect(stakingInfo[2][0].toString()).to.equal('10');
    expect(stakingInfo[1][1].toString()).to.equal('100');
    expect(stakingInfo[2][1].toString()).to.equal('0');

    expect(await staking.getTotalClaimable(owner.address)).to.equal('390');

    tx = await staking.claim('200');
    await tx.wait();

    expect(await riderToken.balanceOf(owner.address)).to.equal("10010");

    stakingInfo = await staking.getStakingInfo(owner.address);
    expect(stakingInfo[1].length).to.equal(2);
    expect(stakingInfo[1][0].toString()).to.equal('100');
    expect(stakingInfo[2][0].toString()).to.equal('210');
    expect(stakingInfo[1][1].toString()).to.equal('100');
    expect(stakingInfo[2][1].toString()).to.equal('0');

    expect(await staking.getTotalClaimable(owner.address)).to.equal('390');

    tx = await staking.unstake('150');
    await tx.wait();

    stakingInfo = await staking.getStakingInfo(owner.address);
    expect(stakingInfo[1].length).to.equal(1)
    expect(stakingInfo[1][0].toString()).to.equal('50');
    expect(stakingInfo[2][0].toString()).to.equal('0');

    expect(await riderToken.balanceOf(owner.address)).to.equal('10750');

    tx = await staking.unstake('50');
    await tx.wait();

    stakingInfo = await staking.getStakingInfo(owner.address);
    expect(stakingInfo[0].length === 0)

    expect(await riderToken.balanceOf(owner.address)).to.equal('10850');
  });
});
