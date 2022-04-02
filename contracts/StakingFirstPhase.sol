// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract StakingFirstPhase is Ownable, ERC1155Holder {
    IERC721 private avatarContract = IERC721(0x31eAa2E93D7AFd237F87F30c0Dbd3aDEB9934f1B);
    IERC1155 private furnitureContract = IERC1155(0xb644476e44A797Db3B8a6A16f2e63e8D5a541b67);

    mapping (bytes32 => bool) public proofs;
    mapping (address => uint256) public tickets;
    uint256 public totalTickets;
    bool public stakingEnabled = true;
    bool public unstakingEnabled = false;

    event Stake(address indexed userAddress, uint256[] avatarIds, uint256[] furnitureIds, uint256[] furnitureAmounts);
    event Unstake(address indexed userAddress, uint256[] avatarIds, uint256[] furnitureIds, uint256[] furnitureAmounts);
    
    constructor() {}
    
    function stake(uint256[] calldata avatarIds, uint256[] calldata furnitureIds, uint256[] calldata furnitureAmounts) external {
        require(stakingEnabled, "Staking is disabled");

        bytes32 proof = keccak256(abi.encode(_msgSender(), avatarIds, furnitureIds, furnitureAmounts));
        require(!proofs[proof], "No reentrancy attacks allowed");

        proofs[proof] = true;

        uint256 earnedTickets;

        uint256 avatarsLength = avatarIds.length;
        for(;earnedTickets < avatarsLength;) {
            avatarContract.transferFrom(_msgSender(), address(this), avatarIds[earnedTickets]);

            unchecked {
                ++earnedTickets;
            }
        }

        uint256 furnitureLength = furnitureIds.length;
        if(furnitureLength > 0){
            furnitureContract.safeBatchTransferFrom(_msgSender(), address(this), furnitureIds, furnitureAmounts, "");

            for(uint256 i = 0; i < furnitureLength;) {
                require(furnitureIds[i] < 4, "Only mega-rare furnitures");

                unchecked {
                    earnedTickets += furnitureAmounts[i++];
                }
            }
        }

        unchecked {
            tickets[_msgSender()] += earnedTickets;
            totalTickets += earnedTickets;
        }

        emit Stake(_msgSender(), avatarIds, furnitureIds, furnitureAmounts);
    }

    function unstake(uint256[] calldata avatarIds, uint256[] calldata furnitureIds, uint256[] calldata furnitureAmounts) external {
        require(unstakingEnabled, "Unstaking is disabled");

        bytes32 proof = keccak256(abi.encode(_msgSender(), avatarIds, furnitureIds, furnitureAmounts));
        require(proofs[proof], "Proof does not exist");

        delete proofs[proof];

        uint256 avatarsLength = avatarIds.length;
        for(uint256 i = 0; i < avatarsLength;) {
            avatarContract.transferFrom(address(this), _msgSender(), avatarIds[i]);

            unchecked {
                ++i;
            }
        }

        uint256 furnitureLength = furnitureIds.length;
        if(furnitureLength > 0){
            furnitureContract.safeBatchTransferFrom(address(this), _msgSender(), furnitureIds, furnitureAmounts, "");
        }

        emit Unstake(_msgSender(), avatarIds, furnitureIds, furnitureAmounts);
    }

    function enableStaking() external onlyOwner {
        require(!unstakingEnabled, "First disable unstaking");
        stakingEnabled = true;
    }

    function disableStaking() external onlyOwner {
        stakingEnabled = false;
    }

    function enableUnstaking() external onlyOwner {
        require(!stakingEnabled, "First disable staking");
        unstakingEnabled = true;
    }

    function disableUnstaking() external onlyOwner {
        unstakingEnabled = false;
    }

}