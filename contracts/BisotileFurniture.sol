// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ITiles.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BisotileFurniture is ERC1155, ERC1155Pausable, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _furnitureIds;
  ITiles private tilesInstance;
  
  // Event on create furnitures
  event FurnitureAdded(uint256 indexed id);
  
  // Mapping from address to amount of TILES to receive as early backer
  mapping (address => uint256) private _earlyBackers;
  
  //Parameters for the TILES distribution for Genesis purchasers so that there is a x10 multiplier between Y_0 and Y_1499
  uint256 Y_0 = 1000000; //Amount recorded for the purchaser of id's 0 of Genesis items
  uint256 slope = 600; //Slope of the Genesis distribution line

  struct Furniture {
    string uri;
    uint256 maxSupply;
    bool isPaidWithBNB;
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
  function isPaidWithBNB(uint256 id) public view returns (bool){
    return _furnitures[id].isPaidWithBNB;
  }

  // Get price in weis of furniture ID
  function getPrice(uint256 id) public view returns (uint256){
    return _furnitures[id].price;
  }

  // Get count of furnitures minted for a furniture ID
  function getTotalSupply(uint256 id) public view returns (uint256){
    return _furnitures[id].totalSupply;
  }
  
  // Get distribution record for an address
  function getDistributionRecordToMintForEarlyBacker(address account) public view returns (uint256){
    return _earlyBackers[account];
  }

  // Mint one furniture
  function mintFurniture(uint256 id, uint256 amount) public payable {
    require(amount > 0, "amount cannot be 0");

    require(_furnitures[id].totalSupply + amount <= _furnitures[id].maxSupply, "Exceeds MAX_SUPPLY");
    _furnitures[id].totalSupply += amount;

    uint256 paymentRequired = _furnitures[id].price * amount;
    if(_furnitures[id].isPaidWithBNB){
      require(msg.value == paymentRequired, "BNB value sent is not correct");
    }else{
      require(msg.value == 0, "BNB not accepted for this furniture");
      require(tilesInstance.balanceOf(msg.sender) >= paymentRequired, "Not enough tiles");

      tilesInstance.spend(msg.sender, paymentRequired);
    }

    //logic for assigning distributionRecord to early backers
    if(id < 4){
      uint256 distributionRecordTilesToMint = getDistributionRecordToMintForEarlyBacker(id, amount);
      _earlyBackers[msg.sender] += distributionRecordTilesToMint;
    }

    _mint(msg.sender, id, amount, "");
  }
  
  //This function generates a intermediate distribution record which will be used by TILES ERC-20 contract to mint the correct amount
  function getDistributionRecordToMintForEarlyBacker(uint256 id, uint256 amount) internal view returns (uint256){
      uint256 distributionRecordTilesToMint = 0;
      uint256 supplyBeforeMint = _furnitures[id].totalSupply - amount; //Mint function already updated the amount so we substract
      for (uint n = supplyBeforeMint; n < _furnitures[id].totalSupply; n++) {
          distributionRecordTilesToMint += Y_0 - slope * n;
      }
      
      return distributionRecordTilesToMint;
  }

  // Mint batch furnitures
  function mintBatchFurnitures(uint256[] memory ids, uint256[] memory amounts) public payable {
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    uint256 paymentRequiredOnBNB = 0;
    uint256 paymentRequiredOnTiles = 0;

    for (uint i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      require(amount > 0, "amount cannot be 0");

      require(_furnitures[id].totalSupply + amount <= _furnitures[id].maxSupply, "Exceeds MAX_SUPPLY");
      _furnitures[id].totalSupply += amount;

      if(_furnitures[id].isPaidWithBNB){
        paymentRequiredOnBNB += _furnitures[id].price * amount;
      }else{
        paymentRequiredOnTiles += _furnitures[id].price * amount;
      }
      
      //logic for assigning distributionRecord to early backers
      if(id < 4){
        uint256 distributionRecordTilesToMint = getDistributionRecordToMintForEarlyBacker(id, amount);
        _earlyBackers[msg.sender] += distributionRecordTilesToMint;
      }
    }

    require(msg.value == paymentRequiredOnBNB, "BNB value sent is not correct");

    if(paymentRequiredOnTiles > 0){
      require(tilesInstance.balanceOf(msg.sender) >= paymentRequiredOnTiles, "Not enough tiles");

      tilesInstance.spend(msg.sender, paymentRequiredOnTiles);
    }

    _mintBatch(msg.sender, ids, amounts, "");
  }
  
  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override(ERC1155, ERC1155Pausable) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  // Create a furniture
  function addFurniture(string memory _furnitureUri, uint256 _maxSupply, bool _isPaidWithBNB, uint256 _price) onlyOwner public {
    uint256 newFurnitureId = _furnitureIds.current();

    _furnitures[newFurnitureId] = Furniture({
      uri: _furnitureUri,
      maxSupply: _maxSupply,
      isPaidWithBNB: _isPaidWithBNB,
      price: _price,
      totalSupply: 0
    });
    
    emit FurnitureAdded(newFurnitureId);

    _furnitureIds.increment();
  }

  function setTilesInstance(address tilesAddress) onlyOwner public {
    tilesInstance = ITiles(tilesAddress);
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