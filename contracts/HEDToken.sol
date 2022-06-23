// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract HappyEnding is ERC20, AccessControl, EIP712 {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => bool) public signers;
    mapping (address => uint) public nonces;
    mapping(string => bool) claimSignatureMarker;

    event SignerAdded (address signer);
    event SignerRemoved (address signer);
    event Claimed(address player, uint256 amount, string nonce, uint256 timestamp);

    constructor() ERC20("Go Dating Earn", "GDE") EIP712("GDE", "1") {
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
        _setupRole(OWNER_ROLE, msg.sender);
    }

    function addSigner(address signer) public onlyRole(OWNER_ROLE) {
        require(signer != address(0), "signer is invalid");
        require(signers[signer] == false, "signer is exists");
        signers[signer] = true;
        emit SignerAdded(signer);
    }

    function removeSigner(address signer) public onlyRole(OWNER_ROLE) {
        require(signer != address(0), "signer is invalid");
        require(signers[signer] == true, "signer is not exists");
        signers[signer] = false;
        emit SignerRemoved(signer);
    }

    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    function burn(uint256 amount) public onlyRole(OWNER_ROLE) {
        _burn(msg.sender, amount);
    }

    function getClaimed(string calldata _nonce) public view returns (bool) {
        return claimSignatureMarker[_nonce];
    }

    function claim(bytes memory _signature, string calldata nonce, uint256 amount) public {
        require(!claimSignatureMarker[nonce], "AirdropDistributor: Drop already claimed.");
        require(amount > 0, "Invalid amount");
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Claim(address walletAddress,string nonce,uint256 amount)"),
            msg.sender,
            keccak256(bytes(nonce)),
            amount
        )));
        address signer = ECDSA.recover(digest, _signature);
        require(signers[signer], "Signer is not valid");
        claimSignatureMarker[nonce] = true;
        _mint(msg.sender, amount*(10**18));
        emit Claimed(msg.sender, amount, nonce, block.timestamp);
    }
}