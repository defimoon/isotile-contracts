// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tiles is ERC20Snapshot, Ownable {
    constructor(uint256 initialSupply) ERC20("Tiles", "TIL") {

    }

    function burnFrom(address account, uint256 amount) public virtual {
    }
}