// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract GDFRANK is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    string private notRevealedUri;
    uint256 public cost = 1 ether;
    uint256 public whiteListCost = 0.5 ether;
    uint256 public maxSupply = 10000;
    bool public paused = true;
    bool public pausedMintPublic = true;
    bool public revealed = false;
    mapping(address => uint256) public addressMintedBalance;

    bytes32 public whitelistMerkleRoot;

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721("GDFRank","GDFRANK") {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public mint then whitelist mint
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        require(!pausedMintPublic, "the contract is paused");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 newId = supply + i;
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, newId);
        }
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    // mint in whitelist
    function mintWhitelist(bytes32[] calldata merkleProof, uint256 _mintAmount)
        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(whiteListCost, _mintAmount)
    {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 newId = supply + i;
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, newId);
        }
    }

    // set merkleroot
    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    // get list token id in address
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // return uri json
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    // change state uri json
    function reveal() public onlyOwner {
        revealed = true;
    }

    // set price mint in public
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    // set price mint in whitelist
    function setWhitelistCost(uint256 _newCost) public onlyOwner {
        whiteListCost = _newCost;
    }

    // set base uri
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // set base extension
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    // set uri init
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    // change state pause
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    // change state pause mint public
    function pauseMintPublic(bool _state) public onlyOwner {
        pausedMintPublic = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}