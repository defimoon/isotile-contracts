// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ERC20Snapshot.sol";
import "./IIsotileFurniture.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tiles is ERC20, ERC20Snapshot, ERC20Capped, Ownable {
    mapping (address => bool) private communityPartRedeemed;
    mapping (address => mapping (uint256 => bool)) private addressAirdropRedeemed;
    IIsotileFurniture private isotileFurnitureInstance;

    uint256 private cappedSupply = 10000000 ether;
    uint256 private supplyOwnersPercentage = 0.2 ether;
    uint256 private supplyEventsPercentage = 0.2 ether;
    uint256 private supplyCommunityPercentage = 0.6 ether;


    constructor(address _isotileFurnitureAddress) ERC20("Tiles", "TIL") ERC20Snapshot() ERC20Capped(cappedSupply) {
        isotileFurnitureInstance = IIsotileFurniture(_isotileFurnitureAddress);

        _mint(msg.sender, cappedSupply * (supplyOwnersPercentage + supplyEventsPercentage));
    }

    function burnFromFurnitureSpending(address account, uint256 amount) public {
        require(msg.sender == address(isotileFurnitureInstance), "Only IsotileFurnitureV0 contract can call this function");

        _burn(account, amount);
    }

    function redeemAirdrop() public {
        require(!addressAirdropRedeemed[msg.sender][getCurrentSnapshotId()], "Airdrop already redeemed");

        uint256 airdropTotalNeeded = cap() - totalSupplyAt(getCurrentSnapshotId());
        uint256 percentageOfTilesOwned = balanceOfAt(msg.sender, getCurrentSnapshotId())/totalSupplyAt(getCurrentSnapshotId());
        uint256 userRedeem = airdropTotalNeeded * percentageOfTilesOwned;

        addressAirdropRedeemed[msg.sender][getCurrentSnapshotId()] = true;
        _mint(msg.sender, userRedeem);
    }

    function redeemCommunityPart() public {
        address[] memory addresses;
        addresses[0] = msg.sender;
        addresses[1] = msg.sender;

        uint256[] memory ids;
        ids[0] = 0;
        ids[1] = 1;

        uint256[] memory balanceFurnitures = isotileFurnitureInstance.balanceOfBatch(addresses, ids);

        uint256 totalBalances = 0;
        for (uint i = 0; i < balanceFurnitures.length; i++) {
            totalBalances += balanceFurnitures[i];
        }

        require(totalBalances > 0, "Not allowed to redeem community part");

        uint256 totalAmountFurnitures = 1000;

        uint256 userCommunityPart = cappedSupply * supplyCommunityPercentage * (totalBalances/totalAmountFurnitures);
        communityPartRedeemed[msg.sender] = true;

        _mint(msg.sender, userCommunityPart);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }
}