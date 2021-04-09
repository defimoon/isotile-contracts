// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITilesV0 is IERC20 {
    function burnFromFurnitureSpending(address account, uint256 amount) external;
}