// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IIsotileFurniture is IERC1155 {
    function getCountOfFurnituresBought(address account) external view returns (uint256);
}