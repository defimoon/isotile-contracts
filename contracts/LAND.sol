// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721APausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStaking.sol";

contract LAND is ERC721APausable, Ownable {
    // Metadata
    string public constant PROVENANCE_SHA1 = "3b2aaeee939ebd5b41866075662819dce7bdcd3f"; // TODO: Modify

    string private _baseTokenURI = "https://cloud.isotile.com/"; // TODO: Modify
    string private _name = "isotile Genesis LAND";
    string private _symbol = "LAND";
    uint256 private _price = 0.001 ether; // TODO: Modify
    uint256 private _maxSupply = 100; // TODO: Modify
    uint256 private _maxSupplyForMint = 75;

    // PHASE 1: Whitelist
    bytes32 private _merkleRoot = 0x79ddf08365fc8d14ac7aed077f551f29de34d1a2cb8667ce686d3ded491b345e; // TODO: Modify
    mapping(uint256 => uint256) private _whitelists;

    // PHASE 2: Minting
    bool private _allowPublicMint = false;
    uint256 private _maxMintPerTx = 50;

    // PHASE 3: Stake
    bool private _allowStakingMint = false;
    IStaking private _stakingInstance = IStaking(0xCFB275c51ffdd6801a17086a67f8b96E577b8Ba2); // TODO: Modify
    mapping (address => bool) private _stakers;

    constructor() ERC721A(_name, _symbol) {}
    
    function mintChecks(uint256 num) private {
        require(num > 0, "You cant mint negative LAND");
        require(num <= _maxMintPerTx, "You can mint max 5 LAND per tx");
        require(totalSupply() + num <= _maxSupplyForMint, "Exceeds maximum LAND supply");
        require(msg.value == _price * num, "Ether sent is not correct");
        
        _mint(_msgSender(), num, "", false);
    }

    function isClaimedWhitelist(uint256 index) private view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = _whitelists[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);

        return claimedWord & mask == mask;
    }

    function _setClaimedWhitelist(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        _whitelists[claimedWordIndex] = _whitelists[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function getPrice() external view returns (uint256){
        return _price;
    }

    function whitelistMint(uint256 index, uint256 num, bytes32[] calldata merkleProof) external payable {
        require(!isClaimedWhitelist(index), "Whitelist already claimed");

        bytes32 node = keccak256(abi.encodePacked(index, _msgSender(), num));
        require(MerkleProof.verify(merkleProof, _merkleRoot, node), "Invalid proof");

        _setClaimedWhitelist(index);

        mintChecks(num);
    }

    function publicMint(uint256 num) external payable {
        require(_allowPublicMint, "Public minting didnt start");

        mintChecks(num);
    }

    function stakingMint() external {
        require(_allowStakingMint, "Staking minting didnt start");
        require(!_stakers[_msgSender()], "You already minted by staking");
        
        uint256 tickets = _stakingInstance.tickets(_msgSender());
        require(tickets > 0, "You have no staking tickets");
        require(totalSupply() + tickets <= _maxSupply, "Exceeds maximum LAND supply");

        _stakers[_msgSender()] = true;

        _mint(_msgSender(), tickets, "", false);
    }

    function adminMint(address receiver, uint256 tickets) onlyOwner external {
        require(tickets > 0, "Tickets should be positive");
        require(totalSupply() + tickets <= _maxSupply, "Exceeds maximum LAND supply");

        _mint(receiver, tickets, "", false);
    }

    function setMerkleRoot(bytes32 merkleRoot) onlyOwner external {
        _merkleRoot = merkleRoot;
    }
  
    function setBaseURI(string memory baseURI) onlyOwner public {
        _baseTokenURI = baseURI;
    }
    
    function setPrice(uint256 price) onlyOwner external {
        _price = price;
    }
    
    function setName(string memory name_) onlyOwner external {
        _name = name_;
    }
    
    function setSymbol(string memory symbol_) onlyOwner external {
        _symbol = symbol_;
    }

    function startPublicMint() onlyOwner external {
        _allowPublicMint = true;
    }

    function startStakingMint() onlyOwner external {
        _allowStakingMint = true;
    }

    function pause() onlyOwner external {
        _pause();
    }
  
    function unpause() onlyOwner external {
        _unpause();
    }

    function withdraw() onlyOwner external {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}