// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./ITilesV0.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract IsotileFurnitureV0 is ERC1155, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _furnitureIds;
  ITilesV0 public tilesInstance;

  struct Furniture {
    string uri;
    uint256 maxSupply;
    bool isPaidWithEther;
    uint256 price;
    uint256 totalSupply;
  }

  // Mapping from furniture ID to furnitures
  mapping (uint256 => Furniture) private _furnitures;
  

  constructor() ERC1155("") {}

  // Get total furnitures added to isotile contract
  function getTotalFurnitures() public view returns (uint256){
    return _furnitureIds.current();
  }

  // Override get uri for a furniture ID
  function uri(uint256 id) public view override returns (string memory) {
    return _furnitures[id].uri;
  }

  // Get max supply for a furniture ID
  function getMaxSupply(uint256 id) public view returns (uint256){
    return _furnitures[id].maxSupply;
  }

  // Get if a furniture is paid on tiles
  function isPaidWithEther(uint256 id) public view returns (bool){
    return _furnitures[id].isPaidWithEther;
  }

  // Get price in weis of furniture ID
  function getPrice(uint256 id) public view returns (uint256){
    return _furnitures[id].price;
  }

  // Get count of furnitures minted for a furniture ID
  function getTotalSupply(uint256 id) public view returns (uint256){
    return _furnitures[id].totalSupply;
  }

  // Mint one furniture
  function mintFurniture(uint256 id, uint256 amount) public payable {
    require(amount > 0, "amount cannot be 0");

    _furnitures[id].totalSupply += amount;
    require(_furnitures[id].totalSupply <= _furnitures[id].maxSupply, "Exceeds MAX_SUPPLY");

    uint256 paymentRequired = _furnitures[id].price * amount;
    if(_furnitures[id].isPaidWithEther){
      require(msg.value == paymentRequired, "Ether value sent is not correct");
    }else{
      require(msg.value == 0, "Ether not accepted for this furniture");
      require(tilesInstance.balanceOf(msg.sender) >= paymentRequired, "Not enough tiles");

      tilesInstance.burnFrom(msg.sender, paymentRequired);
    }

    _mint(msg.sender, id, amount, "");
  }

  // Mint batch furnitures
  function mintBatchFurnitures(uint256[] memory ids, uint256[] memory amounts) public payable {
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    uint256 paymentRequiredOnEther = 0;
    uint256 paymentRequiredOnTiles = 0;

    for (uint i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      require(amount > 0, "amount cannot be 0");

      _furnitures[id].totalSupply += amount;
      require(_furnitures[id].totalSupply <= _furnitures[id].maxSupply, "Exceeds MAX_SUPPLY");

      if(_furnitures[id].isPaidWithEther){
        paymentRequiredOnEther += _furnitures[id].price * amount;
      }else{
        paymentRequiredOnTiles += _furnitures[id].price * amount;
      }
    }

    require(msg.value == paymentRequiredOnEther, "Ether value sent is not correct");

    if(paymentRequiredOnTiles > 0){
      require(tilesInstance.balanceOf(msg.sender) >= paymentRequiredOnTiles, "Not enough tiles");

      tilesInstance.burnFrom(msg.sender, paymentRequiredOnTiles);
    }

    _mintBatch(msg.sender, ids, amounts, "");
  }

  // Create a furniture
  function addFurniture(string memory _furnitureUri, uint256 _maxSupply, bool _isPaidWithEther, uint256 _price) onlyOwner public {
    uint256 newFurnitureId = _furnitureIds.current();

    _furnitures[newFurnitureId] = Furniture({
      uri: _furnitureUri,
      maxSupply: _maxSupply,
      isPaidWithEther: _isPaidWithEther,
      price: _price,
      totalSupply: 0
    });

    _furnitureIds.increment();
  }

  function setTilesInstance(address tilesAddress) onlyOwner public {
    tilesInstance = ITilesV0(tilesAddress);
  }

  function withdraw() onlyOwner public {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

}