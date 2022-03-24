// SPDX-License-Identifier: MIT
//  Cross-Conract Sol
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface RTInterface {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function allowance(address owner, address spender)
        external
        returns (uint256);
}

contract Staking {
    struct Stake {
        uint256 timestamp;
        uint256 amount;
    }
    mapping(address => Stake[]) staked;
    mapping(address => uint256[]) claimed;
    address public rtAddress;

    constructor() {}

    function setTokenAddress(address addr) external {
        rtAddress = addr;
    }

    function stake(uint256 amount) external {
        require(rtAddress != address(0), "Token Contract is not set");
        require(
            RTInterface(rtAddress).balanceOf(msg.sender) >= amount,
            "Insufficient funds"
        );
        require(
            RTInterface(rtAddress).allowance(msg.sender, address(this)) >=
                amount,
            "Insufficient allowance"
        );
        staked[msg.sender].push(Stake(block.number, amount));
        RTInterface(rtAddress).transferFrom(msg.sender, address(this), amount);
        claimed[msg.sender].push(0);
    }

    function getClaimable(uint256 amount, uint256 start)
        internal
        view
        returns (uint256)
    {
        return amount * (block.number - start);
    }

    function getTotalClaimable(address addr) public view returns (uint256) {
        uint256 i;
        uint256 balance;
        uint256 length = staked[addr].length;
        for (i = 0; i < length; ++i) {
            balance +=
                getClaimable(
                    staked[addr][i].amount,
                    staked[addr][i].timestamp
                ) -
                claimed[addr][i];
        }
        return balance;
    }

    function claim(uint256 amount) public {
        require(rtAddress != address(0), "Token Contract is not set");
        require(
            getTotalClaimable(msg.sender) >= amount,
            "Exceeds current claimable"
        );
        uint256 i;
        uint256 length = staked[msg.sender].length;
        uint256 claimable;
        uint256 claimAmount = amount;
        for (i = 0; i < length && amount > 0; ) {
            claimable =
                getClaimable(
                    staked[msg.sender][i].amount,
                    staked[msg.sender][i].timestamp
                ) -
                claimed[msg.sender][i];
            if (claimable > amount) {
                claimed[msg.sender][i] += amount;
                amount = 0;
            } else {
                amount -= claimable;
            }
        }
        RTInterface(rtAddress).mint(msg.sender, claimAmount);
    }

    function claimAll() external {
        require(rtAddress != address(0), "Token Contract is not set");
        uint256 totalClaimable = getTotalClaimable(msg.sender);
        require(totalClaimable > 0, "No token to be claimed");
        uint256 i;
        uint256 length = staked[msg.sender].length;
        uint256 claimable;
        for (i = 0; i < length; ++i) {
            claimable =
                getClaimable(
                    staked[msg.sender][i].amount,
                    staked[msg.sender][i].timestamp
                ) -
                claimed[msg.sender][i];
            claimed[msg.sender][i] += claimable;
        }
        RTInterface(rtAddress).mint(msg.sender, totalClaimable);
    }

    function unstake(uint256 amount) external {
        require(rtAddress != address(0), "Token Contract is not set");
        uint256 i;
        uint256 totalStaked;
        uint256 length = staked[msg.sender].length;
        uint256 claimable;
        uint256 unstakeAmount = amount;
        uint256 remainedStaking;
        for (i = 0; i < length && totalStaked < amount; ++i) {
            totalStaked += staked[msg.sender][i].amount;
        }
        require(amount <= totalStaked, "Insufficient funds to unstake");
        for (i = 0; amount > 0; ) {
            if (amount >= staked[msg.sender][i].amount) {
                amount -= staked[msg.sender][i].amount;
                remainedStaking = 0;
            } else {
                remainedStaking = staked[msg.sender][i].amount - amount;
                amount = 0;
            }
            claimable +=
                getClaimable(
                    staked[msg.sender][i].amount,
                    staked[msg.sender][i].timestamp
                ) -
                claimed[msg.sender][i];
            --length;
            staked[msg.sender][i] = staked[msg.sender][length];
            staked[msg.sender].pop();
            claimed[msg.sender][i] = claimed[msg.sender][length];
            claimed[msg.sender].pop();
            if (remainedStaking > 0) {
                staked[msg.sender].push(Stake(block.number, remainedStaking));
                claimed[msg.sender].push(0);
            }
        }
        RTInterface(rtAddress).transfer(msg.sender, unstakeAmount);
        RTInterface(rtAddress).mint(msg.sender, claimable);
    }

    function getStakingInfo(address addr)
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 i;
        uint256 length = staked[addr].length;
        uint256[] memory timestamp = new uint256[](length);
        uint256[] memory amount = new uint256[](length);
        for (i = 0; i < length; ++i) {
            timestamp[i] = staked[addr][i].timestamp;
            amount[i] = staked[addr][i].amount;
        }
        return (timestamp, amount, claimed[addr]);
    }
}
