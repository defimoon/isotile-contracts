// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Tiles is ERC20 {
    constructor(uint256 initialSupply) ERC20("Tiles", "TIL") {

    }

    function burnFrom(address account, uint256 amount) public virtual {
    }
}