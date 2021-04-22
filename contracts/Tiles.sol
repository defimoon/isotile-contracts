// SPDX-License-Identifier: BUSL-1.1

/*
    This is just a concept, not already published and will be modified
*/

pragma solidity ^0.8.0;

import "./IIsotileFurniture.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tiles is ERC20, ERC20Snapshot, ERC20Capped, ERC20Pausable, Ownable {
    uint256 private lastSnapshotId;
    mapping (address => bool) private communityPartRedeemed;
    mapping (address => mapping (uint256 => bool)) private addressAirdropRedeemed;
    IIsotileFurniture private isotileFurnitureInstance;

    uint256 private cappedSupply = 10000000 ether;
    uint256 private supplyOwnersPercentage = 20;
    uint256 private supplyEventsPercentage = 20;
    uint256 private supplyCommunityPercentage = 60;


    constructor(address _isotileFurnitureAddress) ERC20("Tiles", "TIL") ERC20Snapshot() ERC20Capped(cappedSupply) {
        isotileFurnitureInstance = IIsotileFurniture(_isotileFurnitureAddress);

        ERC20._mint(msg.sender, (cappedSupply * (supplyOwnersPercentage + supplyEventsPercentage))/100);
    }

    function spend(address account, uint256 amount) public {
        require(msg.sender == address(isotileFurnitureInstance), "Only IsotileFurnitureV0 contract can call this function");

        _burn(account, amount);
    }

    function redeemAirdrop() public {
        require(lastSnapshotId > 0, "Airdrop not started");
        require(!addressAirdropRedeemed[msg.sender][lastSnapshotId], "Airdrop already redeemed");

        uint256 airdropTotalNeeded = cap() - totalSupplyAt(lastSnapshotId);
        uint256 percentageOfTilesOwned = ((1 ether) * balanceOfAt(msg.sender, lastSnapshotId))/totalSupplyAt(lastSnapshotId);
        uint256 userRedeem = (airdropTotalNeeded * percentageOfTilesOwned)/(1 ether);

        addressAirdropRedeemed[msg.sender][lastSnapshotId] = true;
        _mint(msg.sender, userRedeem);
    }

    function redeemCommunityPart() public {
        require(!communityPartRedeemed[msg.sender], "Community part already redeemed");

        uint256 totalFurnituresBought = isotileFurnitureInstance.getCountOfFurnituresBought(msg.sender);
        require(totalFurnituresBought > 0, "Not allowed to redeem community part");

        uint256 totalAmountFurnitures = 1000;

        uint256 userCommunityPart = (cappedSupply * supplyCommunityPercentage * totalFurnituresBought)/(100*totalAmountFurnitures);
        communityPartRedeemed[msg.sender] = true;

        _mint(msg.sender, userCommunityPart);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Snapshot, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
    
    function snapshot() onlyOwner public {
        lastSnapshotId = _snapshot();
    }
    
    function pause() onlyOwner public {
        _pause();
    }
      
    function unpause() onlyOwner public {
        _unpause();
    }
    
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}