// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

import "./IStakingFirstPhase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LAND is ERC721Pausable, Ownable {
    // Metadata
    string private _landHashSha1 = "3b2aaeee939ebd5b41866075662819dce7bdcd3f"; // TODO: Modify
    string private _baseTokenURI = "https://cloud.isotile.com/"; // TODO: Modify
    string private _name = "isotile Genesis LAND";
    string private _symbol = "LAND";
    uint256 private _price = 0.049 ether; // TODO: Modify
    uint256 private _maxSupply = 10000; // TODO: Modify

    // PHASE 1: Whitelist
    bytes32 private merkleRoot; // TODO: Modify
    mapping(uint256 => uint256) private _whitelists;
    uint256 private _mintingId = _maxCountStaking;

    // PHASE 2: Minting
    bool private _allowPublicMint = false;

    // PHASE 3: Stake
    bool private _allowStakingMint = false;
    IStakingFirstPhase private _stakingInstance = IStakingFirstPhase(0x3b2AAEeE939ebD5b41866075662819dce7Bdcd3F); // TODO: Modify
    mapping (address => bool) private _stakers;
    uint256 private _maxCountStaking = 500; // TODO: Modify
    uint256 private _claimingId = 0;

    constructor() ERC721(_name, _symbol) {}

    function mint(uint256 startId, uint256 countMints) private {
        for(;startId < countMints;){
            _mint(_msgSender(), startId);

            unchecked {
                ++startId;
            }
        }
    }
    
    function mintChecks(uint256 num) private {
        uint256 startId = _mintingId;
        uint256 countMints;
        unchecked {
            countMints = startId + num;
        }

        require(num > 0, "You cant mint negative LAND");
        require(num < 6, "You can mint max 5 LAND per tx");
        require(countMints <= _maxSupply, "Exceeds maximum LAND supply");
        require(msg.value == _price * num, "Ether sent is not correct");
        
        unchecked {
            _mintingId += num;
        }
        mint(startId, countMints);
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

    function publicMint(uint256 num) external payable {
        require(_allowPublicMint, "Public minting didnt start");

        mintChecks(num);
    }

    function whitelistMint(uint256 index, uint256 num, bytes32[] calldata merkleProof) external payable {
        require(!isClaimedWhitelist(index), "Whitelist already claimed");

        bytes32 node = keccak256(abi.encodePacked(index, _msgSender(), num));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");

        _setClaimedWhitelist(index);

        mintChecks(num);
    }

    function stakingMint() external {
        require(_allowStakingMint, "Staking minting didnt start");
        require(!_stakers[_msgSender()], "You already minted by staking");
        
        uint256 tickets = _stakingInstance.getTickets(_msgSender());
        require(tickets > 0, "You have no staking tickets");

        uint256 startId = _claimingId;
        uint256 countMints;
        unchecked {
            countMints = startId + tickets;
            _claimingId += tickets;
        }

        _stakers[_msgSender()] = true;

        mint(startId, countMints);
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