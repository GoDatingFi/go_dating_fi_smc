// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTVIP is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public baseURI;
    uint256 public cost = 1000000000000000000;
    bool public paused = false;
    mapping (uint256 => string) private _tokenURIs;
    IERC20 token;

    event Minted(uint256 indexed newId, string _tokenURI, uint256 _tokenamount);
    constructor(
        string memory _initBaseURI,
        address _tokenAddress
    ) ERC721("VIPCARD","VIP") {
        token = IERC20(_tokenAddress);
        setBaseURI(_initBaseURI);
    }

    // set address token payment
    function setToken(address _tokenAddress) public onlyOwner {
        token = IERC20(_tokenAddress);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getTokenBalanceContract() public onlyOwner view returns(uint256){
       return token.balanceOf(address(this));
    }

    // public mint
    function mint(string memory _tokenURI, uint256 _tokenamount) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        if (msg.sender != owner()) {
            require(_tokenamount >= cost, "insufficient funds");
        }
        
        uint256 newId = supply + 1;
        _safeMint(msg.sender, newId);
        _setTokenURI(newId, _tokenURI);
        token.transferFrom(msg.sender, address(this), _tokenamount);
        emit Minted(newId, _tokenURI, _tokenamount);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    // set price mint in public
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    // set base uri
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    // change state pause
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    // withdraw coin
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // withdraw token payment
    function withdrawToken() public onlyOwner {
        uint256 amount = getTokenBalanceContract();
        require(amount > 0, "insufficient funds");
        token.transfer(msg.sender, amount);
    }
}