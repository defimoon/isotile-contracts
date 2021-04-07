// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract IsotileFurnitureV0 is ERC1155, Ownable {

  using Counters for Counters.Counter;  
  Counters.Counter private _furnitureIds;

  struct Furniture {
    string uri;
    uint256 maxSupply;
    uint256 weisPrice;
    uint256 totalSupply;
  }

  // Mapping from furniture ID to furnitures
  mapping (uint256 => Furniture) private _furnitures;
  
  constructor() ERC1155("isotile.com") {}

  // Get total furnitures added to isotile contract
  function getTotalFurnitures() public view returns (uint256){
    return _furnitureIds.current();
  }

  // Create a furniture
  function addFurniture(string memory _globalUri, uint256 _maxSupply, uint256 _weisPrice) public onlyOwner {
    uint256 newFurnitureId = _furnitureIds.current();

    _furnitures[newFurnitureId].uri = _globalUri;
    _furnitures[newFurnitureId].maxSupply = _maxSupply;
    _furnitures[newFurnitureId].weisPrice = _weisPrice;

    _furnitureIds.increment();
  }

  // Override get uri for a furniture ID
  function uri(uint256 id) public view override returns (string memory) {
    return _furnitures[id].uri;
  }

  // Get max supply for a furniture ID
  function getMaxSupply(uint256 id) public view returns (uint256){
    return _furnitures[id].maxSupply;
  }

  // Get count of furnitures minted for a furniture ID
  function getTotalSupply(uint256 id) public view returns (uint256){
    return _furnitures[id].totalSupply;
  }

  // Get price in weis of furniture ID
  function getWeisPrice(uint256 id) public view returns (uint256){
    return _furnitures[id].weisPrice;
  }

  // Mint one furniture
  function mintFurniture(uint256 id, uint256 amount) public payable {
    _furnitures[id].totalSupply += amount;

    require(amount > 0, "amount cannot be 0");
    require(_furnitures[id].totalSupply < _furnitures[id].maxSupply, "Exceeds MAX_SUPPLY");
    require(_furnitures[id].weisPrice * amount == msg.value, "Ether value sent is not correct");

    _mint(msg.sender, id, amount, "");
  }

  // Mint batch furnitures
  function mintBatchFurnitures(uint256[] memory ids, uint256[] memory amounts) public payable {
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    uint256 totalSum = 0;
    for (uint i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      require(amount > 0, "amount cannot be 0");
      require(_furnitures[id].totalSupply + amount < _furnitures[id].maxSupply, "Exceeds MAX_SUPPLY");

      totalSum += _furnitures[id].weisPrice * amount;
    }

    require(totalSum == msg.value, "Ether value sent is not correct");

    _mintBatch(msg.sender, ids, amounts, "");
  }

  function withdraw() onlyOwner public {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

}