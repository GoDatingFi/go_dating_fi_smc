// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract HappyEnding is ERC20, AccessControl {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => bool) public signers;
    mapping(string => uint) public claimTransactions;

    event BurnForReason (uint amount, string reason);
    event SignerAdded (address signer);
    event SignerRemoved (address signer);
    event Claimed(address player, string txId,uint256 amount);

    constructor() ERC20("Happy Ending", "HED") {
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
        _setupRole(OWNER_ROLE, msg.sender);
    }

    // Add address permission miner
    function addSigner (address signer) public onlyRole(OWNER_ROLE) {
        require(signer != address(0), "signer is invalid");
        require(signers[signer] == false, "signer is exists");
        signers[signer] = true;
        emit SignerAdded(signer);
    }

    // remove address permission miner
    function removeSigner (address signer) public onlyRole(OWNER_ROLE) {
        require(signer != address(0), "signer is invalid");
        require(signers[signer] == true, "signer is not exists");
        signers[signer] = false;
        emit SignerRemoved(signer);
    }

    // mint with rule minter_role
    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    // burn
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // burn for reason
    function burnFor(uint256 amount, string memory reason) public {
        _burn(msg.sender, amount);
        emit BurnForReason(amount, reason);
    }

    // get transaction claimed
    function getClaimed(string memory message) public view returns (uint256) {
        return claimTransactions[message];
    }

    /**
        - check address minter != address 0
        - check amount > 0
        - verify signature == address minter
        - check transaction claim?
        - mint
     */
    function claim(address to, string memory message, uint256 amount,bytes32 _hashedMessage,  bytes memory _signature) public {
        require(to != address(0), "Invalid claimer");
        require(amount > 0, "Invalid amount");

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = recoverSigner(prefixedHashMessage, _signature);
        require(signers[signer], "Signer is not valid");
        require(claimTransactions[message] == 0, "Transaction is claimed");

        claimTransactions[message] = amount;
        _mint(to, amount);
        emit Claimed(to, message, amount);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}