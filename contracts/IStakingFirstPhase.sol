// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

interface IStakingFirstPhase {
    function getTickets(address userAddress) external view returns(uint256);

    function getTotalTickets() external view returns(uint256);

    function isStakingEnabled() external view returns (bool);
}